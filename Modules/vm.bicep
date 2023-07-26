param vmName string
param location string = resourceGroup().location
param subnetId string
param allocation string = 'Dynamic'
param privateIPAddress string = '10.1.1.1'
param publisher string = 'MicrosoftWindowsServer'
param offer string = 'WindowsServer'
param sku string = '2019-datacenter-gensecond'
param osDiskType string = 'Standard_LRS'
param vmSize string = 'Standard_B2ms'
param username string = 'azureadmin'
@secure()
param password string
param vmzone string = '1'
param tags object
param dataDisks array = []
param monitoringWorkspaceId string = ''
param extensionMonitoringAgentConfig object = {
  enabled: false
}
param osType string = 'Windows'

// Bring in the nic

module nic './vm-nic.bicep' = {
  name: '${vmName}-nic'
  params: {
    name: 'nic-${vmName}-01'
    subnetId: subnetId
    allocation: allocation
    privateIPAddress: privateIPAddress
    location: location
  }
}

// Create the vm
resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: vmName
  location: location
  zones: [
    vmzone
  ]
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: 'latest'
      }
      dataDisks: [for (dataDisk, index) in dataDisks: {
        lun: index
        name: contains(dataDisk, 'name') ? dataDisk.name : '${vmName}-disk-data-${padLeft((index + 1), 2, '0')}'
        diskSizeGB: dataDisk.diskSizeGB
        createOption: contains(dataDisk, 'createOption') ? dataDisk.createOption : 'Empty'
        caching: contains(dataDisk, 'caching') ? dataDisk.caching : 'ReadOnly'
        managedDisk: {
          storageAccountType: dataDisk.managedDisk.storageAccountType
          diskEncryptionSet: contains(dataDisk.managedDisk, 'diskEncryptionSet') ? {
            id: dataDisk.managedDisk.diskEncryptionSet.id
          } : null
        }
      }]
    }
    osProfile: {
      computerName: vmName
      adminUsername: username
      adminPassword: password
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.outputs.nicId
        }
      ]
    }
  }
  // plan: plan
  identity: {
    type: 'SystemAssigned'
  }
}

// Log Analytics Onboarding

resource vm_logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = if (!empty(monitoringWorkspaceId)) {
  name: last(split(monitoringWorkspaceId, '/'))
  scope: az.resourceGroup(split(monitoringWorkspaceId, '/')[2], split(monitoringWorkspaceId, '/')[4])
}

module vm_microsoftMonitoringAgentExtension './vm-extension.bicep' = if (extensionMonitoringAgentConfig.enabled) {
  name: '${uniqueString(deployment().name, location)}-VM-MicrosoftMonitoringAgent'
  params: {
    virtualMachineName: vm.name
    location: location
    name: 'MicrosoftMonitoringAgent'
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: osType == 'Windows' ? 'MicrosoftMonitoringAgent' : 'OmsAgentForLinux'
    typeHandlerVersion: contains(extensionMonitoringAgentConfig, 'typeHandlerVersion') ? extensionMonitoringAgentConfig.typeHandlerVersion : (osType == 'Windows' ? '1.0' : '1.7')
    autoUpgradeMinorVersion: contains(extensionMonitoringAgentConfig, 'autoUpgradeMinorVersion') ? extensionMonitoringAgentConfig.autoUpgradeMinorVersion : true
    enableAutomaticUpgrade: contains(extensionMonitoringAgentConfig, 'enableAutomaticUpgrade') ? extensionMonitoringAgentConfig.enableAutomaticUpgrade : false
    settings: {
      workspaceId: !empty(monitoringWorkspaceId) ? reference(vm_logAnalyticsWorkspace.id, vm_logAnalyticsWorkspace.apiVersion).customerId : ''
    }
    protectedSettings: {
      workspaceKey: !empty(monitoringWorkspaceId) ? vm_logAnalyticsWorkspace.listKeys().primarySharedKey : ''
    }
  }
}


output id string = vm.id
output resourcegroup string = resourceGroup().name
output vmname string = vm.name
