param location string
param subnetId string
param PublicIpId string

@secure()
param passsword string

@description('Configuration object for the virtual machine')
param virtualMachineParams object
param dataDisk_list object

param environment string
param locationShort string

resource virtualMachineResource 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: '${virtualMachineParams.name}-${environment}-${locationShort}'
  location: location
  zones: [virtualMachineParams.zones]
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineParams.size
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: virtualMachineParams.imageSku
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: virtualMachineParams.storageAccountType
        }
      }
      dataDisks: [
        for i in range(1, length(dataDisk_list)): {
          name: '${virtualMachineParams.name}_disk${i+1}'
          createOption: 'Empty'
          caching: 'ReadOnly'
          writeAcceleratorEnabled: false
          diskSizeGB: dataDisk_list['dataDisk${i}'].size
          lun: i
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceResource.id
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineParams.name
      adminUsername: virtualMachineParams.adminUsername
      adminPassword: passsword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: 'AutomaticByOS'
        }
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource networkInterfaceResource 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: '${virtualMachineParams.name}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${virtualMachineParams.name}-nic'
        properties: {
          privateIPAddress: virtualMachineParams.privateIpAddress
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: PublicIpId
            properties: {
              deleteOption: 'Detach'
            }
          }
          subnet: {
            id: subnetId
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}
