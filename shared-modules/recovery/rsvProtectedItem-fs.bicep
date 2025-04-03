param backupPolicyName string
param recoveryServicesVaultId string
param storageAccountId string
param fileShareName string

var rsvName = split(recoveryServicesVaultId, '/')[8]

var storageAccountRgName = split(storageAccountId, '/')[4]
var storageAccountName = split(storageAccountId, '/')[8]

resource protectionContainer 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2024-04-01' = {
  name: '${rsvName}/Azure/storagecontainer;Storage;${storageAccountRgName};${storageAccountName}'
  properties: {
    backupManagementType: 'AzureStorage'
    containerType: 'StorageContainer'
    sourceResourceId: storageAccountId
  }
}

resource protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-04-01' = {
  parent: protectionContainer
  name: 'AzureFileShare;${fileShareName}'
  properties: {
    protectedItemType: 'AzureFileShareProtectedItem'
    sourceResourceId: storageAccountId
    policyId: resourceId('Microsoft.RecoveryServices/vaults/backupPolicies', rsvName, backupPolicyName)
    //isInlineInquiry: true
  }
}
