param deploymentNameStructure string
param roles object
param hostPoolPrincipalId resourceInput<'Microsoft.DesktopVirtualization/hostPools@2026-04-01-preview'>.identity.principalId
param hostPoolResourceId resourceInput<'Microsoft.DesktopVirtualization/hostPools@2026-04-01-preview'>.id
param virtualNetworkResourceId string?

param domainJoinCredentialKeyVaultSecretUris credentialKeyVaultSecretUrisType?
param localCredentialKeyVaultSecretUris credentialKeyVaultSecretUrisType?

param sessionHostResourceGroupName string
param enableAvmTelemetry bool

import { credentialKeyVaultSecretUrisType } from '../types/credentialKeyVaultSecretUrisType.bicep'

// Create role assignments for the managed identity of the host pool (?)
// - Desktop Virtualization Virtual Machine Contributor role
//   - Resource group for the session hosts
module resourceGroupRbacModule '../../module-library/roleAssignments/roleAssignment-rg.bicep' = {
  #disable-next-line BCP334
  name: take(replace(deploymentNameStructure, '{rtype}', 'hp-rbac-rg'), 64)
  scope: resourceGroup(sessionHostResourceGroupName)
  params: {
    principalId: hostPoolPrincipalId
    roleDefinitionId: roles.DesktopVirtualizationVirtualMachineContributor
    principalType: 'ServicePrincipal'
    description: 'Role assignment for the managed identity of the host pool to manage (create, delete) session hosts.'
  }
}

//   - Host pool itself (could be different from session host RG)
module hostPoolRbacModule 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  #disable-next-line BCP334
  name: take(replace(deploymentNameStructure, '{rtype}', 'hp-rbac-hp'), 64)
  params: {
    principalId: hostPoolPrincipalId
    roleDefinitionId: roles.DesktopVirtualizationVirtualMachineContributor
    principalType: 'ServicePrincipal'
    description: 'Role assignment for the managed identity of the host pool.'
    resourceId: hostPoolResourceId
    enableTelemetry: enableAvmTelemetry
  }
}
//   - Virtual network
module vnetRbacModule 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (!empty(virtualNetworkResourceId)) {
  #disable-next-line BCP334
  name: take(replace(deploymentNameStructure, '{rtype}', 'hp-rbac-vnet'), 64)
  scope: resourceGroup(split(virtualNetworkResourceId!, '/')[4])
  params: {
    principalId: hostPoolPrincipalId
    roleDefinitionId: roles.DesktopVirtualizationVirtualMachineContributor
    principalType: 'ServicePrincipal'
    description: 'Role assignment for the managed identity of the host pool.'
    resourceId: virtualNetworkResourceId!
    enableTelemetry: enableAvmTelemetry
  }
}
// LATER: - Subnet (is that necessary? Portal does it)
// - Key Vault Secrets User
//   - Secrets for
//     - Domain join username, password
resource domainJoinCredentialKeyVault 'Microsoft.KeyVault/vaults@2026-02-01' existing = if (domainJoinCredentialKeyVaultSecretUris != null) {
  name: domainJoinCredentialKeyVaultSecretUris!.keyVaultName
  scope: resourceGroup(
    domainJoinCredentialKeyVaultSecretUris!.keyVaultSubscriptionId,
    domainJoinCredentialKeyVaultSecretUris!.keyVaultResourceGroupName
  )
}

resource domainJoinUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2026-02-01' existing = if (domainJoinCredentialKeyVaultSecretUris != null) {
  name: split(domainJoinCredentialKeyVaultSecretUris!.username, '/')[4]
  parent: domainJoinCredentialKeyVault
}

resource domainJoinPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2026-02-01' existing = if (domainJoinCredentialKeyVaultSecretUris != null) {
  name: split(domainJoinCredentialKeyVaultSecretUris!.password, '/')[4]
  parent: domainJoinCredentialKeyVault
}

module domainJoinUsernameSecretRbacModule 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (domainJoinCredentialKeyVaultSecretUris != null) {
  #disable-next-line BCP334
  name: take(replace(deploymentNameStructure, '{rtype}', 'hp-rbac-djuname'), 64)
  scope: resourceGroup(
    domainJoinCredentialKeyVaultSecretUris!.keyVaultSubscriptionId,
    domainJoinCredentialKeyVaultSecretUris!.keyVaultResourceGroupName
  )
  params: {
    principalId: hostPoolPrincipalId
    roleDefinitionId: roles.KeyVaultSecretsUser
    principalType: 'ServicePrincipal'
    description: 'Role assignment for the managed identity of the host pool to access the domain join username secret.'
    resourceId: domainJoinUsernameSecret.id
    enableTelemetry: enableAvmTelemetry
  }
}

module domainJoinPasswordSecretRbacModule 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (domainJoinCredentialKeyVaultSecretUris != null) {
  #disable-next-line BCP334
  name: take(replace(deploymentNameStructure, '{rtype}', 'hp-rbac-djpass'), 64)
  scope: resourceGroup(
    domainJoinCredentialKeyVaultSecretUris!.keyVaultSubscriptionId,
    domainJoinCredentialKeyVaultSecretUris!.keyVaultResourceGroupName
  )
  params: {
    principalId: hostPoolPrincipalId
    roleDefinitionId: roles.KeyVaultSecretsUser
    principalType: 'ServicePrincipal'
    description: 'Role assignment for the managed identity of the host pool to access the domain join password secret.'
    resourceId: domainJoinPasswordSecret.id
    enableTelemetry: enableAvmTelemetry
  }
}

//     - Session host local admin username, password
resource localCredentialKeyVault 'Microsoft.KeyVault/vaults@2026-02-01' existing = if (localCredentialKeyVaultSecretUris != null) {
  name: localCredentialKeyVaultSecretUris!.keyVaultName
  scope: resourceGroup(
    localCredentialKeyVaultSecretUris!.keyVaultSubscriptionId,
    localCredentialKeyVaultSecretUris!.keyVaultResourceGroupName
  )
}
resource localUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2026-02-01' existing = if (localCredentialKeyVaultSecretUris != null) {
  name: split(localCredentialKeyVaultSecretUris!.username, '/')[4]
  parent: localCredentialKeyVault
}

resource localPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2026-02-01' existing = if (localCredentialKeyVaultSecretUris != null) {
  name: split(localCredentialKeyVaultSecretUris!.password, '/')[4]
  parent: localCredentialKeyVault
}

module usernameSecretRbacModule 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (localCredentialKeyVaultSecretUris != null) {
  #disable-next-line BCP334
  name: take(replace(deploymentNameStructure, '{rtype}', 'hp-rbac-uname'), 64)
  scope: resourceGroup(
    localCredentialKeyVaultSecretUris!.keyVaultSubscriptionId,
    localCredentialKeyVaultSecretUris!.keyVaultResourceGroupName
  )
  params: {
    principalId: hostPoolPrincipalId
    roleDefinitionId: roles.KeyVaultSecretsUser
    principalType: 'ServicePrincipal'
    description: 'Role assignment for the managed identity of the host pool to access the session host local admin username secret.'
    resourceId: localUsernameSecret.id
    enableTelemetry: enableAvmTelemetry
  }
}

module passwordSecretRbacModule 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (localCredentialKeyVaultSecretUris != null) {
  #disable-next-line BCP334
  name: take(replace(deploymentNameStructure, '{rtype}', 'hp-rbac-pass'), 64)
  scope: resourceGroup(
    localCredentialKeyVaultSecretUris!.keyVaultSubscriptionId,
    localCredentialKeyVaultSecretUris!.keyVaultResourceGroupName
  )
  params: {
    principalId: hostPoolPrincipalId
    roleDefinitionId: roles.KeyVaultSecretsUser
    principalType: 'ServicePrincipal'
    description: 'Role assignment for the managed identity of the host pool to access the session host local admin password secret.'
    resourceId: localPasswordSecret.id
    enableTelemetry: enableAvmTelemetry
  }
}

// LATER: Create additional role assignments for the managed identity
// - Desktop Virtualization Virtual Machine Contributor role
//   - Custom image resource group - which resource groups(s) are they in?
//     ? Determine from image resource ID if custom image?
//   - NSG - we don't use a VM-based NSG
// - Virtual Machine Contributor
//   - NSG - we don't use a VM-based NSG
