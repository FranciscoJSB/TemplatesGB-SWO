param location string

param subnetId string

param storageAccountParams object

param locationShort string
param environment string

resource storageAccountsBlobstorage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: '${storageAccountParams.name}${environment}${locationShort}'
  location: location
  sku: storageAccountParams.sku
  kind: storageAccountParams.kind
  properties: {
    publicNetworkAccess: storageAccountParams.publicNetworkAccess
    accessTier: storageAccountParams.accessTier
  }
}

resource storageAccountQueueService 'Microsoft.Storage/storageAccounts/queueServices@2024-01-01' = {
  parent: storageAccountsBlobstorage
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

var queueNames = [
  'azure-webjobs-blobtrigger-pf4kmng5-2079601327'
  'azure-webjobs-blobtrigger-process-document-medicaltranslat'
  'default'
]

resource storageQueues 'Microsoft.Storage/storageAccounts/queueServices/queues@2024-01-01' = [
  for name in queueNames: {
    name: name
    parent: storageAccountQueueService
    properties: {
      metadata: {}
    }
  }
]

resource storageAccountsBlobstorageDefault 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccountsBlobstorage
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: [
        {
          allowedOrigins: [
            'https://language.cognitive.azure.com'
          ]
          allowedMethods: [
            'DELETE'
            'GET'
            'POST'
            'OPTIONS'
            'PUT'
          ]
          maxAgeInSeconds: 500
          exposedHeaders: [
            '*'
          ]
          allowedHeaders: [
            '*'
          ]
        }
      ]
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
  }
}

var blobContainerNames = [
  '${storageAccountParams.name}-container'
  '1b846aad-41ec-4fa6-90b7-d5936a11f03d-azureml'
  '1b846aad-41ec-4fa6-90b7-d5936a11f03d-azureml-blobstore'
  'app01-documents'
  'azure-webjobs-hosts'
  'default'
  'di01-documents'
  'eventgrid-dead-letter-container'
  'fep-pending'
  'insights-logs-auditevent'
  'insights-metrics-pt1m'
  'pme-complete'
]

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = [
  for name in blobContainerNames: {
    name: name
    parent: storageAccountsBlobstorageDefault
    properties: {
      immutableStorageWithVersioning: {
        enabled: false
      }
      defaultEncryptionScope: '$account-encryption-key'
      denyEncryptionScopeOverride: false
      publicAccess: 'None'
    }
  }
]

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2024-01-01' = {
  parent: storageAccountsBlobstorage
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: [
        {
          allowedOrigins: [
            'https://mlworkspace.azure.ai'
            'https://ml.azure.com'
            'https://*.ml.azure.com'
            'https://ai.azure.com'
            'https://*.ai.azure.com'
          ]
          allowedMethods: [
            'GET'
            'HEAD'
            'PUT'
            'DELETE'
            'OPTIONS'
            'POST'
          ]
          maxAgeInSeconds: 1800
          exposedHeaders: [
            '*'
          ]
          allowedHeaders: [
            '*'
          ]
        }
      ]
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

var fileShareNames = [
  '1b846aad-41ec-4fa6-90b7-d5936a11f03d-code'
  'default'
  'func-medicaltranlation-internal-eventhandler-devb6b5'
  'func-medicaltranslationapi-dev-eus9b34'
  'process-document-medicaltranslationa434'
]

resource fileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2024-01-01' = [
  for name in fileShareNames: {
    name: name
    parent: fileServices
    properties: {
      accessTier: 'TransactionOptimized'
      shareQuota: 102400
      enabledProtocols: 'SMB'
    }
  }
]

output storageAccounts_documentsaiblobstorage_name_resourceId string = storageAccountsBlobstorage.id
output storageAccounts_documentsaiblobstorage_name_primaryEndpoints object = storageAccountsBlobstorage.properties.primaryEndpoints
output storageAccounts_documentsaiblobstorage_name_primaryEndpointsBlob string = storageAccountsBlobstorage.properties.primaryEndpoints.blob
