// HACK: 2024-11-13: Workaround for enabling encryption using CMK with system-assigned managed identity
param vaultName string
param location string
param tags object

param useCMK bool
param encryptionKeyUri string = ''

param storageType string
param immutabilityState string

param keyVaultResourceGroupName string
param keyVaultName string
param roles object

param deploymentNameStructure string

resource keyVaultResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: keyVaultResourceGroupName
  scope: subscription()
}

module recoveryServicesVaultNoEncryptionModule 'recoveryServicesVault.bicep' = {
  name: take(replace(deploymentNameStructure, '{rtype}', 'rsv-encoff'), 64)
  params: {
    vaultName: vaultName
    location: location
    tags: tags

    immutabilityState: 'Disabled'
    storageType: storageType
    useCMK: false
  }
}

// Create a role assignment on the Key Vault for the system-assigned managed identity of the vault
module keyVaultRoleAssignmentModule '../../module-library/roleAssignments/roleAssignment-kv.bicep' = if (useCMK) {
  name: take(replace(deploymentNameStructure, '{rtype}', 'rsv-kv-rbac'), 64)
  scope: keyVaultResourceGroup
  params: {
    kvName: keyVaultName
    principalId: recoveryServicesVaultNoEncryptionModule.outputs.principalId
    roleDefinitionId: roles.KeyVaultCryptoUser
    principalType: 'ServicePrincipal'
  }
}

// Now that the RSV identity has been assigned a permission to the Key Vault, 
// we can redeploy it with encryption enabled
module recoveryServicesVaultEncryptionModule 'recoveryServicesVault.bicep' = if (useCMK) {
  name: take(replace(deploymentNameStructure, '{rtype}', 'rsv-encon'), 64)
  params: {
    vaultName: vaultName
    location: location
    tags: tags

    immutabilityState: immutabilityState
    storageType: storageType
    useCMK: useCMK
    encryptionKeyUri: encryptionKeyUri
  }
  dependsOn: [keyVaultRoleAssignmentModule]
}

output id string = recoveryServicesVaultNoEncryptionModule.outputs.id
output name string = recoveryServicesVaultNoEncryptionModule.outputs.name
output principalId string = recoveryServicesVaultNoEncryptionModule.outputs.principalId
