param name string 
param location string = 'northeurope'
param tags object
param nsgRules array = []

resource SubnetNsg 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    securityRules: nsgRules
  }
}

output nsgid string = SubnetNsg.id
