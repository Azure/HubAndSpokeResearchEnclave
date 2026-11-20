param uamiName string
param principalId string
param roleDefinitionId string

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: uamiName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(uami.id, principalId, roleDefinitionId)
  scope: uami
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
  }
}
