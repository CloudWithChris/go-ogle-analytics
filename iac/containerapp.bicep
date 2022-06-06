param prefix string = 'cwc-ga'
param acrName string = 'cwceventplatform'

param location string = resourceGroup().location
param containerAppImage string

// Also take an object as an input for the tags parameter. This is used to cascade resource tags to all resources.
param tags object = {}

var containerAppEnvironmentName = '${prefix}-env'
var containerAppName = '${prefix}-analytics'
var containerRegistryLoginServer = 'cwceventplatform.azurecr.io'
var containerRegistryPasswordRef = 'container-registry-password'

resource acrResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: 'event-platform-rg'
  scope: subscription()
}

// Definition for the existing Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: acrName
  scope: acrResourceGroup
}

//Container App Environment
resource environment 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: containerAppEnvironmentName
}

resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: containerAppName
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 6002
      }
      registries: [
        {
          server: containerRegistryLoginServer
          username: acr.name
          passwordSecretRef: containerRegistryPasswordRef
        }
      ]
      secrets : [
        {
          name: containerRegistryPasswordRef
          value: listCredentials(acr.id, acr.apiVersion).passwords[0].value
        }
      ]
    }
    template: {
      containers: [
        {
          image: containerAppImage
          name: 'analytics'
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
    }
  }
}

