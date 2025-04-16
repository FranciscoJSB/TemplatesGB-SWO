param location string
param networkSecurityGroupName string
param securityRules array

param environment string
param locationShort string

resource networkSecurityGroupsResource 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${networkSecurityGroupName}-${environment}-${locationShort}'
  location: location
  properties: {
    securityRules: [
      for rule in securityRules: {
        name: rule.name
        properties: {
          protocol: rule.protocol
          sourcePortRange: rule.sourcePortRange
          destinationPortRange: rule.destinationPortRange
          sourceAddressPrefix: rule.sourceAddressPrefix
          destinationAddressPrefix: rule.destinationAddressPrefix
          access: rule.access
          priority: rule.priority
          direction: rule.direction
          sourcePortRanges: rule.sourcePortRanges
          destinationPortRanges: rule.destinationPortRanges
          sourceAddressPrefixes: rule.sourceAddressPrefixes
          destinationAddressPrefixes: rule.destinationAddressPrefixes
        }
      }
    ]
  }
}


