param location string
param containerRegistryParams object

param environment string
param locationShort string

param scopeMaps array

resource registriesResource 'Microsoft.ContainerRegistry/registries@2024-11-01-preview' = {
  name: '${containerRegistryParams.name}${environment}${locationShort}'
  location: location
  sku: {
    name: containerRegistryParams.sku
  }
  properties: {
    adminUserEnabled: containerRegistryParams.adminUserEnabled
    networkRuleSet: containerRegistryParams.networkRuleSet
    policies: containerRegistryParams.policies
    encryption: containerRegistryParams.encryption
    publicNetworkAccess: containerRegistryParams.publicNetworkAccess
    zoneRedundancy: containerRegistryParams.zoneRedundancy
    anonymousPullEnabled: containerRegistryParams.anonymousPullEnabled
  }
}

resource acrReplication 'Microsoft.ContainerRegistry/registries/replications@2024-11-01-preview' = if(location != 'westus') {
  parent: registriesResource
  name: location
  location: location
  properties: {
    regionEndpointEnabled: true
    zoneRedundancy: 'Enabled'
  }
}

resource acrScopeMaps 'Microsoft.ContainerRegistry/registries/scopeMaps@2024-11-01-preview' = [for scopeMap in scopeMaps: {
  parent: registriesResource
  name: scopeMap.name
  properties: {
    description: scopeMap.description
    actions: scopeMap.actions
  }
}]

output registryId string = registriesResource.id
