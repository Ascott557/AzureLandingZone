param name string 
param location string = resourceGroup().location
param tags object 
param skuName string = 'standard'
param retentiondays int = 90
param enabledForDeployment bool = true
param enabledForDiskEncryption bool = true
param enabledForTemplateDeployment bool = true
param enablePurgeProtection bool = true
param enableRbacAuthorization bool = true
param enableSoftDelete bool = true
param ipRules array = []
param virtualNetworkRules array = []
param accessPolicies array = []
param defaultAction string = 'allow'
param tenantId string
param secretname string
@secure()
param secretvalue string


resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    accessPolicies: accessPolicies
    tenantId: tenantId
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: defaultAction
      ipRules: ipRules
      virtualNetworkRules: virtualNetworkRules
    }
    sku: {
      family: 'A'
      name: skuName
    }
    softDeleteRetentionInDays: retentiondays
  }
  resource secrets 'secrets' = { 
    name: secretname
    properties: {
      value: secretvalue
    }
  }
}
output kvid string = kv.id
