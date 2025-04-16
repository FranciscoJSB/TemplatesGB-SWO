
param location string
param InsightsParams array

param workspaceId string
param locationShort string
param environment string

resource appInsights 'microsoft.insights/components@2020-02-02' = [for cfg in InsightsParams: {
  name: '${cfg.name}-${environment}-${locationShort}'
  location: location
  kind: cfg.kind
  properties: {
    Application_Type: cfg.Application_Type
    Flow_Type: cfg.Flow_Type
    Request_Source: cfg.Request_Source
    RetentionInDays: cfg.RetentionInDays
    WorkspaceResourceId: workspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: cfg.publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: cfg.publicNetworkAccessForQuery
  }
}]

output insightsId array = [
  for (cfg,i) in InsightsParams: resourceId('Microsoft.Insights/components', '${cfg.name}-${environment}-${locationShort}')
]
