@description('Name of the App Service Plan')
param appServicePlanName string

@description('Name of the Web App')
param webAppName string

@description('Azure region for resources')
param location string

@description('ACR login server URL')
param acrLoginServer string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('User-Assigned Managed Identity resource ID')
param identityId string

@description('User-Assigned Managed Identity client ID')
param identityClientId string

@description('Docker image name (without registry)')
param dockerImageName string = 'zavastorefront'

@description('Docker image tag')
param dockerImageTag string = 'latest'

@description('App Service Plan SKU name')
param skuName string = 'B1'

@description('Log Analytics workspace resource ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Azure AI Services endpoint')
param aiServicesEndpoint string

@description('AI model deployment name')
param aiModelName string = 'Phi-4'

@description('Tags for the resources')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: identityClientId
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${dockerImageName}:${dockerImageTag}'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'AzureAI__Endpoint'
          value: aiServicesEndpoint
        }
        {
          name: 'AzureAI__ModelName'
          value: aiModelName
        }
        {
          name: 'AzureAI__ApiKey'
          value: ''
        }
      ]
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
    }
    httpsOnly: true
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webAppName}-diagnostics'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output webAppId string = webApp.id
output webAppName string = webApp.name
output webAppHostName string = webApp.properties.defaultHostName
output webAppPrincipalId string = webApp.identity.principalId
