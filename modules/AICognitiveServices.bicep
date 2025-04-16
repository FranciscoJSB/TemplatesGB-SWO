// v2 - Conflict-avoiding version with explicit dependencies and role assignment handling

param location string
param TranslationServiceParams object
param OpenAIParams object
param DocumentIntelligenceParams object
param TextTranslationServiceParams object
param LanguageTranslationParam object

param modelDeployments array

param isInitialDeployment bool

// Outputs from other modules
param subnet5Id string
param subnet6Id string
param storageAccountId string

param environment string
param locationShort string

// Translation Service Account
resource TranslationAIServiceAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: '${TranslationServiceParams.name}-${environment}-${locationShort}'
  location: location
  sku: {
    name: TranslationServiceParams.sku.name
  }
  kind: TranslationServiceParams.kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: '${TranslationServiceParams.customSubDomainName}-${environment}-${locationShort}'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: TranslationServiceParams.publicNetworkAccess
  }
}

// OpenAI Cognitive Service Account
resource TranslationOpenAIAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: '${OpenAIParams.name}-${environment}-${locationShort}'
  location: location
  sku: {
    name: OpenAIParams.sku.name
  }
  kind: OpenAIParams.kind
  properties: {
    apiProperties: {}
    customSubDomainName: '${OpenAIParams.customSubDomainName}-${environment}-${locationShort}'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: OpenAIParams.publicNetworkAccess
  }
  dependsOn: [
    TranslationAIServiceAccount
  ]
}

// OpenAI Model Deployments
@batchSize(1)
resource cognitiveServicesDeploymentLoop 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [
  for deployment in modelDeployments: {
    parent: TranslationAIServiceAccount
    name: deployment.name
    sku: deployment.sku
    properties: {
      model: deployment.properties.model
      versionUpgradeOption: deployment.properties.versionUpgradeOption
    }
    dependsOn: [
      TranslationOpenAIAccount
    ]
  }
]

// Defender for AI Settings
resource translationAIServiceDefenderSettings 'Microsoft.CognitiveServices/accounts/defenderForAISettings@2024-10-01' = {
  parent: TranslationAIServiceAccount
  name: 'Default'
  properties: {
    state: 'Disabled'
  }
  dependsOn: [
    TranslationAIServiceAccount
  ]
}

// Document Intelligence (Form Recognizer)
resource translationCognitiveServiceAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: '${DocumentIntelligenceParams.name}-${environment}-${locationShort}'
  location: location
  sku: {
    name: DocumentIntelligenceParams.sku.name
  }
  kind: DocumentIntelligenceParams.kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: '${DocumentIntelligenceParams.customSubDomainName}-${environment}-${locationShort}'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: DocumentIntelligenceParams.publicNetworkAccess
  }
  dependsOn: [
    TranslationAIServiceAccount
  ]
}

// Text Translation Service Account (VNet restricted)
resource cognitive_services_account_aitr_dev_eus_aihub_open 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: '${TextTranslationServiceParams.name}-${environment}-${locationShort}'
  location: location
  sku: {
    name: TextTranslationServiceParams.sku.name
  }
  kind: TextTranslationServiceParams.kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: '${TextTranslationServiceParams.customSubDomainName}-${environment}-${locationShort}'
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnet5Id
          ignoreMissingVnetServiceEndpoint: false
        }
        {
          id: subnet6Id
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
      ipRules: []
    }
    publicNetworkAccess: TextTranslationServiceParams.publicNetworkAccess
  }
  dependsOn: [
    TranslationAIServiceAccount
  ]
}

resource cognitiveservicestranslation_existing 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: '${LanguageTranslationParam.name}-${environment}-${locationShort}'
}

// Medical Translation Cognitive Service (with user-owned storage)
resource cognitiveservicestranslation_dev_eus 'Microsoft.CognitiveServices/accounts@2024-10-01' = if (isInitialDeployment) {
  name: '${LanguageTranslationParam.name}-${environment}-${locationShort}'
  location: location
  sku: {
    name: LanguageTranslationParam.sku.name
  }
  kind: LanguageTranslationParam.kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    apiProperties: {}
    customSubDomainName: '${LanguageTranslationParam.customSubDomainName}-${environment}-${locationShort}'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    userOwnedStorage: [
      {
        resourceId: storageAccountId
      }
    ]
    publicNetworkAccess: LanguageTranslationParam.publicNetworkAccess
  }
  dependsOn: [
    TranslationAIServiceAccount
  ]
}

// // Role Assignment: Grant Storage Blob Data Reader to Translation Account
// resource blobDataReaderRoleAssignmentTranslation 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//   name: guid(storageAccountId, cognitiveservicestranslation_dev_eus.id, 'StorageBlobDataReader')
//   scope: storageAccountId
//   properties: {
//     principalId: cognitiveservicestranslation_dev_eus.identity.principalId
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1') // Storage Blob Data Reader
//     principalType: 'ServicePrincipal'
//   }
//   dependsOn: [
//     cognitiveservicestranslation_dev_eus
//   ]
// }

// Outputs
output accounts_ailg_dev_eus_medical_translation_name_resourceId string = cognitiveservicestranslation_dev_eus.id
output accounts_aitr_dev_eus_aihub_open_name_resourceId string = cognitive_services_account_aitr_dev_eus_aihub_open.id
output accounts_MedicalTranslation_AI_Services_name_resourceId string = TranslationAIServiceAccount.id
output accounts_MedicalTranslation_DocumentIntelligence_Service_name_resourceId string = translationCognitiveServiceAccount.id
output accounts_MedicalTranslation_OpenAI_Services_name_resourceId string = TranslationOpenAIAccount.id

// Output: Endpoint for the core Translation Service
output translationServiceEndpoint string = TranslationAIServiceAccount.properties.endpoint
// Output: Endpoint for OpenAI
output openAIServiceEndpoint string = TranslationOpenAIAccount.properties.endpoint
// Output: Endpoint for Document Intelligence
output documentIntelligenceEndpoint string = translationCognitiveServiceAccount.properties.endpoint
// Output: Endpoint for VNet-restricted Text Translation
output textTranslationEndpoint string = cognitive_services_account_aitr_dev_eus_aihub_open.properties.endpoint
// Output: Endpoint for Medical Translation (if deployed)
output medicalTranslationEndpoint string = isInitialDeployment
  ? cognitiveservicestranslation_dev_eus.properties.endpoint
  : cognitiveservicestranslation_existing.properties.endpoint

