param location string
param subnetId string

param privateEndpointsParams object

param environment string
param locationShort string

@description('Create Private EndPoints Resource')
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = [
  for (pve, i) in privateEndpointsParams.endpoints: {
    name: '${pve.privateEndpointName}-${environment}-${locationShort}'
    location: location
    properties: {
      subnet: {
        id: subnetId
      }
      ipConfigurations: pve.groupId == 'Sql' //cosmos
        ? [
            {
              name: '${pve.memberName}-${environment}-${locationShort}'
              properties: {
                groupId: pve.groupId
                memberName: '${pve.memberName}-${environment}-${locationShort}'
                privateIPAddress: pve.privateIPAddressEp
              }
            }
            {
              name: '${pve.memberName}-${environment}-${locationShort}-${pve.firstFQDN}'
              properties: {
                groupId: pve.groupId
                memberName: '${pve.memberName}-${environment}-${locationShort}-${pve.firstFQDN}'
                privateIPAddress: pve.privateIPAddressEpAdditional
              }
            }
            {
              name: '${pve.resourceName}-${environment}-${locationShort}-${pve.secondFQDN}'
              properties: {
                groupId: pve.groupId
                memberName: '${pve.memberName}-${environment}-${locationShort}-${pve.secondFQDN}'
                privateIPAddress: pve.privateIPAddressEpThird
              }
            }
          ]
        : pve.groupId == 'registry'
            ? [
                {
                  name: pve.memberName
                  properties: {
                    groupId: pve.groupId
                    memberName: pve.memberName
                    privateIPAddress: pve.privateIPAddressEp
                  }
                }
                {
                  name: '${pve.resourceName}-${environment}-${locationShort}-${location}'
                  properties: {
                    groupId: pve.groupId
                    memberName: 'registry_data_${location}'
                    privateIPAddress: pve.privateIPAddressEpAdditional
                  }
                }
              ]
            : pve.groupId == 'account' && contains(pve.resourceName, 'ais-') //cognitiveServices
                ? [
                    {
                      name: 'default'
                      properties: {
                        groupId: pve.groupId
                        memberName: 'default'
                        privateIPAddress: pve.privateIPAddressEp
                      }
                    }
                    {
                      name: 'secondary'
                      properties: {
                        groupId: pve.groupId
                        memberName: 'secondary'
                        privateIPAddress: pve.privateIPAddressEpAdditional
                      }
                    }
                    {
                      name: 'third'
                      properties: {
                        groupId: pve.groupId
                        memberName: 'third'
                        privateIPAddress: pve.privateIPAddressEpThird
                      }
                    }
                  ]
                : pve.groupId == 'amlworkspace' //machineLearningWorkspace
                    ? [
                        {
                          name: 'default'
                          properties: {
                            groupId: pve.groupId
                            memberName: 'default'
                            privateIPAddress: pve.privateIPAddressEp
                          }
                        }
                        {
                          name: 'notebook'
                          properties: {
                            groupId: pve.groupId
                            memberName: 'notebook'
                            privateIPAddress: pve.privateIPAddressEpAdditional
                          }
                        }
                        {
                          name: 'inference'
                          properties: {
                            groupId: pve.groupId
                            memberName: 'inference'
                            privateIPAddress: pve.privateIPAddressEpThird
                          }
                        }
                        {
                          name: 'models'
                          properties: {
                            groupId: pve.groupId
                            memberName: 'models'
                            privateIPAddress: pve.privateIPAddressEpFourth
                          }
                        }
                      ]
                    : [
                        {
                          name: pve.privateIpName
                          properties: {
                            groupId: pve.groupId
                            memberName: pve.memberName
                            privateIPAddress: pve.privateIPAddressEp
                          }
                        }
                      ]
      customNetworkInterfaceName: '${pve.privateEndpointName}-${environment}-${locationShort}-NIC'
      privateLinkServiceConnections: [
        {
          name: pve.privateEndpointName
          properties: {
            privateLinkServiceId: (pve.resourceType == 'Storage/blobservices' || pve.resourceType == 'Storage/queueservices' || pve.resourceType == 'Storage/fileservices')
              ? resourceId(
                  '${pve.resourceGroupName}-${environment}-${locationShort}',
                  'Microsoft.Storage/storageAccounts',
                  '${pve.resourceName}${environment}${locationShort}'
                )
              : (pve.resourceType == 'KeyVault/vaults' || pve.resourceType == 'ContainerRegistry/registries')
                  ? resourceId(
                      '${pve.resourceGroupName}-${environment}-${locationShort}',
                      'Microsoft.${pve.resourceType}',
                      '${pve.resourceName}${environment}${locationShort}'
                    )
                  : resourceId(
                      '${pve.resourceGroupName}-${environment}-${locationShort}',
                      'Microsoft.${pve.resourceType}',
                      '${pve.resourceName}-${environment}-${locationShort}'
                    )
            groupIds: [
              pve.groupId
            ]
            privateLinkServiceConnectionState: {
              status: 'Approved'
              actionsRequired: 'None'
            }
          }
        }
      ]
      customDnsConfigs: length(pve.customDnsConfigs) > 0 ? pve.customDnsConfigs : []
    }
  }
]
