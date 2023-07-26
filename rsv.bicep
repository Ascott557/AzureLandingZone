@description('Resource group where the virtual machines are located. This can be different than resource group of the vault. ')
param existingVirtualMachinesResourceGroup string

@description('Array of Azure virtual machines. e.g. ["vm1","vm2","vm3"]')
param existingVirtualMachines array

@description('Name of the Recovery Services Vault')
param vaultName string 

@description('Conditional parameter for New or Existing Vault')
param isNewVault bool = false

@description('Backup policy to be used to backup VMs. Backup POlicy defines the schedule of the backup and how long to retain backup copies. By default every vault comes with a \'DefaultPolicy\' which canbe used here.')
param policyName string = 'PMGBackupPolicy'

@description('Conditional parameter for New or Existing Backup Policy')
param isNewPolicy bool = false

@description('Location for all resources.')
param location string 

var backupFabric = 'Azure'

param tags object

var scheduleRunTimes = [
  '2023-01-16T01:00:00Z'
]


var v2VmType = 'Microsoft.Compute/virtualMachines'
var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2021-03-01' = if (isNewVault) {
  name: vaultName
  tags: tags
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-03-01' = if (isNewPolicy) {
  parent: recoveryServicesVault
  name: policyName
  location: location
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 5
    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: scheduleRunTimes
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
      dailySchedule: {
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
        ]
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 8
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Daily'
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: scheduleRunTimes
        retentionDuration: {
          count: 60
          durationType: 'Months'
        }
      }
      
      retentionPolicyType: 'LongTermRetentionPolicy'
    }
    timeZone: 'UTC'
  }
}

resource protectedItems 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-03-01' = [for item in existingVirtualMachines: {
  name: '${vaultName}/${backupFabric}/${v2VmContainer}${existingVirtualMachinesResourceGroup};${item}/${v2Vm}${existingVirtualMachinesResourceGroup};${item}'
  location: location
  properties: {
    protectedItemType: v2VmType
    policyId: backupPolicy.id
    sourceResourceId: resourceId(subscription().subscriptionId, existingVirtualMachinesResourceGroup, 'Microsoft.Compute/virtualMachines', item)
  }
  dependsOn: [
    recoveryServicesVault
  ]
}]

