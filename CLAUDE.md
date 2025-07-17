# CLAUDE.md - Simple Azure Function App with IaC

This file provides guidance to Claude Code (claude.ai/code) when working with this Infrastructure as Code (IaC) iteration of the simple Azure Function App project.

## Project Overview

This is the second iteration of the simple Azure Function App project, building on the successful [exemplar project](https://github.com/MrBenA/simple-azure-function-app). It adds Infrastructure as Code (IaC) capabilities using Bicep templates while maintaining the exact same working configuration that was proven successful.

**Key Design Principles:**
- **Build on Success**: Use the exact same function code and configuration that worked
- **Infrastructure as Code**: Automate infrastructure deployment with Bicep
- **Incremental Complexity**: Add IaC without changing what works
- **Basic Authentication**: Continue using storage account keys (not managed identity yet)
- **Automated Deployment**: GitHub Actions for both infrastructure and application

## Project Evolution

### From Exemplar Project → IaC Project

| Component | Exemplar Project | IaC Project |
|-----------|------------------|-------------|
| **Function Code** | ✅ Same working code | ✅ Same working code |
| **Infrastructure** | Manual portal creation | ✅ Automated Bicep templates |
| **Deployment** | Portal GitHub integration | ✅ GitHub Actions workflows |
| **Authentication** | Basic (storage keys) | ✅ Basic (storage keys) |
| **Configuration** | Manual app settings | ✅ Bicep-managed app settings |
| **Repeatability** | Manual steps required | ✅ Fully automated |

## Project Structure

```
simple-function-app-iac/
├── src/                    # Function code (copied from exemplar)
│   ├── function_app.py     # Three working functions
│   ├── host.json          # Function host configuration
│   └── requirements.txt   # Python dependencies
├── infra/                 # Infrastructure as Code
│   ├── main.bicep         # Main Bicep template
│   └── main.bicepparam    # Parameters file
├── .github/workflows/     # GitHub Actions
│   ├── deploy-infra.yml   # Infrastructure deployment
│   └── deploy-app.yml     # Application deployment
├── CLAUDE.md             # This file - Claude Code guidance
└── README.md            # Project documentation
```

## Infrastructure Architecture

### Resources Created by Bicep

1. **Storage Account** (`Microsoft.Storage/storageAccounts`):
   - Standard LRS storage
   - HTTPS only, TLS 1.2 minimum
   - Used for function app storage with basic authentication

2. **Application Insights** (`Microsoft.Insights/components`):
   - Web application type
   - Monitoring and logging for function app

3. **Hosting Plan** (`Microsoft.Web/serverfarms`):
   - Consumption plan (Y1/Dynamic)
   - Linux reserved for Python runtime

4. **Function App** (`Microsoft.Web/sites`):
   - Linux function app
   - Python 3.11 runtime
   - Configured with all necessary app settings

### Key Configuration Settings

The Bicep template sets these critical app settings:

```bicep
appSettings: [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};...'
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'python'
  }
  {
    name: 'PYTHON_ENABLE_WORKER_EXTENSIONS'
    value: '1'
  }
  // ... other settings
]
```

## Deployment Workflows

### 1. Infrastructure Deployment (`deploy-infra.yml`)

**Triggers:**
- Manual workflow dispatch
- Push to `infra/` folder

**Steps:**
1. Checkout code
2. Azure login using service principal
3. Create resource group
4. Deploy Bicep template
5. Output function app name

### 2. Application Deployment (`deploy-app.yml`)

**Triggers:**
- Manual workflow dispatch
- Push to `src/` folder

**Steps:**
1. Checkout code
2. Setup Python 3.11
3. Install dependencies
4. Azure login
5. Deploy function code using Azure Functions Action

## Setup Instructions

### Prerequisites

1. **Azure Subscription** with permission to create resources
2. **GitHub Repository** for the project
3. **Azure Service Principal** for GitHub Actions authentication

### 1. Create Azure Service Principal

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "simple-func-iac-github" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth

# Copy the JSON output for GitHub secret
```

### 2. Configure GitHub Secrets

Add this secret to your GitHub repository:

**Name**: `AZURE_CREDENTIALS`
**Value**: JSON output from service principal creation

### 3. Customize Parameters

Edit `infra/main.bicepparam` to customize:

- `functionAppName`: Your function app name
- `storageAccountName`: Storage account name (must be globally unique)
- `appInsightsName`: Application Insights name
- `hostingPlanName`: Hosting plan name

### 4. Deploy Infrastructure

1. Push changes to `infra/` folder OR
2. Go to GitHub Actions → "Deploy Infrastructure" → "Run workflow"
3. Wait for deployment to complete
4. Check Azure Portal for created resources

### 5. Deploy Application

1. Push changes to `src/` folder OR
2. Go to GitHub Actions → "Deploy Function App" → "Run workflow"
3. Wait for deployment to complete
4. Test endpoints

## Testing and Validation

### Function Endpoints

After successful deployment, test these endpoints:

1. **Health Check**: `https://your-function-app.azurewebsites.net/api/health`
   - Expected: JSON with status, timestamp, version

2. **Test Endpoint**: `https://your-function-app.azurewebsites.net/api/test`
   - Expected: "Hello from Azure Functions! This is a simple test endpoint."

3. **Hello Endpoint**: `https://your-function-app.azurewebsites.net/api/hello?name=Test`
   - Expected: "Hello, Test! Welcome to Azure Functions."

### Validation Commands

```bash
# Check function registration
az functionapp function list \
  --resource-group rg-simple-func-iac \
  --name simple-func-iac-ba

# Test endpoints
curl https://your-function-app.azurewebsites.net/api/health
curl https://your-function-app.azurewebsites.net/api/test
curl "https://your-function-app.azurewebsites.net/api/hello?name=Test"
```

## Troubleshooting

### Common Issues

**1. Deployment Fails - Resource Names**
- **Cause**: Resource names must be globally unique
- **Solution**: Update storage account name in parameters file

**2. Function App Not Found**
- **Cause**: Infrastructure deployment failed
- **Solution**: Check GitHub Actions logs for infrastructure workflow

**3. Functions Not Registered**
- **Cause**: Application deployment failed or configuration issue
- **Solution**: Check GitHub Actions logs for app deployment workflow

**4. Authentication Errors**
- **Cause**: Service principal permissions or expired credentials
- **Solution**: Verify AZURE_CREDENTIALS secret and permissions

### Debugging Steps

1. **Check GitHub Actions Logs**:
   - Go to Actions tab in repository
   - Click on failed workflow
   - Review detailed logs

2. **Check Azure Portal**:
   - Verify resource group exists
   - Check function app configuration
   - Review Application Insights logs

3. **Validate Bicep Template**:
   ```bash
   az deployment group validate \
     --resource-group rg-simple-func-iac \
     --template-file infra/main.bicep \
     --parameters infra/main.bicepparam
   ```

## Development Guidelines

### Making Changes

**Infrastructure Changes:**
1. Edit Bicep templates in `infra/`
2. Test locally with `az deployment group validate`
3. Push to trigger infrastructure deployment
4. Verify changes in Azure Portal

**Function Code Changes:**
1. Edit code in `src/`
2. Test locally with `func start`
3. Push to trigger application deployment
4. Test endpoints

### Best Practices

1. **Test Infrastructure Changes**: Always validate Bicep templates before deploying
2. **Use Parameters**: Don't hardcode values in Bicep templates
3. **Monitor Deployments**: Check GitHub Actions logs for all deployments
4. **Incremental Changes**: Make small, focused changes
5. **Version Control**: Tag successful deployments

## Comparison with Original Complex Project

### What We Learned

| Issue | Original Complex Project | This IaC Project |
|-------|-------------------------|------------------|
| **Managed Identity** | ❌ Complex setup, failed | ✅ Avoided (using basic auth) |
| **Role Assignments** | ❌ Over-engineered | ✅ Simple service principal |
| **Bicep Complexity** | ❌ Too many resources | ✅ Focused on essentials |
| **Deployment** | ❌ Custom complex workflows | ✅ Simple, focused workflows |
| **Function Registration** | ❌ Functions not detected | ✅ Should work (same as exemplar) |

### Success Factors

1. **Started with Working Code**: Copied exact function code from exemplar
2. **Basic Authentication**: Used storage account keys (reliable)
3. **Simple Bicep**: Only essential resources
4. **Proven Patterns**: Based on successful exemplar project
5. **Incremental Approach**: Added IaC without changing what works

## Next Steps

After this IaC version is working, future iterations can add:

1. **Managed Identity**: Replace storage account keys with managed identity
2. **Multiple Environments**: Add dev/staging/prod environments
3. **Advanced Monitoring**: Enhanced Application Insights configuration
4. **Security**: Network restrictions, key vault integration
5. **Database Integration**: Add database connections
6. **API Authentication**: Add proper API authentication

## Success Criteria

This project is considered successful when:

- ✅ Infrastructure deploys via GitHub Actions
- ✅ Function app is created with correct configuration
- ✅ Application deploys via GitHub Actions
- ✅ All three endpoints return expected responses
- ✅ Configuration matches working exemplar project

## Support and Maintenance

- **Primary Focus**: Prove IaC deployment of working configuration
- **Approach**: Build incrementally on proven patterns
- **Documentation**: Keep this file updated with deployment results
- **Next Iteration**: Add managed identity after this works

---

**Last Updated**: 2025-07-17
**Status**: In Development
**Next Steps**: Create GitHub repository and test deployment workflows