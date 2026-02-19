@description('Name of the Azure AI Services account')
param aiServicesName string

@description('Azure region for resources')
param location string

@description('SKU for the AI Services account')
param skuName string = 'S0'

@description('Tags for the resources')
param tags object = {}

@description('GPT-4 model deployment name')
param gpt4DeploymentName string = 'gpt-4'

@description('Phi model deployment name')
param phiDeploymentName string = 'phi-4'

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: gpt4DeploymentName
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: phiDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-4-mini-instruct'
      version: '1'
    }
  }
  dependsOn: [
    gpt4Deployment
  ]
}

output aiServicesId string = aiServices.id
output aiServicesName string = aiServices.name
output aiServicesEndpoint string = aiServices.properties.endpoint
