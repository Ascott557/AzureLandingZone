param customer string
param deploytime string = utcNow('MMMM-dd-yyyy-H-mm-ss')
param env string
param location object 
param sub object
param tenantId string
param secretname string
@secure()
param secretvalue string
var tags = loadJsonContent('shared-tags.json')

targetScope = 'subscription'
module kv '../modules/keyVault.bicep' = {
  name: '${deploytime}-kv'
  scope: resourceGroup(sub.management_subid, 'rg-mgmt-${env}-${location.primary.code}-01')
  params: {
    name: 'kv-${customer}-5-mgmt-${location.primary.code}-01'
    tenantId: tenantId
    tags: tags.prod
    location: location.primary.name
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    enableSoftDelete: true
    retentiondays: 30
    skuName: 'standard'
    secretname: secretname
    secretvalue: secretvalue
  }
}
