param name string 
param location string = 'northeurope'
param sku string = 'Standard'
param privateip string = '0.0.0.0'
param subnetId string 
param bepname string = '${name}-bep'
param tags object
param subid string 
param rgname string
param feIPConfigurations array = [
  {
    name: '${name}-fip'
    properties: {
      privateIPAddress: privateip
      privateIPAllocationMethod: 'Static'
      subnet: {
        id: subnetId
      }
    }
  }
]
param loadBalancingRules array = [
  {
    name: 'lbruleFEall'
    properties: {
      frontendIPConfiguration: {
        id: '/subscriptions/${subid}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/${name}/frontendIPConfigurations/${name}-fip'
      }
      backendAddressPool: {
        id: '/subscriptions/${subid}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/${name}/backendAddressPools/${name}-bep'
      }
      probe: {
        id: '/subscriptions/${subid}/resourceGroups/${rgname}/providers/Microsoft.Network/loadBalancers/${name}/probes/lbprobe'
      }
      protocol: 'All'
      frontendPort: 0
      backendPort: 0
      enableFloatingIP: true
      idleTimeoutInMinutes: 5
    }
  }
]
param probes array = [
  {
    name: 'lbprobe'
    properties: {
      protocol: 'Tcp'
      port: 8008
      intervalInSeconds: 5
      numberOfProbes: 2
    }
  }
]
param inboundNatRules array = []


resource nlb 'Microsoft.Network/loadBalancers@2021-03-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    backendAddressPools: [
      {
        name: bepname
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: '${name}-bep'
            }
          ]
          
        }
        
      }
    ]
    frontendIPConfigurations: feIPConfigurations
    loadBalancingRules: loadBalancingRules
    probes: probes
    inboundNatRules: inboundNatRules
  }
}

output nlb_id string = nlb.id
