param vmNamePrefix string = 'vm-azneufwl00'
param location string = resourceGroup().location
param extSubnetId string
param intSubnetId string
param subId string
param rgname string
param publisher string = 'fortinet'
param offer string = 'fortinet_fortigate-vm_v5'
param sku string = 'fortinet_fg-vm_payg_20190624'
param osDiskType string = 'Premium_LRS'
param vmSize string = 'Standard_F2s'
param username string = 'pmglocal'
@secure()
param userpwd string
param vmzone1 string = '1'
param vmzone2 string = '2'
param tags object
param plan object = {}

var vmNamea  = '${vmNamePrefix}1'
var vmNameb  = '${vmNamePrefix}2'

// Bring in the nic
module a_nicext './vm-nic.bicep' = {
  name: 'nic-${vmNamea}-ext'
  params: {
    name: 'nic-${vmNamea}-ext'
    subnetId: extSubnetId
    location: location
    enableIPForwarding: true
    loadBalancerBackendAddressPools: [
      {
        id: '${nlb_ext.outputs.nlb_id}/backendAddressPools/nlb-ext-azneufwl-01-bep'
      } 
    ]
    loadBalancerInboundNatRules: [
      {
        id: '${nlb_ext.outputs.nlb_id}/inboundNatRules/nlb-ext-azneufwl-01-ASSH'
      }
      {
        id: '${nlb_ext.outputs.nlb_id}/inboundNatRules/nlb-ext-azneufwl-01-AFGAdminPerm'
      }
    ]
  }
}
module a_nicint './vm-nic.bicep' = {
  name: 'nic-${vmNamea}-int'
  params: {
    name: 'nic-${vmNamea}-int'
    subnetId: intSubnetId
    location: location
    enableIPForwarding: true
    loadBalancerBackendAddressPools: [
      {
        id: '${nlb_int.outputs.nlb_id}/backendAddressPools/nlb-int-azneufwl-01-bep'
      } 
    ]
  }
}
module b_nicext './vm-nic.bicep' = {
  name: 'nic-${vmNameb}-ext'
  params: {
    name: 'nic-${vmNameb}-ext'
    subnetId: extSubnetId
    enableIPForwarding: true
    location: location
    loadBalancerBackendAddressPools: [
      {
        id: '${nlb_ext.outputs.nlb_id}/backendAddressPools/nlb-ext-azneufwl-01-bep'
      } 
    ]
    loadBalancerInboundNatRules: [
      {
        id: '${nlb_ext.outputs.nlb_id}/inboundNatRules/nlb-ext-azneufwl-01-BSSH'
      }
      {
        id: '${nlb_ext.outputs.nlb_id}/inboundNatRules/nlb-ext-azneufwl-01-BFGAdminPerm'
      }
    ]
  }
}
module b_nicint './vm-nic.bicep' = {
  name: 'nic-${vmNameb}-int'
  params: {
    name: 'nic-${vmNameb}-int'
    subnetId: intSubnetId
    location: location
    enableIPForwarding: true
    loadBalancerBackendAddressPools: [
      {
        id: '${nlb_int.outputs.nlb_id}/backendAddressPools/nlb-int-azneufwl-01-bep'
      } 
    ]
  }
}

module nlb_int './vnet-loadbalancer.bicep' = {
  name: 'nlb-int-azneufwl-01'
  params: {
    name: 'nlb-int-azneufwl-01'
    subnetId: intSubnetId
    location: location
    privateip: '172.29.96.169'
    tags:tags
    subid: subId
    rgname: rgname
  }
}

module nlb_ext_pip './vnet-pip.bicep' = {
  name: 'nlb-ext-azneufwl-01-pip'
  params: {
    name: 'nlb-ext-azneufwl-01-pip'
    tags: tags
    location: location

  }
}
module nlb_ext './vnet-loadbalancer.bicep' = {
  name: 'nlb-ext-azneufwl-01'
  params: {
    name: 'nlb-ext-azneufwl-01'
    subnetId: extSubnetId
    tags:tags
    location: location
    subid: subId
    rgname: rgname
    feIPConfigurations: [
      {
        name: 'nlb-ext-azneufwl-01-fip'
        properties: {
          publicIPAddress: {
            id: nlb_ext_pip.outputs.pip_id
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'ExternalLBRule-FE-http'
        properties: {
          frontendIPConfiguration: {
            id: '/subscriptions/${subId}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/nlb-ext-azneufwl-01/frontendIPConfigurations/nlb-ext-azneufwl-01-fip'
          }
          backendAddressPool: {
            id: '/subscriptions/${subId}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/nlb-ext-azneufwl-01/backendAddressPools/nlb-ext-azneufwl-01-bep'
          }
          probe: {
            id: '/subscriptions/${subId}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/nlb-ext-azneufwl-01/probes/lbprobe'
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
        }
      }
      {
        name: 'ExternalLBRule-FE-udp10551'
        properties: {
          frontendIPConfiguration: {
            id: '/subscriptions/${subId}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/nlb-ext-azneufwl-01/frontendIPConfigurations/nlb-ext-azneufwl-01-fip'
          }
          backendAddressPool: {
            id: '/subscriptions/${subId}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/nlb-ext-azneufwl-01/backendAddressPools/nlb-ext-azneufwl-01-bep'
          }
          probe: {
            id: '/subscriptions/${subId}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/nlb-ext-azneufwl-01/probes/lbprobe'
          }
          protocol: 'Udp'
          frontendPort: 10551
          backendPort: 10551
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
        }
      }
    ]
    inboundNatRules: [
      {
        name: 'nlb-ext-azneufwl-01-ASSH'
        properties: {
          frontendIPConfiguration: {
            id: '/subscriptions/${subId}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/nlb-ext-azneufwl-01/frontendIPConfigurations/nlb-ext-azneufwl-01-fip'
          }
          protocol: 'Tcp'
          frontendPort: 50030
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'nlb-ext-azneufwl-01-AFGAdminPerm'
        properties: {
          frontendIPConfiguration: {
            id: '/subscriptions/${subId}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/nlb-ext-azneufwl-01/frontendIPConfigurations/nlb-ext-azneufwl-01-fip'
          }
          protocol: 'Tcp'
          frontendPort: 40030
          backendPort: 443
          enableFloatingIP: false
        }
      }
      {
        name: 'nlb-ext-azneufwl-01-BSSH'
        properties: {
          frontendIPConfiguration: {
            id: '/subscriptions/${subId}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/nlb-ext-azneufwl-01/frontendIPConfigurations/nlb-ext-azneufwl-01-fip'
          }
          protocol: 'Tcp'
          frontendPort: 50031
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: 'nlb-ext-azneufwl-01-BFGAdminPerm'
        properties: {
          frontendIPConfiguration: {
            id: '/subscriptions/${subId}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/nlb-ext-azneufwl-01/frontendIPConfigurations/nlb-ext-azneufwl-01-fip'
          }
          protocol: 'Tcp'
          frontendPort: 40031
          backendPort: 443
          enableFloatingIP: false
        }
      }
      
    ]
  }
}




// Create the vm
resource vm_a 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmNamea
  location: location
  zones: [
    vmzone1
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
      computerName: vmNamea
      adminUsername: username
      adminPassword: userpwd
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: a_nicext.outputs.nicId
          properties: {
            primary: true
          }
        }
        {
          id: a_nicint.outputs.nicId
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

resource vm_b 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: vmNameb
  location: location
  zones: [
    vmzone2
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
      computerName: vmNameb
      adminUsername: username
      adminPassword: userpwd
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: b_nicext.outputs.nicId
          properties: {
            primary: true
          }
        }
        {
          id: b_nicint.outputs.nicId
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

module nsgvnethubneu_fgext 'vnet-nsg.bicep' = {
  scope: resourceGroup(subId, 'rg-nethub-prd-neu-01')
  name: 'nsgvnethubneufgext'
  params: {
    name: 'nsg-sn-vnet-pmgg-neu-hub-fg-ext'
    location: location
    tags: tags
    nsgRules: [
      {
        name: 'AllowAllInBound'
        properties: {
          priority: '1000'
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceApplicationSecurityGroups: []
          destinationApplicationSecurityGroups: []
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'HTTPS'
        properties: {
          priority: '1000'
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceApplicationSecurityGroups: []
          destinationApplicationSecurityGroups: []
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

module nsgvnethubneu_fgint 'vnet-nsg.bicep' = {
  scope: resourceGroup(subId, 'rg-nethub-prd-neu-01')
  name: 'nsgvnethubneufgint'
  params: {
    name: 'nsg-sn-vnet-pmgg-neu-hub-fg-int'
    location: location
    tags: tags
    nsgRules: [
      {
        name: 'AllowAllInBound'
        properties: {
          priority: '1000'
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceApplicationSecurityGroups: []
          destinationApplicationSecurityGroups: []
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'HTTPS'
        properties: {
          priority: '1000'
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceApplicationSecurityGroups: []
          destinationApplicationSecurityGroups: []
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

output id_a string = vm_a.id
output id_b string = vm_b.id
output nsgid_fgint string = nsgvnethubneu_fgext.outputs.nsgid
output nsgid_fgext string = nsgvnethubneu_fgext.outputs.nsgid


