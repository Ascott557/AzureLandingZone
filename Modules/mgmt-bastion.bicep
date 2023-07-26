param name string 
param location string
param vnet string
param tags object

resource bastionHostPip 'Microsoft.Network/publicIpAddresses@2020-05-01' = {
  name: 'pip-${name}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2020-06-01'= {
  name: name
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: '${name}-ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: bastionHostPip.id
          }
        }
      }
    ]
  }
}

output bastionid string = bastionHost.id
