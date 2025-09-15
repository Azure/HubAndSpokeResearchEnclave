param location string
param namingStructure string
param adfName string
@minLength(3)
@maxLength(24)
param prjStorageAcctName string
@minLength(3)
@maxLength(24)
param prjPublicStorageAcctName string
@minLength(3)
@maxLength(24)
param airlockStorageAcctName string
param airlockFileShareName string
param privateFileShareName string
param approverEmail string
param processNotificationEmail string
param sourceFolderPath string
param airlockFolderPath string
param exportApprovedContainerName string
param privateContainerName string

param pipelineNames pipelineNamesType

@description('The URI of the Key Vault that contains the connection string airlock review storage account.')
param keyVaultUri string

@description('The URI of the Key Vault that contains the connection string for the project private storage account\'s file share.')
param privateConnStringKvBaseUrl string

param roles object
param deploymentNameStructure string

param subWorkloadName string
param tags object = {}

import { pipelineNamesType } from '../../../shared-modules/types/pipelineNamesType.bicep'

var baseName = !empty(subWorkloadName)
  ? replace(namingStructure, '{subWorkloadName}', subWorkloadName)
  : replace(namingStructure, '-{subWorkloadName}', '')

// Project's private storage account
resource prjStorageAcct 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: prjStorageAcctName
}

resource adf 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: adfName
}

// As of 2022-10-23, Bicep does not have type info for this resource type
#disable-next-line BCP081
resource adfConnection 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: 'api-${adfName}'
  location: location
  properties: {
    displayName: 'Data Factory'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuredatafactory')
    }
    parameterValueType: 'Alternative'
  }
  tags: tags
}

// As of 2022-10-23, Bicep does not have type info for this resource type
#disable-next-line BCP081
resource storageConnection 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: 'api-${prjStorageAcctName}'
  location: location
  properties: {
    displayName: 'Project storage ${prjStorageAcctName}'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
    }
    parameterValueSet: {
      name: 'managedIdentityAuth'
      value: {}
    }
  }
  tags: tags
}

var isAzureUSGov = (az.environment().name == 'AzureUSGovernment')

// As of 2022-10-23, Bicep does not have type info for this resource type
#disable-next-line BCP081
resource emailConnection 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: 'api-office365'
  location: location
  properties: {
    displayName: 'Office 365${isAzureUSGov ? ' GCC-High' : ''}'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
    }
    // This parameterValueSet is only supported when deploying to Azure Gov
    parameterValueSet: isAzureUSGov
      ? {
          // Per https://learn.microsoft.com/en-us/azure/backup/backup-reports-email?tabs=arm
          name: 'oauthGccHigh'
          values: {
            token: {
              value: 'https://logic-apis-${location}.consent.azure-apihub.us/redirect'
            }
          }
        }
      : null
  }
  tags: tags
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: replace(baseName, '{rtype}', 'logic')
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    definition: json(loadTextContent('./content/logicAppWorkflow.json'))
    parameters: {
      '$connections': {
        value: {
          azureblob: {
            connectionId: storageConnection.id
            connectionName: 'azureblob'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azureblob')
          }
          azuredatafactory: {
            connectionId: adfConnection.id
            connectionName: 'azuredatafactory'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuredatafactory')
          }
          office365: {
            connectionId: emailConnection.id
            connectionName: 'office365'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
          }
        }
      }
      subscriptionId: {
        value: subscription().subscriptionId
      }
      dataFactoryRG: {
        value: resourceGroup().name
      }
      dataFactoryName: {
        value: adf.name
      }
      privateStorageAccountName: {
        value: prjStorageAcctName
      }
      privateFolderPath: {
        value: sourceFolderPath
      }
      airlockStorageAccountName: {
        value: airlockStorageAcctName
      }
      approverEmail: {
        value: approverEmail
      }
      airlockFileShareName: {
        value: airlockFileShareName
      }
      airlockFolderPath: {
        value: airlockFolderPath
      }
      publicStorageAccountName: {
        value: prjPublicStorageAcctName
      }
      // LATER: Add parameters for pipeline names
      airlockConnStringKvBaseUrl: {
        value: keyVaultUri
      }
      privateContainerName: {
        value: privateContainerName
      }
      exportApprovedContainerName: {
        value: exportApprovedContainerName
      }
      processNotificationEmail: {
        value: processNotificationEmail
      }
      privateFileShareName: {
        value: privateFileShareName
      }
      privateConnStringKvBaseUrl: {
        value: privateConnStringKvBaseUrl
      }
      pipelineNameBlobToFileShare: {
        value: pipelineNames.blobToFileShare
      }
      pipelineNameFileShareToBlob: {
        value: pipelineNames.fileShareToBlob
      }
      pipelineNameFileShareToFileShare: {
        value: pipelineNames.fileShareToFileShare
      }
    }
  }
  tags: tags
}

// Set RBAC on ADF for Logic App
module logicAppAdfRbacModule '../../../module-library/roleAssignments/roleAssignment-adf.bicep' = {
  name: take(replace(deploymentNameStructure, '{rtype}', 'logic-rbac-adf'), 64)
  params: {
    adfName: adf.name
    principalId: logicApp.identity.principalId
    roleDefinitionId: roles.DataFactoryContributor
    principalType: 'ServicePrincipal'
  }
}

// Set RBAC on project Storage Account for Logic App
module logicAppPrivateStRbacModule '../../../module-library/roleAssignments/roleAssignment-st.bicep' = {
  name: take(replace(deploymentNameStructure, '{rtype}', 'logic-rbac-st'), 64)
  params: {
    principalId: logicApp.identity.principalId
    roleDefinitionId: roles.StorageBlobDataContributor
    storageAccountName: prjStorageAcct.name
    principalType: 'ServicePrincipal'
  }
}
