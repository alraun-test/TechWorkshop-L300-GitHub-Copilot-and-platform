targetScope = 'resourceGroup'

@description('Environment name (e.g. dev, staging, prod)')
param environmentName string

@description('Primary Azure region for resources')
param location string

@description('Docker image name')
param dockerImageName string = 'zavastorefront'

@description('Docker image tag')
param dockerImageTag string = 'latest'

// Resource token for unique naming
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)

// Resource names following az{prefix}{token} convention
var identityName = 'azid${resourceToken}'
var acrName = 'azacr${resourceToken}'
var appServicePlanName = 'azasp${resourceToken}'
var webAppName = 'azapp${resourceToken}'
var logAnalyticsName = 'azlog${resourceToken}'
var appInsightsName = 'azai${resourceToken}'
var aiServicesName = 'azais${resourceToken}'

var tags = {
  environment: environmentName
  project: 'zavastorefront'
}

// ── User-Assigned Managed Identity ──────────────────────────────────────────
module identity 'modules/identity.bicep' = {
  name: 'identity-deployment'
  params: {
    identityName: identityName
    location: location
    tags: tags
  }
}

// ── Azure Container Registry ────────────────────────────────────────────────
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    acrName: acrName
    location: location
    skuName: 'Basic'
    tags: tags
  }
}

// ── AcrPull Role Assignment (UAMI → ACR) ────────────────────────────────────
module acrPullRole 'modules/roleassignment.bicep' = {
  name: 'acrpull-role-deployment'
  params: {
    acrId: acr.outputs.acrId
    principalId: identity.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ── Application Insights + Log Analytics ────────────────────────────────────
module appInsights 'modules/appinsights.bicep' = {
  name: 'appinsights-deployment'
  params: {
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    location: location
    tags: tags
  }
}

// ── App Service (Web App for Containers) ────────────────────────────────────
module appService 'modules/appservice.bicep' = {
  name: 'appservice-deployment'
  params: {
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    location: location
    acrLoginServer: acr.outputs.acrLoginServer
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalyticsWorkspaceId
    identityId: identity.outputs.identityId
    identityClientId: identity.outputs.identityClientId
    dockerImageName: dockerImageName
    dockerImageTag: dockerImageTag
    skuName: 'B1'
    aiServicesEndpoint: aiServices.outputs.aiServicesEndpoint
    aiModelName: 'Phi-4'
    tags: union(tags, {
      'azd-service-name': 'web'
    })
  }
  dependsOn: [
    acrPullRole
  ]
}

// ── Azure AI Services (Microsoft Foundry) ───────────────────────────────────
module aiServices 'modules/ai.bicep' = {
  name: 'ai-services-deployment'
  params: {
    aiServicesName: aiServicesName
    location: location
    skuName: 'S0'
    tags: tags
  }
}

// ── Cognitive Services OpenAI User Role (App Service → AI Services) ─────────
module aiOpenAIRole 'modules/airoleassignment.bicep' = {
  name: 'ai-openai-role-deployment'
  params: {
    aiServicesId: aiServices.outputs.aiServicesId
    principalId: appService.outputs.webAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ── Outputs ─────────────────────────────────────────────────────────────────
output RESOURCE_GROUP_ID string = resourceGroup().id
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.acrLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.acrName
output WEB_APP_NAME string = appService.outputs.webAppName
output WEB_APP_HOSTNAME string = appService.outputs.webAppHostName
output APP_INSIGHTS_CONNECTION_STRING string = appInsights.outputs.appInsightsConnectionString
output AI_SERVICES_ENDPOINT string = aiServices.outputs.aiServicesEndpoint
