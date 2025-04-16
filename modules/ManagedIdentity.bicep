param ManagedIdentityName string
param location string
param environment string
param locationShort string

resource userAssignedIdentityResource 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: '${ManagedIdentityName}-${environment}-${locationShort}'
  location: location
}

output managedIdentityId string = userAssignedIdentityResource.id
