param storageAccountId string
@minLength(3)
@maxLength(24)
param sinkStorageAccountName string
param sinkFileShareName string
@minLength(3)
@maxLength(24)
param sourceStorageAccountName string
param adfName string
param ingestPipelineName string
param workspaceName string
@allowed([
  'Public'
  // 'Private'
  // 'Airlock'
])
param storageAccountType string
param additionalSinkFolderPath string
// LATER: Validate the KV URL has the https:// prefix already
param sinkConnStringKvBaseUrl string

param containerName string = ''
param blobPathEndsWith string = ''

resource trigger 'Microsoft.DataFactory/factories/triggers@2018-06-01' = {
  name: '${adfName}/trigger_ws_${workspaceName}_${storageAccountType}${!empty(blobPathEndsWith) ? '_${replace(blobPathEndsWith, '.', '')}' : ''}_BlobCreated'
  properties: {
    type: 'BlobEventsTrigger'
    typeProperties: {
      // No blobPathBeginsWith property means all containers will be matched (used for ingest)
      blobPathBeginsWith: !empty(containerName) ? '/${containerName}/blobs/' : null
      blobPathEndsWith: blobPathEndsWith
      ignoreEmptyBlobs: true
      events: [
        'Microsoft.Storage.BlobCreated'
      ]
      scope: storageAccountId
    }
    pipelines: [
      {
        pipelineReference: {
          referenceName: ingestPipelineName
          type: 'PipelineReference'
        }
        parameters: {
          sourceStorageAccountName: sourceStorageAccountName
          sinkStorageAccountName: sinkStorageAccountName
          fileName: '@triggerBody().fileName'
          sourceFolderPath: '@triggerBody().folderPath'
          sinkFolderPath: additionalSinkFolderPath
          sinkFileShareName: sinkFileShareName
          sinkConnStringKvBaseUrl: sinkConnStringKvBaseUrl
        }
      }
    ]
  }
}
