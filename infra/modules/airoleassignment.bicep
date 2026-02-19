@description('Azure AI Services resource ID')
param aiServicesId string

@description('Principal ID to assign the Cognitive Services OpenAI User role to')
param principalId string

@description('Principal type')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
  'ForeignGroup'
])
param principalType string = 'ServicePrincipal'

// Cognitive Services OpenAI User built-in role definition ID
var cognitiveServicesOpenAIUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: last(split(aiServicesId, '/'))
}

resource openAIUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiServicesId, principalId, cognitiveServicesOpenAIUserRoleId)
  scope: aiServices
  properties: {
    roleDefinitionId: cognitiveServicesOpenAIUserRoleId
    principalId: principalId
    principalType: principalType
  }
}
