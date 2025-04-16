param location string
param cosmosAccounts array
param containersDB1 array

param environment string
param locationShort string

@batchSize(1)
resource cosmosAccountResources 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' = [
  for account in cosmosAccounts: {
    name: '${account.name}-${environment}-${locationShort}'
    location: location
    kind: account.kind
    properties: account.properties
  }
]

output cosmosAccountResources array = [
  for account in cosmosAccounts: {
    name: account.name
    id: resourceId('Microsoft.DocumentDB/databaseAccounts', account.name)
  }
]

resource cosmosDbTranslation 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-12-01-preview' = {
  parent: cosmosAccountResources[0]
  name: 'MedicalTranslations'
  properties: {
    resource: {
      id: 'MedicalTranslations'
    }
  }
}

@batchSize(1)
resource translationContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-12-01-preview' = [
  for container in containersDB1: {
    parent: cosmosDbTranslation
    name: container.name
    properties: {
      resource: {
        id: container.name
        indexingPolicy: {
          includedPaths: [
            {
              path: '/*'
            }
          ]
        }
        partitionKey: {
          paths: [
            container.partitionKeyPath
          ]
          kind: 'Hash'
          version: 2
        }
      }
    }
  }
]

output translationsContainers array = [
  for container in containersDB1: {
    name: container.name
    id: resourceId(
      'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers',
      cosmosAccountResources[0].name,
      cosmosDbTranslation.name,
      container.name
    )
  }
]


