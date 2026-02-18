# Deploy Workflow Setup

This workflow builds the container image, pushes it to Azure Container Registry, and deploys it to the App Service defined in `infra/`.

## Prerequisites

1. **Deploy your infrastructure** first using the Bicep templates in `infra/`.
2. **Create a Microsoft Entra ID app registration** with federated credentials for GitHub Actions OIDC. The service principal needs:
   - `AcrPush` role on the ACR
   - `Contributor` role on the App Service (or the resource group)

### Create the federated credential

`APP_ID` (also called the **Application (client) ID**) is a GUID that uniquely identifies the app registration in Microsoft Entra ID. You get it from the output of the first command below:

```bash
# Create an app registration and capture the APP_ID from the output
az ad app create --display-name "mgr-github-deploy" --query appId -o tsv
# ⬆ This prints the APP_ID (e.g. a1b2c3d4-e5f6-7890-abcd-ef1234567890)
# Save it:  APP_ID=<value printed above>

# Create a service principal for the app registration
# (The app must exist in your local tenant — which it does from the step above)
az ad sp create --id $APP_ID

# Add a federated credential for the main branch
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<OWNER>/<REPO>:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# Assign roles
az role assignment create --assignee $APP_ID --role AcrPush --scope <ACR_RESOURCE_ID>
az role assignment create --assignee $APP_ID --role Contributor --scope <RESOURCE_GROUP_ID>
```

> **Note:** The `APP_ID` value is the same value you set as the `AZURE_CLIENT_ID` GitHub secret.

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
