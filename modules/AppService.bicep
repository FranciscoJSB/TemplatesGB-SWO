param location string

param appServiceParams object

param subnetSpoke6Id string
param managedIdentityId string
param LinuxPlanId string
param environment string
param locationShort string

resource translationAppService 'Microsoft.Web/sites@2024-04-01' = {
  name: '${appServiceParams.name}-${environment}-${locationShort}'
  location: location
  kind: 'app,linux,container'
  identity: appServiceParams.identity == 'UserAssigned'
    ? {
        type: 'UserAssigned'
        userAssignedIdentities: {
          '${managedIdentityId}': {}
        }
      }
    : {
        type: 'SystemAssigned'
      }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${appServiceParams.name}-${environment}-${locationShort}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${appServiceParams.name}-${environment}-${locationShort}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: LinuxPlanId
    reserved: true
    vnetRouteAllEnabled: true
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'DOCKER|acrdeveusgeo.azurecr.io/container-medicaltranslation:medicaltranslation'
      acrUseManagedIdentityCreds: true
      alwaysOn: true
      http20Enabled: false
      functionAppScaleLimit: 0
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    ipMode: 'IPv4'
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    endToEndEncryptionEnabled: false
    redundancyMode: 'None'
    publicNetworkAccess: 'Disabled'
    virtualNetworkSubnetId: subnetSpoke6Id
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource appServiceTranslationftpPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = {
  parent: translationAppService
  name: 'ftp'
  properties: {
    allow: false
  }
}

resource appServiceTranslationscmPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01' = {
  parent: translationAppService
  name: 'scm'
  properties: {
    allow: false
  }
}

resource appServiceTranslationConfig 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: translationAppService
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: 'DOCKER|acrdeveusgeo.azurecr.io/container-medicaltranslation:medicaltranslation'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: true
    acrUserManagedIdentityID: '1066e8eb-7e24-4569-826a-e9f70aa1d723'
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: 'REDACTED'
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetName: '109330f6-2849-4c56-b6fa-dd616fd47261_subnet-spoke6'
    vnetRouteAllEnabled: true
    vnetPrivatePortsCount: 0
    publicNetworkAccess: 'Disabled'
    localMySqlEnabled: false
    xManagedServiceIdentityId: 14327
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    elasticWebAppScaleLimit: 0
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {}
  }
}

output appServiceId string = translationAppService.id
