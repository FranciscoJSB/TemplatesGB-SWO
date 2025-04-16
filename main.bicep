targetScope = 'subscription'
param isCodeDeployed bool = false
param isInitialDeployment bool = false
param deployAgent bool = false

@description('Name of the resource group for networking resources.')
param networkingRGName string
@description('Name of the resource group for AI resources.')
param aiRGName string
@description('Name of the resource group for core resources.')
param coreRGName string
@description('Name of the resource group for DevOps agent resources.')
param devopsAgentRGName string

@allowed([
  'eastus'
  'westus'
  'centralus'
  'northcentralus'
  'southcentralus'
  'westus2'
  'eastus2'
  'canadacentral'
  'canadaeast'
])
@description('Location for all resources.')
param location string
param locationShort string
param environment string

@description('Name of the virtual network.')
param subnetNameSpoke5 string
param subnetNameSpoke6 string
param subnetNameSpoke0 string
param vnetName string

// Action Group Parameters
param actionGroupName object
param armRoleReceivers array

//AI Cognitive Services Parameters
param TranslationServiceParams object
param OpenAIParams object
param modelDeployments array
param DocumentIntelligenceParams object
param TextTranslationServiceParams object
param LanguageTranslationParam object

// AI Workspace Parameters
param WorkspacesParams object

// APIM Parameters
param ApimServiceParams object
param apis array
param groups array

// Application Insights Parameters
param InsightsParams array

// App service Parameters
param appServiceParams object

// App Service Plan Parameters
param plans array

// Container Registry Parameters
param containerRegistryParams object
param scopeMaps array

// Cosmos DB Parameters
param cosmosAccounts array
param containersDB1 array

// Event Grid Parameters
param eventGridParams object

// Functions Parameters
param functionApps array
param webConfigs array
param functions array

// Key Vault Parameters
param keyVaultParams object
param agentDevOpsObjectId string

// Log Analytics Parameters
param logAnalyticsWorkspaceParams object

// Managed Identity Parameters
param ManagedIdentityName string

// Network Security Group Parameters
param networkSecurityGroupName string

// Private Endpoint Parameters
param privateEndpointsParams object

// Public IP Parameters
param publicIpParams array

// Storage Account Parameters
param storageAccountParams object

// Virtual machine Parameters
param virtualMachineParams object
param dataDisks_list object

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Existing resources
@description('Name of the existing virtual network.')
resource existingVnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: vnetName
  scope: resourceGroup(rgNetworking.name)
}
@description('Name of the existing subnet network.')
resource existingSubnetSpoke5 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: existingVnet
  name: subnetNameSpoke5
}
@description('Name of the existing subnet network.')
resource existingSubnetSpoke6 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: existingVnet
  name: subnetNameSpoke6
}
@description('Name of the existing subnet network.')
resource existingSubnetSpoke0 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: existingVnet
  name: subnetNameSpoke0
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@description('Name of the existing resource group for networking resources.')
resource rgNetworking 'Microsoft.Resources/resourceGroups@2024-11-01' existing = {
  name: networkingRGName
  scope: subscription()
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource rgAI 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${aiRGName}-${environment}-${locationShort}'
  location: location
}

resource rgCore 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${coreRGName}-${environment}-${locationShort}'
  location: location
}

resource rgDevOps 'Microsoft.Resources/resourceGroups@2021-04-01' = if(deployAgent) {
  name: '${devopsAgentRGName}-devops-${environment}-${locationShort}'
  location: location
}

@description('Create Storage Account')
module storageAccount './modules/StorageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    subnetId: existingSubnetSpoke5.id
    location: location
    storageAccountParams: storageAccountParams
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgAI.name)
  dependsOn: [
    rgAI
  ]
}
@description('Create action group')
module actionGroup './modules/ActionGroup.bicep' = {
  name: 'actionGroup'
  params: {
    actionGroupName: actionGroupName
    armRoleReceivers: armRoleReceivers
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgNetworking.name)
}
@description('Create Key Vault')
module keyVault './modules/KeyVault.bicep' = {
  name: 'keyVault'
  params: {
    subnet5Id: existingSubnetSpoke5.id
    subnet6Id: existingSubnetSpoke6.id
    location: location
    keyVaultParams: keyVaultParams
    locationShort: locationShort
    environment: environment
    agentDevOpsObjectId: agentDevOpsObjectId
    //virtualMachineParams: virtualMachineParams
  }
  scope: resourceGroup(rgCore.name)
  dependsOn: [
    rgCore
  ]
}
@description('Create Function App')
module managedIdentity './modules/ManagedIdentity.bicep' = {
  name: 'managedIdentity'
  params: {
    location: location
    ManagedIdentityName: ManagedIdentityName
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgCore.name)
  dependsOn: [
    rgCore
  ]
}
@description('Create Log Analytics Workspace')
module logAnalytics './modules/LogAnalyticsWorkspace.bicep' = {
  name: 'logAnalytics'
  params: {
    logAnalyticsWorkspaceParams: logAnalyticsWorkspaceParams
    location: location
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgCore.name)
}
@description('Create Application Insights')
module applicationInsights './modules/ApplicationInsights.bicep' = {
  name: 'applicationInsights'
  params: {
    workspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    InsightsParams: InsightsParams
    location: location
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgCore.name)
}
@description('Create App Service Plan')
module appServicePlan './modules/AppServicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    location: location
    plans: plans
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgCore.name)
}
@description('Create API Management')
module apiManagement './modules/ApiManagementService.bicep' = {
  name: 'apiManagement'
  params: {
    insightsId: applicationInsights.outputs.insightsId[0]
    ApimServiceParams: ApimServiceParams
    location: location
    apis: apis
    groups: groups
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgAI.name)
  dependsOn: [
    appServicePlan
  ]
}
@description('Create App Service')
module appService './modules/AppService.bicep' = {
  name: 'appService'
  params: {
    appServiceParams: appServiceParams
    location: location
    subnetSpoke6Id: existingSubnetSpoke6.id
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    LinuxPlanId: appServicePlan.outputs.planIds[0]
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgAI.name)
  dependsOn:[
      apiManagement
    ]
}
@description('Create Cognitive Services')
// This module creates the AI Cognitive Services resources.
// It includes the translation service, OpenAI service, and other related services.
// The parameters for this module are defined above and passed in when the module is created.
module aiCognitiveServices './modules/AICognitiveServices.bicep' = {
  name: 'aiCognitiveServices'
  params: {
    subnet5Id: existingSubnetSpoke5.id
    subnet6Id: existingSubnetSpoke6.id
    location: location
    TranslationServiceParams: TranslationServiceParams
    OpenAIParams: OpenAIParams
    modelDeployments: modelDeployments
    DocumentIntelligenceParams: DocumentIntelligenceParams
    TextTranslationServiceParams: TextTranslationServiceParams
    LanguageTranslationParam: LanguageTranslationParam
    storageAccountId: storageAccount.outputs.storageAccounts_documentsaiblobstorage_name_resourceId
    isInitialDeployment:isInitialDeployment
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgAI.name)
  dependsOn: [
    storageAccount
    appServicePlan
    managedIdentity
    logAnalytics
    applicationInsights
  ]
}
@description('Create AI Workspace')
module aiWorkspace './modules/AiWorkspace.bicep' = {
  name: 'aiworkspace'
  params: {
    location: location
    storageAccounts_documentsaiblobstorage_name_resourceId: storageAccount.outputs.storageAccounts_documentsaiblobstorage_name_resourceId
    keyvaultID: keyVault.outputs.keyvaultID
    accounts_MedicalTranslation_AI_Services_name_resourceId: aiCognitiveServices.outputs.accounts_MedicalTranslation_AI_Services_name_resourceId
    insightsId: applicationInsights.outputs.insightsId[0]
    WorkspacesParams: WorkspacesParams
    password: kv.getSecret('AIWorkspaceKey')
    translationServiceEndpoint: aiCognitiveServices.outputs.translationServiceEndpoint
    openAIEndpoint: aiCognitiveServices.outputs.openAIServiceEndpoint
    documentIntelligenceEndpoint: aiCognitiveServices.outputs.documentIntelligenceEndpoint
    textTranslationServiceEndpoint: aiCognitiveServices.outputs.textTranslationEndpoint
    medicalTranslationEndpoint: aiCognitiveServices.outputs.medicalTranslationEndpoint
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgAI.name)
  dependsOn:[
    keyVault
    storageAccount
  ]
}
@description('Create Container Registry')
module containerRegistry './modules/ContainerRegistry.bicep' = {
  name: 'containerRegistry'
  params: {
    location: location
    containerRegistryParams: containerRegistryParams
    scopeMaps: scopeMaps
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgAI.name)
}
@description('Create Cosmos DB')
module cosmosDB './modules/CosmosDB.bicep' = {
  name: 'cosmosDB'
  params: {
    location: location
    cosmosAccounts: cosmosAccounts
    containersDB1: containersDB1
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgAI.name)
}
@description('Create Event Grid')
module eventGrid './modules/EventGrid.bicep' = {
  name: 'eventGrid'
  params: {
    location: location
    eventGridParams: eventGridParams
    isCodeDeployed: isCodeDeployed
    storageAccountId: storageAccount.outputs.storageAccounts_documentsaiblobstorage_name_resourceId
    HandleDocumentReceivedId: functionApp.outputs.functionDefinitionResourceIds[0]
    PushTranslationStatusId: functionApp.outputs.functionDefinitionResourceIds[1]
    ValidateExtractedDocumentDataId: functionApp.outputs.functionDefinitionResourceIds[2]
    WriteTranslationLogId: functionApp.outputs.functionDefinitionResourceIds[5]
    PureEventGridTriggerId: functionApp.outputs.functionDefinitionResourceIds[8]
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgAI.name)
  dependsOn:[
    functionApp
  ]
}
@description('Create Function App')
module functionApp './modules/Functions.bicep' = {
  name: 'functionApp'
  params: {
    location: location
    subnetSpoke6Id: existingSubnetSpoke6.id
    ElasticPlanId: appServicePlan.outputs.planIds[1]
    functionApps: functionApps
    webConfigs: webConfigs
    functions: functions
    isCodeDeployed: isCodeDeployed
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgAI.name)
}
@description('Create Network Security Group')
module networkSecurityGroup './modules/NetworkSecurityGroup.bicep' = {
  name: 'networkSecurityGroup'
  params: {
    location: location
    networkSecurityGroupName: networkSecurityGroupName
    securityRules: [
      {
        name: 'SSH'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '22'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 300
        direction: 'Inbound'
        sourcePortRanges: []
        destinationPortRanges: []
        sourceAddressPrefixes: []
        destinationAddressPrefixes: []
      }
    ]
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgNetworking.name)
}
@description('Create Public IP')
module publicIP './modules/PublicIP.bicep' = if(deployAgent) {
  name: 'publicIP'
  params: {
    location: location
    publicIpParams: publicIpParams
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgNetworking.name)
  dependsOn: [
    networkSecurityGroup
    keyVault
  ]
}

@description('Used to access to the kv for the VM password')
resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVault.outputs.keyvaultname
  scope: resourceGroup(rgCore.name)
}

@description('Create Virtual Machine')
module virtualMachine './modules/VirtualMachine.bicep' = if(deployAgent){
  name: 'virtualMachine'
  params: {
    environment: environment
    locationShort: locationShort
    location: location
    passsword: kv.getSecret('vm1AdminPassword')
    virtualMachineParams: virtualMachineParams
    PublicIpId: publicIP.outputs.publicIpResourceIds[0]
    subnetId: existingSubnetSpoke6.id
    dataDisk_list: dataDisks_list
  }
  scope: resourceGroup(rgDevOps.name)
}

@description('Create Private Endpoint')
module privateEndpoint './modules/PrivateEndpoint.bicep' = {
  name: 'privateEndpoint'
  params: {
    location: location
    subnetId: existingSubnetSpoke5.id
    privateEndpointsParams: privateEndpointsParams
    locationShort: locationShort
    environment: environment
  }
  scope: resourceGroup(rgNetworking.name)
  dependsOn: [
    storageAccount
    appServicePlan
    managedIdentity
    logAnalytics
    applicationInsights
    aiCognitiveServices
    containerRegistry
    eventGrid
    functionApp
    apiManagement
    keyVault
    aiWorkspace
    publicIP
    networkSecurityGroup
    cosmosDB
    actionGroup
    appService
    //  virtualMachine
  ]
}
