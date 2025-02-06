param name string
param location string = resourceGroup().location
param hostPoolId string
param friendlyName string
param applications array
param tags object

param principalId string
param roleDefinitionId string

/*
 * TYPES
 */

@export()
type application = {
  name: string
  applicationType: 'InBuilt' | 'MsixApplication'
  filePath: string
  friendlyName: string
  @minValue(0)
  iconIndex: int
  iconPath: string
  showInPortal: bool?
  commandLineSetting: 'Allow' | 'DoNotAllow' | 'Require'
  commandLineArguments: string?
}

/*
 * RESOURCES
 */

resource vdag 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: name
  location: location
  properties: {
    applicationGroupType: 'RemoteApp'
    hostPoolArmPath: hostPoolId
    friendlyName: friendlyName
  }
  tags: tags
}

resource remoteApplications 'Microsoft.DesktopVirtualization/applicationGroups/applications@2023-09-05' = [
  for app in applications: {
    name: app.name
    parent: vdag
    properties: {
      commandLineSetting: contains(app, 'commandLineSetting') && !empty(app.commandLineSetting)
        ? app.commandLineSetting
        : 'Allow'
      commandLineArguments: contains(app, 'commandLineArguments') && !empty(app.commandLineArguments)
        ? app.CommandLineArguments
        : ''

      applicationType: app.applicationType
      filePath: app.filePath
      friendlyName: app.friendlyName
      iconIndex: app.iconIndex
      iconPath: app.iconPath
      showInPortal: app.showInPortal
    }
  }
]

// Assign the specified role to the specified principal
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' =
  if (!empty(principalId) && !empty(roleDefinitionId)) {
    name: guid(vdag.id, principalId, roleDefinitionId)
    scope: vdag
    properties: {
      roleDefinitionId: roleDefinitionId
      principalId: principalId
    }
  }

output id string = vdag.id
output name string = vdag.name
