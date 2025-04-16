param actionGroupName object
param armRoleReceivers array
param locationShort string
param environment string

resource actionGroupResource 'microsoft.insights/actionGroups@2024-10-01-preview' = {
  name: '${actionGroupName.name}-${environment}-${locationShort}'
  location: 'Global'
  properties: {
    groupShortName: actionGroupName.groupShortName
    enabled: true
    armRoleReceivers: armRoleReceivers
  }
}
