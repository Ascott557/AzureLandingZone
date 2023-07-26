@description('Required. Name of the Log Analytics workspace.')
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Service Tier: PerGB2018, Free, Standalone, PerGB or PerNode.')
@allowed([
  'Free'
  'Standalone'
  'PerNode'
  'PerGB2018'
])
param serviceTier string = 'PerGB2018'


@description('Optional. LAW data sources to configure.')
param dataSources array = []

@description('Optional. Number of days data will be retained for.')
@minValue(0)
@maxValue(730)
param dataRetention int = 365

@description('Optional. The workspace daily quota for ingestion.')
@minValue(-1)
param dailyQuotaGb int = 1

@description('Optional. The network access type for accessing Log Analytics ingestion.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForIngestion string = 'Enabled'

@description('Optional. The network access type for accessing Log Analytics query.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForQuery string = 'Enabled'

@description('Optional. Set to \'true\' to use resource or workspace permissions and \'false\' (or leave empty) to require workspace permissions.')
param useResourcePermissions bool = false

@description('Optional. Indicates whether customer managed storage is mandatory for query management.')
param forceCmkForQuery bool = true

@description('Optional. Tags of the resource.')
param tags object = {}


var logAnalyticsSearchVersion = 1

var enableReferencedModulesTelemetry = false



resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  location: location
  name: name
  tags: tags
  properties: {
    features: {
      searchVersion: logAnalyticsSearchVersion
      enableLogAccessUsingOnlyResourcePermissions: useResourcePermissions
    }
    sku: {
      name: serviceTier
    }
    retentionInDays: dataRetention
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
    forceCmkForQuery: forceCmkForQuery
  }
}

module logAnalyticsWorkspace_dataSources './mgmt-logandatasources.bicep' = [for (dataSource, index) in dataSources: {
  name: '${uniqueString(deployment().name, location)}-LAW-DataSource-${index}'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.name
    name: dataSource.name
    kind: dataSource.kind
    linkedResourceId: contains(dataSource, 'linkedResourceId') ? dataSource.linkedResourceId : ''
    eventLogName: contains(dataSource, 'eventLogName') ? dataSource.eventLogName : ''
    eventTypes: contains(dataSource, 'eventTypes') ? dataSource.eventTypes : []
    objectName: contains(dataSource, 'objectName') ? dataSource.objectName : ''
    instanceName: contains(dataSource, 'instanceName') ? dataSource.instanceName : ''
    intervalSeconds: contains(dataSource, 'intervalSeconds') ? dataSource.intervalSeconds : 60
    counterName: contains(dataSource, 'counterName') ? dataSource.counterName : ''
    state: contains(dataSource, 'state') ? dataSource.state : ''
    syslogName: contains(dataSource, 'syslogName') ? dataSource.syslogName : ''
    syslogSeverities: contains(dataSource, 'syslogSeverities') ? dataSource.syslogSeverities : []
    performanceCounters: contains(dataSource, 'performanceCounters') ? dataSource.performanceCounters : []
  }
}]


@description('The resource ID of the deployed log analytics workspace.')
output resourceId string = logAnalyticsWorkspace.id

@description('The resource group of the deployed log analytics workspace.')
output resourceGroupName string = resourceGroup().name

@description('The name of the deployed log analytics workspace.')
output name string = logAnalyticsWorkspace.name

@description('The ID associated with the workspace.')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.properties.customerId

@description('The location the resource was deployed into.')
output location string = logAnalyticsWorkspace.location
