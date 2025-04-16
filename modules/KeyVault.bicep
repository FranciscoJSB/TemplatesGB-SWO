param keyVaultParams object
//param virtualMachineParams object 

param location string
param subnet5Id string
param	subnet6Id string
param locationShort string
param environment string
param agentDevOpsObjectId string

//@description('URI for KeyVault')
//var vaultUri = 'https://${keyVaultParams.name}${environment().suffixes.keyvaultDns}'

@description('CosmosDB Id')
var cosmosDBId = 'f27cf75b-16d5-46ad-b9dd-fe4d04460be3' //taken from MS website for grid reference

@description('key vault')
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${keyVaultParams.name}${environment}${locationShort}'
  location: location
  properties: {
    sku: keyVaultParams.sku
    tenantId: subscription().tenantId
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []

      virtualNetworkRules:[
        {
          id:subnet5Id
          ignoreMissingVnetServiceEndpoint: true
        }
        {
          id:subnet6Id
          ignoreMissingVnetServiceEndpoint: true
        } 
      ]
    }
    accessPolicies: [
      {
        objectId: cosmosDBId
        tenantId: subscription().tenantId
        permissions: {
          keys: [
            'get'
            'list'
            'wrapKey'
            'unwrapKey'
          ]
        }
      }
      {
        tenantId: tenant().tenantId
        objectId: '43b2d11b-c303-4858-a7d1-5038b704f60e'
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          certificates: [
            'all'
          ]
          storage: []
        }
      }
      {
        tenantId: tenant().tenantId
        objectId: '5985df00-523d-4f91-bd30-91ca176dcce0'
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          certificates: [
            'all'
          ]
          storage: []
        }
      }
      {
        tenantId: tenant().tenantId
        objectId: 'd2810312-38c2-4cb1-9d50-de725b1408d5'  ////// REMOVE THIS WHEN DEPLOYING TO PROD AND THROUGH PIPELINE
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          certificates: [
            'all'
          ]
          storage: []
        }
      }
      {
        tenantId: tenant().tenantId
        objectId: agentDevOpsObjectId
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          certificates: [
            'all'
          ]
          storage: []
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization:false                    
    enablePurgeProtection: true
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Disabled'

  }
}

// resource secretVM 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [ for i in range(1,length(virtualMachineParams)):{
//   name: 'vm${i}AdminPassword'
//   parent: keyVault
//   properties: {
//     value: passwordvm.properties.outputs.password
//   }
// }]
resource secretVM 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'AIWorkspaceKey'
  parent: keyVault
  properties: {
    value: passwordvm.properties.outputs.password
  }
}


resource passwordvm 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'password-generate'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    azPowerShellVersion: '7.0' 
    retentionInterval: 'P1D'
    scriptContent: loadTextContent('../scripts/random-password-generator.ps1')
  }
}

output keyvaultname string = keyVault.name
output keyvaultID string = keyVault.id
