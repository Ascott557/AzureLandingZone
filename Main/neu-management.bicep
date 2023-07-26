param customer string
param deploytime string = utcNow('MMMM-dd-yyyy-H-mm-ss')
param env string
param location object 
param sub object
param tenantId string
param secretname string
@secure()
param secretvalue string

var tags = loadJsonContent('shared-tags.json')
targetScope = 'subscription'

//Creating Automationaccount  
module automationAccounts '../modules/mgmt-automation.bicep' = {
  name: '${deploytime}-automationAccounts'
  scope: resourceGroup(sub.management_subid, 'rg-mgmt-${tags.prod.environment}-${location.primary.code}-01')
  dependsOn: [
    workspaces
  ]
  params: {
    location: location.primary.name
    // Required parameters
    name: '${customer}aacom001'
    // Non-required parameters
    tags: tags.prod
    gallerySolutions: [
      {
        name: 'Updates'
        product: 'OMSGallery'
        publisher: 'Microsoft'
      }
    ]
    linkedWorkspaceResourceId: workspaces.outputs.resourceId
    softwareUpdateConfigurations: [
      {
        frequency: 'Month'
        interval: 1
        maintenanceWindow: 'PT3H'
        monthlyOccurrences: [
          {
            day: 'Sunday'
            occurrence: 1
          }
        ]
        name: 'Windows_ZeroDay'
        operatingSystem: 'Windows'
        rebootSetting: 'IfRequired'
        scopeByTags: {
          Update: [
            'Automatic-Wave1'
          ]
        }
        updateClassifications: [
          'Critical'
          'Definition'
          'FeaturePack'
          'Security'
          'ServicePack'
          'Tools'
          'UpdateRollup'
          'Updates'
        ]
      }
      {
        frequency: 'Week'
        interval: 1
        maintenanceWindow: 'PT2H'
        name: 'PMG_Weekly_Critical'
        operatingSystem: 'Windows'
        rebootSetting: 'IfRequired'
        scopeByTags: {
          Update: [
            'Automatic-Wave1'
          ]
        }
        updateClassifications: [
          'Critical'
        ]
      }

      {
        excludeUpdates: [
          'icacls'
        ]
        frequency: 'OneTime'
        includeUpdates: [
          'kernel'
        ]
        maintenanceWindow: 'PT4H'
        name: 'Linux_ZeroDay'
        operatingSystem: 'Linux'
        rebootSetting: 'IfRequired'
        updateClassifications: [
          'Critical'
          'Other'
          'Security'
        ]
      }
    ]
  }
}

//Creating loganalytics workspace
module workspaces '../modules/mgmt-loganalytics.bicep' = {
  name: '${deploytime}-loganalyticsworkspaces'
  scope: resourceGroup(sub.management_subid, 'rg-mgmt-${tags.prod.environment}-${location.primary.code}-01')
  params: {
    // Required parameters
    location: location.primary.name
    name: '${customer}logs001'
    // Non-required parameters
    dailyQuotaGb: 10
    dataSources: [
      {
        eventLogName: 'Application'
        eventTypes: [
          {
            eventType: 'Error'
          }
          {
            eventType: 'Warning'
          }
          {
            eventType: 'Information'
          }
        ]
        kind: 'WindowsEvent'
        name: 'applicationEvent'
      }
      {
        counterName: '% Processor Time'
        instanceName: '*'
        intervalSeconds: 60
        kind: 'WindowsPerformanceCounter'
        name: 'windowsPerfCounter1'
        objectName: 'Processor'
      }
      {
        kind: 'IISLogs'
        name: 'sampleIISLog1'
        state: 'OnPremiseEnabled'
      }
      {
        kind: 'LinuxSyslog'
        name: 'sampleSyslog1'
        syslogName: 'kern'
        syslogSeverities: [
          {
            severity: 'emerg'
          }
          {
            severity: 'alert'
          }
          {
            severity: 'crit'
          }
          {
            severity: 'err'
          }
          {
            severity: 'warning'
          }
        ]
      }
      {
        kind: 'LinuxSyslogCollection'
        name: 'sampleSyslogCollection1'
        state: 'Enabled'
      }
      {
        instanceName: '*'
        intervalSeconds: 10
        kind: 'LinuxPerformanceObject'
        name: 'sampleLinuxPerf1'
        objectName: 'Logical Disk'
        syslogSeverities: [
          {
            counterName: '% Used Inodes'
          }
          {
            counterName: 'Free Megabytes'
          }
          {
            counterName: '% Used Space'
          }
          {
            counterName: 'Disk Transfers/sec'
          }
          {
            counterName: 'Disk Reads/sec'
          }
          {
            counterName: 'Disk Writes/sec'
          }
        ]
      }
      {
        kind: 'LinuxPerformanceCollection'
        name: 'sampleLinuxPerfCollection1'
        state: 'Enabled'
      }
    ]
    useResourcePermissions: true
  }
}
