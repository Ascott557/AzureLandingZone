param vmNamePrefix string = 'vm-azneufwl00'
param location string = resourceGroup().location
param extSubnetId string
param intSubnetId string
param publisher string = 'fortinet'
param offer string = 'fortinet_fortigate-vm_v5'
param sku string = 'fortinet_fg-vm_payg_20190624'
param osDiskType string = 'Premium_LRS'
param vmSize string = 'Standard_F2s'
param username string = 'pmglocal'
@secure()
param userpwd string
param vmzone string = '1'
param tags object
param plan object = {}

// Bring in the nic
module nicext './vm-nic.bicep' = {
  name: 'nic-${vmNamePrefix}-ext'
  params: {
    name: 'nic-${vmNamePrefix}-ext'
    subnetId: extSubnetId
    location: location
    privateIPAddress: '172.29.128.132'
    allocation: 'static'
    enableIPForwarding: true
  }
}
module nicint './vm-nic.bicep' = {
  name: 'nic-${vmNamePrefix}-int'
  params: {
    name: 'nic-${vmNamePrefix}-int'
    subnetId: intSubnetId
    location: location
    privateIPAddress: '172.29.128.164'
    allocation: 'static'
    enableIPForwarding: true
  }
}

// Create the vm
resource vm 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: '${vmNamePrefix}1'
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
      dataDisks: [
        {
          diskSizeGB: 30
          lun: 0
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: osDiskType
          }
        }
      ]
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: 'latest'
      }
    }
    osProfile: {
      computerName: '${vmNamePrefix}1'
      adminUsername: username
      adminPassword: userpwd
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicext.outputs.nicId
          properties: {
            primary: true
          }
        }
        {
          id: nicint.outputs.nicId
          properties: {
            primary: false
          }
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  plan: plan
}
