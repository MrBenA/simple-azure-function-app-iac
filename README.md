# Simple Azure Function App with IaC

This is the next iteration of the simple Azure Function App, now with Infrastructure as Code (IaC) using Bicep templates. This project builds on the successful [exemplar project](https://github.com/MrBenA/simple-azure-function-app) and adds infrastructure automation while maintaining the same working configuration.

## Features

- **Same Working Functions**: Health check, test, and hello endpoints
- **Infrastructure as Code**: Bicep templates for automatic deployment
- **Basic Authentication**: Using storage account keys (simple and reliable)
- **GitHub Actions**: Automated deployment workflows
- **Consumption Plan**: Cost-effective serverless hosting

## Project Structure

```
simple-function-app-iac/
├── src/                    # Function code (copied from exemplar)
│   ├── function_app.py     # Main function definitions
│   ├── host.json          # Function host configuration
│   └── requirements.txt   # Python dependencies
├── infra/                 # Infrastructure as Code
│   ├── main.bicep         # Main Bicep template
│   └── main.bicepparam    # Parameters file
├── .github/workflows/     # GitHub Actions
│   ├── deploy-infra.yml   # Infrastructure deployment
│   └── deploy-app.yml     # Application deployment
├── CLAUDE.md             # Claude Code guidance
└── README.md            # This file
```

## Deployment

### Prerequisites

1. **Azure Subscription** with appropriate permissions
2. **GitHub Repository** with secrets configured
3. **Azure CLI** (for local development)

### Setup GitHub Secrets

Add the following secret to your GitHub repository:

```
AZURE_CREDENTIALS = {
  "clientId": "your-service-principal-client-id",
  "clientSecret": "your-service-principal-client-secret",
  "subscriptionId": "your-azure-subscription-id",
  "tenantId": "your-azure-tenant-id"
}
```

### Deployment Steps

1. **Deploy Infrastructure**:
   - Push changes to `infra/` folder OR
   - Manually trigger "Deploy Infrastructure" workflow
   - Creates resource group and all Azure resources

2. **Deploy Application**:
   - Push changes to `src/` folder OR
   - Manually trigger "Deploy Function App" workflow
   - Deploys function code to the infrastructure

### Testing

Once deployed, test the endpoints:

- **Health**: `https://your-function-app.azurewebsites.net/api/health`
- **Test**: `https://your-function-app.azurewebsites.net/api/test`
- **Hello**: `https://your-function-app.azurewebsites.net/api/hello?name=YourName`

## Configuration

The infrastructure creates:

- **Function App**: `simple-func-iac-ba` (Python 3.11, Consumption plan)
- **Storage Account**: For function app storage (basic authentication)
- **Application Insights**: For monitoring and logging
- **Hosting Plan**: Consumption (Dynamic) plan

## Development

### Local Development

```bash
# Navigate to src directory
cd src

# Install dependencies
pip install -r requirements.txt

# Run locally (requires Azure Functions Core Tools)
func start
```

### Adding New Functions

1. Edit `src/function_app.py` to add new functions
2. Follow the existing pattern with `@app.route()` decorators
3. Test locally before pushing to GitHub

## Comparison with Exemplar Project

| Aspect | Exemplar Project | This IaC Project |
|--------|------------------|------------------|
| **Infrastructure Creation** | Manual (Azure Portal) | Automated (Bicep) |
| **Deployment** | Portal GitHub integration | GitHub Actions |
| **Configuration** | Same working config | Same working config |
| **Complexity** | Minimal | Slightly more (IaC) |
| **Repeatability** | Manual steps | Fully automated |

## Documentation

See [CLAUDE.md](CLAUDE.md) for comprehensive guidance, troubleshooting, and development instructions.

## Next Steps

This project serves as a foundation for adding more advanced features:

- Managed Identity (next iteration)
- Advanced monitoring and alerts
- Multiple environments (dev/staging/prod)
- Database integration
- API authentication and authorization

## Support

This project builds incrementally on proven patterns. Start with the [exemplar project](https://github.com/MrBenA/simple-azure-function-app) to understand the basics, then use this IaC version for automated deployments.