param namingConvention string
param environment string
param sequenceFormatted string
param namingStructure string
param deploymentNameStructure string
param workloadName string
param encryptionKeyUri string
param useCMK bool
param roles object
param keyVaultResourceGroupName string
param keyVaultName string

param debugMode bool = false

param location string = resourceGroup().location
param tags object
param storageType string = 'GeoRedundant'

param backupTime string = '2023-12-31T08:00:00.000Z'
param dailyRetentionDurationCount int = 8
param weeklyRetentionDurationCount int = 6
param monthlyRetentionDurationCount int = 13
param weeklyRetentionDays ('Sunday' | 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday')[] = [
  'Sunday'
]
param timeZone string

param protectedStorageAccountId string
param protectedAzureFileShares string[]

@description('The schedule policy used for the custom Virtual Machine backup policy.')
param schedulePolicy object = {
  schedulePolicyType: 'SimpleSchedulePolicyV2'
  scheduleRunFrequency: 'Hourly'
  hourlySchedule: {
    interval: 4
    scheduleWindowStartTime: backupTime
    scheduleWindowDuration: 4
  }
  dailySchedule: null
  weeklySchedule: null
}

@description('The schedule policy used for the custom Azure File Shares backup policy.')
param fileShareSchedulePolicy object = {
  schedulePolicyType: 'SimpleSchedulePolicy'
  scheduleRunFrequency: 'Daily'
  scheduleRunDays: null
  scheduleRunTimes: [
    backupTime
  ]
}

@description('The retention policy used for all custom backup policies.')
param retentionPolicy object = {
  retentionPolicyType: 'LongTermRetentionPolicy'

  dailySchedule: {
    retentionTimes: [backupTime]
    retentionDuration: {
      count: dailyRetentionDurationCount
      durationType: 'Days'
    }
  }

  weeklySchedule: {
    daysOfTheWeek: weeklyRetentionDays
    retentionTimes: [backupTime]
    retentionDuration: {
      count: weeklyRetentionDurationCount
      durationType: 'Weeks'
    }
  }

  monthlySchedule: {
    retentionScheduleFormatType: 'Daily'
    retentionScheduleDaily: {
      daysOfTheMonth: [
        {
          date: 1
          isLast: false
        }
      ]
    }
    retentionTimes: [backupTime]
    retentionDuration: {
      count: monthlyRetentionDurationCount
      durationType: 'Months'
    }
    retentionScheduleWeekly: null
  }

  yearlySchedule: null
}

var vaultName = replace(namingStructure, '{rtype}', 'rsv')

resource keyVaultResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: keyVaultResourceGroupName
  scope: subscription()
}

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2024-04-01' = {
  name: vaultName
  location: location
  tags: tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    // Use only Azure Monitor for alerts
    monitoringSettings: {
      azureMonitorAlertSettings: {
        alertsForAllJobFailures: 'Enabled'
        // Only supported (and required) in later API versions
        alertsForAllFailoverIssues: 'Enabled'
        alertsForAllReplicationIssues: 'Enabled'
      }
      classicAlertSettings: {
        alertsForCriticalOperations: 'Disabled'
        // Only supported in later API versions
        emailNotificationsForSiteRecovery: 'Disabled'
      }
    }

    securitySettings: {
      // Default to immutable but don't lock the policy
      immutabilitySettings: {
        state: debugMode ? 'Disabled' : 'Unlocked'
      }
    }

    // Do not allow cross-subscription restores (to avoid leaking data between projects)
    restoreSettings: {
      crossSubscriptionRestoreSettings: {
        crossSubscriptionRestoreState: 'PermanentlyDisabled'
      }
    }

    publicNetworkAccess: 'Enabled'

    // Use a customer-managed key when not debugging and when required
    encryption: !debugMode && useCMK
      ? {
          keyVaultProperties: {
            keyUri: encryptionKeyUri
          }
          kekIdentity: {
            useSystemAssignedIdentity: true
          }
          infrastructureEncryption: 'Enabled'
        }
      : null

    redundancySettings: {
      standardTierStorageRedundancy: storageType
      crossRegionRestore: 'Enabled'
    }
  }
}

// Create a role assignment on the Key Vault for the system-assigned managed identity of the vault
module keyVaultRoleAssignment '../../module-library/roleAssignments/roleAssignment-kv.bicep' = if (useCMK) {
  name: take(replace(deploymentNameStructure, '{rtype}', 'rsv-kv-rbac'), 80)
  scope: keyVaultResourceGroup
  params: {
    kvName: keyVaultName
    principalId: recoveryServicesVault.identity.principalId
    roleDefinitionId: roles.KeyVaultCryptoUser
    principalType: 'ServicePrincipal'
  }
}

// Enable soft delete settings
resource backupConfig 'Microsoft.RecoveryServices/vaults/backupconfig@2024-04-01' = {
  name: 'vaultconfig'
  location: location
  parent: recoveryServicesVault
  properties: {
    enhancedSecurityState: debugMode ? 'Disabled' : 'Enabled'
    isSoftDeleteFeatureStateEditable: true
    softDeleteFeatureState: debugMode ? 'Disabled' : 'Enabled'
  }
}

// Break up the naming convention on the sequence placeholder to use for the backup RG name
var processNamingConventionPlaceholders = replace(
  replace(
    replace(
      replace(replace(namingConvention, '{workloadName}', workloadName), '{rtype}', 'rg-backup'),
      '{loc}',
      location
    ),
    '{env}',
    environment
  ),
  '-{subWorkloadName}',
  ''
)
var splitNamingConvention = split(processNamingConventionPlaceholders, '{seq}')
var azureBackupRGNamePrefix = '${splitNamingConvention[0]}${sequenceFormatted}-'
var azureBackupRGNameSuffix = length(splitNamingConvention) > 1 ? splitNamingConvention[1] : ''

var backupPolicyCommonProperties = {
  retentionPolicy: retentionPolicy
  timeZone: timeZone
}

var backupPolicyIaasVmProperties = {
  schedulePolicy: schedulePolicy
  backupManagementType: 'AzureIaasVM'
  instantRpRetentionRangeInDays: 2
  policyType: 'V2'
  instantRPDetails: {
    azureBackupRGNamePrefix: azureBackupRGNamePrefix
    azureBackupRGNameSuffix: azureBackupRGNameSuffix
  }
}

var backupPolicyAzureStorageProperties = {
  backupManagementType: 'AzureStorage'
  workloadType: 'AzureFileShare'
  schedulePolicy: fileShareSchedulePolicy
}

// Create an enhanced VM backup policy to backup multiple times per day
resource iaasVmBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  name: 'EnhancedPolicy-${workloadName}-${sequenceFormatted}'
  parent: recoveryServicesVault
  properties: union(backupPolicyCommonProperties, backupPolicyIaasVmProperties)
}

// Create a single Azure File backup policy, even if there are multiple file shares or storage accounts
resource filesBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = if (length(protectedAzureFileShares) > 0) {
  name: 'AzureFileSharesPolicy-${workloadName}-${sequenceFormatted}'
  parent: recoveryServicesVault
  properties: union(backupPolicyCommonProperties, backupPolicyAzureStorageProperties)
}

// Create a protected item per Azure File Share to be protected
module fileShareProtectedItems 'rsvProtectedItem-fs.bicep' = [
  for fileShare in protectedAzureFileShares: {
    name: take(replace(deploymentNameStructure, '{rtype}', 'rsv-fs-${fileShare}'), 64)
    params: {
      backupPolicyName: filesBackupPolicy.name
      fileShareName: fileShare
      recoveryServicesVaultId: recoveryServicesVault.id
      storageAccountId: protectedStorageAccountId
    }
  }
]

// Lock the Recovery Services Vault to prevent accidental deletion
resource lock 'Microsoft.Authorization/locks@2020-05-01' = if (!debugMode) {
  name: replace(namingStructure, '{rtype}', 'rsv-lock')
  scope: recoveryServicesVault
  properties: {
    level: 'CanNotDelete'
  }
}

output id string = recoveryServicesVault.id
output name string = recoveryServicesVault.name
output vmBackupPolicyName string = iaasVmBackupPolicy.name

// For debug purposes only
output backupResourceGroupNameStructure string = '${azureBackupRGNamePrefix}{N}${azureBackupRGNameSuffix}'
