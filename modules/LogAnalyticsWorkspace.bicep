param logAnalyticsWorkspaceParams object
param location string
param environment string
param locationShort string

resource workspacesLogAnalyticsWorkspaceResource 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${logAnalyticsWorkspaceParams.workspaceName}-${environment}-${locationShort}'
  location: location
  properties: {
    sku: {
      name: logAnalyticsWorkspaceParams.skuName
    }
    retentionInDays: logAnalyticsWorkspaceParams.retentionInDays
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: logAnalyticsWorkspaceParams.dailyQuotaGb
    }
    publicNetworkAccessForIngestion: logAnalyticsWorkspaceParams.publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: logAnalyticsWorkspaceParams.publicNetworkAccessForQuery
  }
}

output logAnalyticsWorkspaceId string = workspacesLogAnalyticsWorkspaceResource.id
