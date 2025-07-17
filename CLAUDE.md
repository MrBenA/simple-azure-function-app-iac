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

## Next Steps - Iteration Checklist

### Planned Iteration Roadmap

**✅ Iteration 1: Simple Function App (Exemplar)**
- Status: COMPLETED
- Repository: https://github.com/MrBenA/simple-azure-function-app
- Features: Basic 3-function app, manual portal deployment, basic auth

**✅ Iteration 2: Infrastructure as Code (Current)**
- Status: COMPLETED  
- Repository: https://github.com/MrBenA/simple-azure-function-app-iac
- Features: Same functions + Bicep templates + GitHub Actions automation

**📋 Iteration 3: Complex Function App**
- Status: PENDING
- Goal: Add more sophisticated function capabilities while maintaining IaC
- Planned Features:
  - Multiple function types (HTTP, Timer, Queue triggers)
  - Function chaining and workflow patterns
  - Input/output bindings to Azure services
  - Error handling and retry policies
  - More complex business logic
  - Enhanced monitoring and logging
  - Environment-specific configurations

**📋 Iteration 4: Managed Identity**
- Status: PENDING
- Goal: Replace basic authentication with managed identity
- Planned Features:
  - User-assigned managed identity (UAMI)
  - Role-based access control (RBAC)
  - Key Vault integration for secrets
  - Secure storage account access
  - Service-to-service authentication
  - Enhanced security posture

### Future Iterations (Post-Managed Identity)

5. **Multiple Environments**: Add dev/staging/prod environments
6. **Advanced Monitoring**: Enhanced Application Insights configuration
7. **Security**: Network restrictions, private endpoints
8. **Database Integration**: Add database connections
9. **API Authentication**: Add proper API authentication
10. **Performance Optimization**: Scaling, caching, optimization patterns

## Success Criteria

This project is considered successful when:

- ✅ Infrastructure deploys via GitHub Actions (Manual ✅, GitHub Actions ✅)
- ✅ Function app is created with correct configuration
- ✅ Application deploys via GitHub Actions (Manual ✅, GitHub Actions ✅)
- ✅ All three endpoints return expected responses
- ✅ Configuration matches working exemplar project

**Current Status**: ✅ **FULLY SUCCESSFUL** - All criteria met with both manual and automated deployments

## Deployment Results

### Manual Deployment Success ⚠️

**Deployment Method**: Manual Azure CLI (NOT GitHub Actions)
**Deployment Date**: 2025-07-17
**Status**: ✅ **SUCCESSFUL**

**Resources Created**:
- **Function App**: `simple-func-iac-ba`
- **Storage Account**: `sfiacbalhbicnagrsmhk` (23 chars, valid)
- **Application Insights**: `simple-func-iac-ba-insights`
- **Hosting Plan**: `simple-func-iac-ba-plan`

**Function App URL**: https://simple-func-iac-ba.azurewebsites.net

**Functions Registered**:
- ✅ `health` - [httpTrigger] - ANONYMOUS
- ✅ `hello` - [httpTrigger] - ANONYMOUS  
- ✅ `test` - [httpTrigger] - ANONYMOUS

### GitHub Actions Workflows Status

**✅ BOTH WORKFLOWS SUCCESSFULLY TESTED**

**Infrastructure Workflow** (`deploy-infra.yml`):
- **Status**: ✅ **SUCCESSFUL**
- **Run ID**: 16353237974
- **Duration**: 3m29s
- **Configuration**: Azure CLI 2.72.0 and fixed storage account naming
- **Result**: All 4 resources created successfully

**Application Workflow** (`deploy-app.yml`):
- **Status**: ✅ **SUCCESSFUL**
- **Run ID**: 16353327595
- **Duration**: 1m23s
- **Configuration**: Standard Azure Functions Action deployment
- **Result**: All 3 functions deployed and registered

### Endpoint Testing Results

**All endpoints tested and working perfectly after GitHub Actions deployment**:

1. **Health Endpoint**: ✅ `https://simple-func-iac-ba.azurewebsites.net/api/health`
   - **Response**: `{"status": "healthy", "timestamp": "2025-07-17T18:47:38.507298", "version": "1.0.0"}`

2. **Test Endpoint**: ✅ `https://simple-func-iac-ba.azurewebsites.net/api/test`
   - **Response**: `"Hello from Azure Functions! This is a simple test endpoint."`

3. **Hello Endpoint**: ✅ `https://simple-func-iac-ba.azurewebsites.net/api/hello?name=GitHub-Actions`
   - **Response**: `"Hello, GitHub-Actions! Welcome to Azure Functions."`

**Function Registration Verification**: ✅ All 3 functions properly registered

### Key Fixes Applied

1. **Storage Account Naming**: Fixed name length issue by shortening `simplefunciacba` → `sfiacba`
2. **Azure CLI Version**: Used Azure CLI 2.72.0 to avoid "content consumed" bug
3. **Parameter Consistency**: Ensured all parameters match between workflows and templates

## Support and Maintenance

- **Primary Focus**: Prove IaC deployment of working configuration
- **Approach**: Build incrementally on proven patterns
- **Documentation**: Keep this file updated with deployment results
- **Next Iteration**: Add managed identity after this works

---

**Last Updated**: 2025-07-17
**Status**: ✅ **FULLY COMPLETED - BOTH MANUAL AND GITHUB ACTIONS SUCCESSFUL**
**Next Steps**: 
1. ✅ Create GitHub repository 
2. ✅ Configure `AZURE_CREDENTIALS` secret
3. ✅ Test both GitHub Actions workflows
4. ✅ Project fully complete - ready for Iteration 3 (Complex Function App)

**Iteration Roadmap**: This project serves as the foundation for systematic progression through increasingly complex Azure Function patterns, with each iteration building on the previous success.