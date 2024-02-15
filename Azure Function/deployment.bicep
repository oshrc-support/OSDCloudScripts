@description('resource location')
param location string = 'eastus'

@description('Name of the storage account')
param storageAccountName string = 'oshrcosdcloud-stor'

@description('Name of the function app')
param functionAppName string = 'oshrcosdcloud-fa'

var managedIdentityName = '${functionAppName}-identity'
var appInsightsName = '${functionAppName}-appinsights'
var appServicePlanName = '${functionAppName}-appserviceplan'

var blobServiceUri = 'https://${storageAccountName}.blob.core.windows.net/'
var queueServiceUri = 'https://${storageAccountName}.queue.core.windows.net/'
var tableServiceUri = 'https://${storageAccountName}.table.core.windows.net/'
var queueName = 'queue'
var tableStorageName = 'table'

var storageOwnerRoleDefinitionResourceId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var storageQueueDataContributorRoleId = '/providers/Microsoft.Authorization/roleDefinitions/974c5e8b-45b9-4653-ba55-5f855dd0fb88'
var storageQueueDataQueueMessageSenderRoleId = '/providers/Microsoft.Authorization/roleDefinitions/c6a89b2d-59bc-44d0-9896-0f6e12d7b80a'
var storageTableDataContributorRoleId = '/providers/Microsoft.Authorization/roleDefinitions/0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
	name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties:{
	  allowBlobPublicAccess: false
  }
}
resource storageQueuesService 'Microsoft.Storage/storageAccounts/queueServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2021-04-01' = {
  name: queueName
  parent: storageQueuesService
  properties: {
	visibilityTimeout: '00:00:30'
	messageTimeToLive: '00:02:00'
	deadLetteringOnMessageExpiration: true
	maxDeliveryCount: 5
  }
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource table 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-04-01' = {
  name: tableStorageName
  parent: tableService
}


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

resource storageOwnerPermission 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(storageAccount.id, functionAppName, storageOwnerRoleDefinitionResourceId)
  scope: storageAccount
  properties: {
	principalId: managedIdentity.properties.principalId
	roleDefinitionId: storageOwnerRoleDefinitionResourceId
  }
}

resource storageQueueContributorPermission 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(storageAccount.id, functionAppName, storageQueueDataContributorRoleId)
  scope: storageAccount
  properties: {
	principalId: managedIdentity.properties.principalId
	roleDefinitionId: storageQueueDataContributorRoleId
  }
}

resource storageQueueSenderPermission 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(storageAccount.id, functionAppName, storageQueueDataQueueMessageSenderRoleId)
  scope: storageAccount
  properties: {
	principalId: managedIdentity.properties.principalId
	roleDefinitionId: storageQueueDataQueueMessageSenderRoleId
  }
}
resource storageTableContributorPermission 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(storageAccount.id, functionAppName, storageTableDataContributorRoleId)
  scope: storageAccount
  properties: {
	principalId: managedIdentity.properties.principalId
	roleDefinitionId: storageTableDataContributorRoleId
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
	Application_Type: 'web'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
	name: 'Y1'
	tier: 'Dynamic'
  }
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {'${managedIdentity.id}': {}}
  }
  properties: {
	serverFarmId: appServicePlan.id
	siteConfig: {
	  appSettings: [
		{
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
		{
		  name: 'FUNCTIONS_EXTENSION_VERSION'
		  value: '~4'
		}
		{
		  name: 'FUNCTIONS_WORKER_RUNTIME'
		  value: 'dotnet'
		}
		{
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
		
		{
		  name: 'blobConnection__accountName'
		  value: storageAccountName
		}
		{
          name: 'blobConnection__serviceUri'
          value: blobServiceUri
        }
		{
          name: 'blobConnection__queueServiceUri'
          value: queueServiceUri
        }
		{
          name: 'blobConnection__tableServiceUri'
          value: tableServiceUri
        }
		
		{
		  name: 'blobConnection__credential'
		  value: 'managedidentity'
		}
		{
		  name: 'blobConnection__clientId'
		  value: managedIdentity.properties.clientId
		}
	  ]
	}
  }
}
