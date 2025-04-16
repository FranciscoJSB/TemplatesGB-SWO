param location string
param publicIpParams array
param environment string
param locationShort string

resource publicIpResources 'Microsoft.Network/publicIPAddresses@2024-05-01' = [
  for (ip,i) in publicIpParams: {
    name: '${ip.name}-${environment}-${locationShort}-${ip.zone}-${i}'
    location: location
    sku: {
      name: 'Standard'
    }
    zones: [
      ip.zone
    ]
    properties: {
      publicIPAddressVersion: 'IPv4'
      publicIPAllocationMethod: 'Static'
    }
  }
]

output publicIpResourceIds array = [
  for ip in publicIpParams: resourceId('Microsoft.Network/publicIPAddresses', ip.name)
]
