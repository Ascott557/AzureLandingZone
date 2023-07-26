param name string 
param location string = 'northeurope'
param tags object
param disableBgpRoutePropagation bool = true
param routes array = []

resource routetable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: disableBgpRoutePropagation
    routes: routes
  }
}

output rtid string = routetable.id
output rtname string = routetable.name
