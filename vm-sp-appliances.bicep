param vmName string
param location string = resourceGroup().location
param mgmtSubnetId string
param wanSubnetId string
param lanSubnetId string
param publisher string = 'MicrosoftWindowsServer'
param offer string = 'WindowsServer'
param sku string = '2019-datacenter-gensecond'
param osDiskType string = 'Standard_LRS'
param vmSize string = 'Standard_B2ms'
param username string = 'azureadmin'
param publicIPAddressMGMT string
param publicIPAddressWAN string
@secure()
param publickey string
param vmzone string = '1'
param tags object
param plan object = {}

// Bring in the nic
module nicmgmt './vm-nic.bicep' = {
  name: 'nic-${vmName}-mgmt'
  params: {
    name: 'nic-${vmName}-mgmt'
    subnetId: mgmtSubnetId
    publicIPAddress: !empty(publicIPAddressMGMT) ? publicIPAddressMGMT : ''
    location: location
  }
}
module niclan './vm-nic.bicep' = {
  name: 'nic-${vmName}-lan'
  params: {
    name: 'nic-${vmName}-lan'
    subnetId: lanSubnetId
    enableIPForwarding: true
    location: location
  }
}
module nicwan './vm-nic.bicep' = {
  name: 'nic-${vmName}-wan'
  params: {
    name: 'nic-${vmName}-wan'
    subnetId: wanSubnetId
    publicIPAddress: !empty(publicIPAddressWAN) ? publicIPAddressWAN : ''
    location: location
  }
}

// Create the vm
resource vm 'Microsoft.Compute/virtualMachines@2019-07-01' = {
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
    }
    osProfile: {
      computerName: vmName
      adminUsername: username
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${username}/.ssh/authorized_keys'
              keyData: publickey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicmgmt.outputs.nicId
          properties: {
            primary: true
          }
        }
        {
          id: niclan.outputs.nicId
          properties: {
            primary: false
          }
        }
        {
          id: nicwan.outputs.nicId
          properties: {
            primary: false
          }
        }
      ]
    }
  }
  plan: plan
  identity: {
    type: 'SystemAssigned'
  }
}

output id string = vm.id
