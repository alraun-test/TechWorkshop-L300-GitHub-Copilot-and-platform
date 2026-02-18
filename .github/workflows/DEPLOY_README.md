# Deploy Workflow Setup

This workflow builds the container image, pushes it to Azure Container Registry, and deploys it to the App Service defined in `infra/`.

## Prerequisites

1. **Deploy your infrastructure** first using the Bicep templates in `infra/`.
2. **Create a Microsoft Entra ID app registration** with federated credentials for GitHub Actions OIDC. The service principal needs:
   - `AcrPush` role on the ACR
   - `Contributor` role on the App Service (or the resource group)

### Create the federated credential

```bash
# Create an app registration
az ad app create --display-name "github-deploy"

# Create a service principal
az ad sp create --id <APP_ID>

# Add a federated credential for the main branch
az ad app federated-credential create --id <APP_ID> --parameters '{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<OWNER>/<REPO>:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Assign roles
az role assignment create --assignee <APP_ID> --role AcrPush --scope <ACR_RESOURCE_ID>
az role assignment create --assignee <APP_ID> --role Contributor --scope <RESOURCE_GROUP_ID>
```

## GitHub Secrets

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | App registration (client) ID |
| `AZURE_TENANT_ID` | Microsoft Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

## GitHub Variables

| Variable | Description | Example |
|---|---|---|
| `ACR_NAME` | ACR resource name (short name, not FQDN) | `azacrabc123` |
| `ACR_LOGIN_SERVER` | ACR login server | `azacrabc123.azurecr.io` |
| `AZURE_WEBAPP_NAME` | App Service name | `azappabc123` |

You can get these values from the Bicep deployment outputs:

```bash
az deployment group show -g <RESOURCE_GROUP> -n main --query properties.outputs
```
