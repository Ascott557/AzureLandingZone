param name string 
param location string = 'northeurope'
param kind string = 'StorageV2'
param sku string = 'Standard_LRS'
param fwdefault string = 'Deny'
param datalake bool = false
param tags object

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: name
  location: location
  kind: kind
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    networkAcls: {
      defaultAction: fwdefault
    }
    isHnsEnabled: datalake
  }
}

output accid string = storageAccount.id
