param prefix string = 'cwc-ga'
param location string = resourceGroup().location


// Also take an object as an input for the tags parameter. This is used to cascade resource tags to all resources.
param tags object = {}

var containerAppEnvironmentName = '${prefix}-env'
var workspaceName = '${prefix}-logs'


// Definition for the Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {}
  }
}

// Definition for the Azure Container Apps Environment
resource environment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  name: containerAppEnvironmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: listKeys(workspace.id, workspace.apiVersion).primarySharedKey
      }
    }
  }
}
