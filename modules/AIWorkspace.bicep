param location string

param WorkspacesParams object

@secure()
param password string

//outputs from other modules
param storageAccounts_documentsaiblobstorage_name_resourceId string
param keyvaultID string
param accounts_MedicalTranslation_AI_Services_name_resourceId string
param insightsId string

param translationServiceEndpoint string
param openAIEndpoint string
param documentIntelligenceEndpoint string
param textTranslationServiceEndpoint string
param medicalTranslationEndpoint string

param environment string
param locationShort string

var optionalManagedNetwork = (location == 'centralus' || location == 'westus3')
  ? {
      isolationMode: 'AllowInternetOutbound'
      outboundRules: {
        __SYS_PE_documentsaiblobstorage_blob_9fe114ba: {
          type: 'PrivateEndpoint'
          destination: {
            serviceResourceId: storageAccounts_documentsaiblobstorage_name_resourceId
            subresourceTarget: 'blob'
            sparkEnabled: true
            sparkStatus: 'Active'
          }
          status: 'Active'
          category: 'Required'
        }
        __SYS_PE_documentsaiblobstorage_file_9fe114ba: {
          type: 'PrivateEndpoint'
          destination: {
            serviceResourceId: storageAccounts_documentsaiblobstorage_name_resourceId
            subresourceTarget: 'file'
            sparkEnabled: true
            sparkStatus: 'Active'
          }
          status: 'Active'
          category: 'Required'
        }
        '__SYS_PE_ai-hub-medicaltranslation_amlworkspace_9fe114ba': {
          type: 'PrivateEndpoint'
          destination: {
            subresourceTarget: 'amlworkspace'
            sparkEnabled: true
            sparkStatus: 'Active'
          }
          status: 'Active'
          category: 'Required'
        }
      }
      status: {
        status: 'Active'
        sparkReady: false
      }
    }
  : {}

resource workspaces_ai_hub_medicaltranslation_name_resource 'Microsoft.MachineLearningServices/workspaces@2025-01-01-preview' = if (location == 'centralus' || location == 'westus3') {
  name: '${WorkspacesParams.name}-${environment}-${locationShort}'
  location: location
  sku: {
    name: WorkspacesParams.sku.name
    tier: WorkspacesParams.sku.tier
  }
  kind: WorkspacesParams.kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: WorkspacesParams.friendlyName
    storageAccount: storageAccounts_documentsaiblobstorage_name_resourceId
    keyVault: keyvaultID
    applicationInsights: insightsId
    hbiWorkspace: false
    managedNetwork: optionalManagedNetwork
    allowRoleAssignmentOnRG: WorkspacesParams.allowRoleAssignment
    v1LegacyMode: false
    publicNetworkAccess: WorkspacesParams.publicNetworkAccess
    ipAllowlist: []
    enableSoftwareBillOfMaterials: false
    workspaceHubConfig: {
      defaultWorkspaceResourceGroup: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}'
    }
    enableDataIsolation: true
    systemDatastoresAuthMode: 'identity'
    enableServiceSideCMKEncryption: false
    provisionNetworkNow: true
  }
}

resource workspaces_ai_hub_medicaltranslation_name_resource_eus2 'Microsoft.MachineLearningServices/workspaces@2025-01-01-preview' = if (location != 'centralus' && location != 'westus3') {
  name: '${WorkspacesParams.name}-${environment}-${locationShort}'
  location: location
  sku: {
    name: WorkspacesParams.sku.name
    tier: WorkspacesParams.sku.tier
  }
  kind: WorkspacesParams.kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: WorkspacesParams.friendlyName
    storageAccount: storageAccounts_documentsaiblobstorage_name_resourceId
    keyVault: keyvaultID
    applicationInsights: insightsId
    hbiWorkspace: false
    allowRoleAssignmentOnRG: WorkspacesParams.allowRoleAssignment
    v1LegacyMode: false
    publicNetworkAccess: WorkspacesParams.publicNetworkAccess
    ipAllowlist: []
    enableSoftwareBillOfMaterials: false
    workspaceHubConfig: {
      defaultWorkspaceResourceGroup: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}'
    }
    enableDataIsolation: true
    systemDatastoresAuthMode: 'identity'
    enableServiceSideCMKEncryption: false
  }
}

resource workspaces_ai_hub_medicaltranslation_name_HubAgents 'Microsoft.MachineLearningServices/workspaces/capabilityHosts@2025-01-01-preview' = if (location == 'centralus' || location == 'westus3') {
  parent: workspaces_ai_hub_medicaltranslation_name_resource
  name: 'HubAgents'
  properties: {
    capabilityHostKind: 'Agents'
  }
}

resource workspaces_ai_hub_medicaltranslation_name_HubAgents_eus2 'Microsoft.MachineLearningServices/workspaces/capabilityHosts@2025-01-01-preview' = if (location != 'centralus' && location != 'westus3') {
  parent: workspaces_ai_hub_medicaltranslation_name_resource_eus2
  name: 'HubAgents'
  properties: {
    capabilityHostKind: 'Agents'
  }
}

resource workspaces_ai_hub_medicaltranslation_name_MedicalTranslationAIServices 'Microsoft.MachineLearningServices/workspaces/connections@2025-01-01-preview' = if (location == 'centralus' || location == 'westus3') {
  parent: workspaces_ai_hub_medicaltranslation_name_resource
  name: 'MedicalTranslationAIServices'
  properties: {
    authType: 'ApiKey'
    credentials: { key: password }
    category: 'AIServices'
    target: medicalTranslationEndpoint
    useWorkspaceManagedIdentity: true
    isSharedToAll: true
    sharedUserList: []
    peRequirement: 'Required'
    peStatus: 'Inactive'
    metadata: {
      ApiType: 'Azure'
      ResourceId: accounts_MedicalTranslation_AI_Services_name_resourceId
      Location: location
      ApiVersion: '2023-07-01-preview'
      DeploymentApiVersion: '2023-10-01-preview'
    }
  }
}

resource workspaces_ai_hub_medicaltranslation_name_MedicalTranslationAIServices_eus2 'Microsoft.MachineLearningServices/workspaces/connections@2025-01-01-preview' = if (location != 'centralus' && location != 'westus3') {
  parent: workspaces_ai_hub_medicaltranslation_name_resource_eus2
  name: 'MedicalTranslationAIServices'
  properties: {
    authType: 'ApiKey'
    credentials: { key: password }
    category: 'AIServices'
    target: medicalTranslationEndpoint
    useWorkspaceManagedIdentity: true
    isSharedToAll: true
    sharedUserList: []
    peRequirement: 'Required'
    peStatus: 'Inactive'
    metadata: {
      ApiType: 'Azure'
      ResourceId: accounts_MedicalTranslation_AI_Services_name_resourceId
      Location: location
      ApiVersion: '2023-07-01-preview'
      DeploymentApiVersion: '2023-10-01-preview'
    }
  }
}

resource workspaces_ai_hub_medicaltranslation_name_MedicalTranslationAIServices_aoai 'Microsoft.MachineLearningServices/workspaces/connections@2025-01-01-preview' = if (location == 'centralus' || location == 'westus3') {
  parent: workspaces_ai_hub_medicaltranslation_name_resource
  name: 'MedicalTranslationAIServices_aoai'
  properties: {
    authType: 'ApiKey'
    credentials: { key: password }
    category: 'AzureOpenAI'
    target: openAIEndpoint
    useWorkspaceManagedIdentity: true
    isSharedToAll: true
    sharedUserList: []
    peRequirement: 'Required'
    peStatus: 'Inactive'
    metadata: {
      ApiType: 'Azure'
      ResourceId: accounts_MedicalTranslation_AI_Services_name_resourceId
      Location: location
      ApiVersion: '2023-07-01-preview'
      DeploymentApiVersion: '2023-10-01-preview'
    }
  }
}

resource workspaces_ai_hub_medicaltranslation_name_MedicalTranslationAIServices_aoai_eus2 'Microsoft.MachineLearningServices/workspaces/connections@2025-01-01-preview' = if (location != 'centralus' && location != 'westus3') {
  parent: workspaces_ai_hub_medicaltranslation_name_resource_eus2
  name: 'MedicalTranslationAIServices_aoai'
  properties: {
    authType: 'ApiKey'
    credentials: { key: password }
    category: 'AzureOpenAI'
    target: openAIEndpoint
    useWorkspaceManagedIdentity: true
    isSharedToAll: true
    sharedUserList: []
    peRequirement: 'Required'
    peStatus: 'Inactive'
    metadata: {
      ApiType: 'Azure'
      ResourceId: accounts_MedicalTranslation_AI_Services_name_resourceId
      Location: location
      ApiVersion: '2023-07-01-preview'
      DeploymentApiVersion: '2023-10-01-preview'
    }
  }
}

output workspaces_ai_hub_medicaltranslation_name_resourceId string = workspaces_ai_hub_medicaltranslation_name_resource.id

