param location string
param subnetSpoke6Id string
param ElasticPlanId string

param functionApps array
param webConfigs array
param functions array
param isCodeDeployed bool

param environment string
param locationShort string

@batchSize(1)
resource functionAppResources 'Microsoft.Web/sites@2024-04-01' = [
  for app in functionApps: {
    name: '${app.name}-${environment}-${locationShort}'
    location: location
    kind: 'functionapp,linux'
    properties: {
      serverFarmId: ElasticPlanId
      reserved: true
      vnetRouteAllEnabled: true
      vnetContentShareEnabled: true
      siteConfig: {
        numberOfWorkers: 1
        linuxFxVersion: app.linuxFxVersion
        alwaysOn: false
        http20Enabled: false
        minimumElasticInstanceCount: 1
        appSettings: [
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: app.linuxFxVersion == 'PYTHON|3.12' ? 'python' : 'dotnet-isolated'
          }
          {
            name: 'WEBSITE_RUN_FROM_PACKAGE'
            value: '1'
          }
        ]
      }
      clientCertMode: 'Required'
      httpsOnly: true
      publicNetworkAccess: app.publicNetworkAccess
      virtualNetworkSubnetId: subnetSpoke6Id
      keyVaultReferenceIdentity: 'SystemAssigned'
    }
  }
]

output functionAppResourceIds array = [for app in functionApps: resourceId('Microsoft.Web/sites', app.name)]

resource webConfigsResources 'Microsoft.Web/sites/config@2024-04-01' = [
  for config in webConfigs: {
    parent: functionAppResources[config.parentIndex]
    name: 'web'
    properties: {
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
        supportCredentials: false
      }
      ipSecurityRestrictions: config.ipSecurityRestrictions
      ipSecurityRestrictionsDefaultAction: config.ipSecurityRestrictionsDefaultAction
      scmIpSecurityRestrictions: [
        {
          ipAddress: 'Any'
          action: 'Allow'
          priority: 2147483647
          name: 'Allow all'
          description: 'Allow all access'
        }
      ]
      scmIpSecurityRestrictionsDefaultAction: 'Allow'
      scmIpSecurityRestrictionsUseMain: false
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
    }
  }
]
// Only active if code is deployed
// This is a workaround for the fact that function definitions are not created automatically when using the 'functionapp,linux' kind
resource functionDefinitions 'Microsoft.Web/sites/functions@2024-04-01' = [
  for fn in functions: if (isCodeDeployed) {
    name: fn.name
    parent: functionAppResources[fn.parentIndex]
    properties: {
      config: {
        name: fn.name
        entryPoint: fn.entryPoin
        scriptFile: fn.scriptFile
        language: fn.language
        bindings: fn.bindings
      }
    }
  }
]
// This assumes function names match code and will be registered automatically after code deployment
output functionDefinitionResourceIds array = [
  for fn in functions: resourceId('Microsoft.Web/sites/functions', functionAppResources[fn.parentIndex].name, fn.name)
]
