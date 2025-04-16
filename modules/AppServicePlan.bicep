param plans array
param location string
param environment string
param locationShort string

resource serverfarms 'Microsoft.Web/serverfarms@2024-04-01' = [for (plan, i) in plans: {
  name: '${plan.name}-${environment}-${locationShort}-${i}'
  location: location
  sku: plan.sku
  kind: plan.kind
  properties: plan.properties
}]

output planIds array = [for (plan,i) in plans: resourceId('Microsoft.Web/serverfarms', '${plan.name}-${environment}-${locationShort}-${i}')]

