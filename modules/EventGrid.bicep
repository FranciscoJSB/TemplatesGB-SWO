param eventGridParams object
param location string

param storageAccountId string
param HandleDocumentReceivedId string
param PushTranslationStatusId string
param ValidateExtractedDocumentDataId string
param WriteTranslationLogId string
param PureEventGridTriggerId string

param isCodeDeployed bool

param environment string
param locationShort string

// Event Grid Topic for Document Processing
resource eventGridTopic 'Microsoft.EventGrid/topics@2025-02-15' = {
  name: '${eventGridParams.name}-${environment}-${locationShort}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    inputSchema: eventGridParams.inputSchema
    publicNetworkAccess: eventGridParams.publicNetworkAccess
  }
}

resource eventSubscriptionHandleTopic 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = if (isCodeDeployed){
  parent: eventGridTopic
  name: 'HandleDocumentReceived'
  properties: {
    destination: {
      properties: {
        resourceId: HandleDocumentReceivedId
      }
      endpointType: 'AzureFunction'
    }
    filter: {
      includedEventTypes: [
        'MedicalTranslation.HandleDocumentReceived'
      ]
    }
  }
}

resource eventGridTopicompleted 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = if (isCodeDeployed) {
  parent: eventGridTopic
  name: 'ProcessingComplete'
  properties: {
    destination: {
      properties: {
        resourceId: PushTranslationStatusId
      }
      endpointType: 'AzureFunction'
    }
    filter: {
      includedEventTypes: [
        'MedicalTranslation.ProcessingCompleted'
      ]
    }
  }
}

// Event Grid System Topic for Document Processing
resource eventGridDocumentProcessingTopic 'Microsoft.EventGrid/systemTopics@2025-02-15' = if (isCodeDeployed) {
  name: eventGridParams.name
  location: location
  properties: {
    source: storageAccountId
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

resource eventGrid_documentExtracted_subscriber 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = if (isCodeDeployed) {
  parent: eventGridTopic
  name: 'DocumentExtracted'
  properties: {
    destination: {
      properties: {
        resourceId: ValidateExtractedDocumentDataId
      }
      endpointType: 'AzureFunction'
    }
    filter: {
      includedEventTypes: [
        'MedicalTranslation.DocumentExtracted'
      ]
    }
    deadLetterDestination: {
      properties: {
        resourceId: storageAccountId
        blobContainerName: 'eventgrid-dead-letter-container'
      }
      endpointType: 'StorageBlob'
    }
  }
}

resource eventGrid_topics_document_translation_WriteLog 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = if (isCodeDeployed){
  parent: eventGridTopic
  name: 'WriteTranslationLog'
  properties: {
    destination: {
      properties: {
        resourceId: WriteTranslationLogId
      }
      endpointType: 'AzureFunction'
    }
    filter: {
      includedEventTypes: [
        'MedicalTranslation.SaveTranslationLog'
      ]
    }
    deadLetterDestination: {
      properties: {
        resourceId: storageAccountId
        blobContainerName: 'eventgrid-dead-letter-container'
      }
      endpointType: 'StorageBlob'
    }
  }
}

resource eventGrid_blobCreated_trigger_documentProcessing 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2025-02-15' = if (isCodeDeployed){
  parent: eventGridDocumentProcessingTopic
  name: 'blobCreated-BlobTriggerWithEventGrid'
  properties: {
    destination: {
      properties: {
        resourceId: PureEventGridTriggerId
      }
      endpointType: 'AzureFunction'
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
    }
  }
}

output eventGridDocumentProcessingId string = eventGridTopic.id
