param name string
param location string = resourceGroup().location
param subnetId string
param privateIPAddress string =  '10.0.0.4'
param allocation string = 'Dynamic'
param enableAcceleratedNetworking bool = false
param enableIPForwarding bool = false
param loadBalancerBackendAddressPools array = []
param loadBalancerInboundNatRules array = []
param publicIPAddress string = ''

resource nic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: name
        properties: {
          privateIPAddress: privateIPAddress
          publicIPAddress: !empty(publicIPAddress) ? { id: publicIPAddress } : null
          privateIPAllocationMethod: allocation
          subnet: {
            id: subnetId
          }
          privateIPAddressVersion: 'IPv4'
          loadBalancerBackendAddressPools: loadBalancerBackendAddressPools
          loadBalancerInboundNatRules: loadBalancerInboundNatRules
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableIPForwarding: enableIPForwarding
  }
}


output nicId string = nic.id
