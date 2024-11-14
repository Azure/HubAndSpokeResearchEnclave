param vaultName string
param location string
param tags object

param useCMK bool
param encryptionKeyUri string = ''

param storageType string

@allowed(['Disabled', 'Unlocked'])
param immutabilityState string

// LATER: Use AVM

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
        state: immutabilityState
      }
    }

    // Do not allow cross-subscription restores (to avoid leaking data between projects)
    restoreSettings: {
      crossSubscriptionRestoreSettings: {
        crossSubscriptionRestoreState: 'PermanentlyDisabled'
      }
    }

    publicNetworkAccess: 'Enabled'

    // Use a customer-managed key when not debugging and when specified
    encryption: useCMK && !empty(encryptionKeyUri)
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

output id string = recoveryServicesVault.id
output name string = recoveryServicesVault.name
output principalId string = recoveryServicesVault.identity.principalId
