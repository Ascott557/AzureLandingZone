param name string 
param subnets array = []
param location string = 'northeurope'
param enableVmProtection bool = true
param enableDdosProtection bool = false
param tags object
param dnsServers object = {}
param addressPrefixes string


resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    enableDdosProtection: enableDdosProtection
    enableVmProtection: enableVmProtection
    addressSpace: {
      addressPrefixes: [
        addressPrefixes
      ]
    }
    dhcpOptions: dnsServers
    subnets: subnets
  }
}


output vnetid string = vnet.id
output vnetName string = vnet.name
