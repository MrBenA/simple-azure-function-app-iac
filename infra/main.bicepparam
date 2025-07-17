using 'main.bicep'

// Parameters for the simple function app IaC deployment
param functionAppName = 'simple-func-iac-ba'
param storageAccountName = 'simplefunciacba${uniqueString(resourceGroup().id)}'
param appInsightsName = 'simple-func-iac-ba-insights'
param hostingPlanName = 'simple-func-iac-ba-plan'