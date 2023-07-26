param name string 
param location string = 'northeurope'
param sku string = 'Standard'
param tags object
param publicIPAllocationMethod string = 'Static'

resource pip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
  }
}

output pip_id string = pip.id
