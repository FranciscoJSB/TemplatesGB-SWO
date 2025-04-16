param location string
param insightsId string

param ApimServiceParams object
param apis array
param groups array

param environment string
param locationShort string

resource apiManagementService 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  name: '${ApimServiceParams.name}-${environment}-${locationShort}'
  location: location
  sku: {
    name: ApimServiceParams.sku.name  
    capacity: ApimServiceParams.sku.capacity
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: ApimServiceParams.publisherEmail
    publisherName: ApimServiceParams.publisherNames
    virtualNetworkType: ApimServiceParams.virtualNetworkType
    disableGateway: ApimServiceParams.disableGateway
    apiVersionConstraint: ApimServiceParams.apiVersionConstraint
    publicNetworkAccess: ApimServiceParams.publicNetworkAccess
    developerPortalStatus: ApimServiceParams.developerPortalStatus
    releaseChannel: ApimServiceParams.releaseChannel
  }
}

resource apiManagementServiceApis 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = [for api in apis: {
  parent: apiManagementService
  name: api.name
  properties: {
    displayName: api.displayName
    apiRevision: api.revision
    subscriptionRequired: api.subscriptionRequired
    serviceUrl: api.serviceUrl
    path: api.path
    protocols: api.protocols
    subscriptionKeyParameterNames: {
      header: api.subscriptionKeyHeader
      query: api.subscriptionKeyQuery
    }
    isCurrent: api.isCurrent
  }
}]

// Skip system-defined groups
resource apimanagementgroups 'Microsoft.ApiManagement/service/groups@2024-06-01-preview' = [for group in groups: if (group.type != 'system') {
  parent: apiManagementService
  name: group.name
  properties: {
    displayName: group.displayName
    type: group.type
  }
}]

output service_api_mgt_ai_dev_name_resourceId string = apiManagementService.id
output service_api_mgt_ai_dev_name_resourceName string = apiManagementService.name
