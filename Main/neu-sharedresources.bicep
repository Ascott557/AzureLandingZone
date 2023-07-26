param customer string
param tenantId string
param deploytime string = 'utcNow(\'MMMM-dd-yyyy-H-mm-ss\')' 
param env string
param location object 
param sub object 
param secretname string
@secure()
param secretvalue string


@description('Tags to be applied on Azure resources based on environment')
var tags = loadJsonContent('shared-tags.json')

targetScope = 'subscription'
//Refrencing keyvault to get VM password
resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-${customer}-5-mgmt-${location.primary.code}-01'
  scope: resourceGroup(sub.management_subid, 'rg-mgmt-${tags.prod.environment}-${location.primary.code}-01')
}

//Refrencing the North Europe Virtual Network for subnet id
resource vnetspkss1prdpri 'Microsoft.Network/virtualNetworks@2022-07-01' existing = {
  name: 'vnet-${customer}-${location.primary.code}-spk-ss1'
  scope: resourceGroup(sub.sharedservices_subid, 'rg-netspk-${tags.prod.environment}-${location.primary.code}-01')
}

// Get exsisting log
resource loganalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: '${customer}logs001'
  scope: resourceGroup(sub.management_subid, 'rg-mgmt-${tags.prod.environment}-${location.primary.code}-01')
}

param userName string = 'azureadmin'

//Creating EPM Automate Production server in Primary region
module vmpriprdepma001 '../modules/vm.bicep' = {
  scope: resourceGroup(sub.sharedservices_subid, 'rg-epma-${env}-${location.primary.code}-01')
  name: '${customer}-vm-azpriepma001'
  params: {
    vmName: 'vm-epmaprdneu01'
    tags: tags.prod
    username: userName
    password: kv.getSecret('epmaprdadminpwd')
    subnetId: '${vnetspkss1prdpri.id}/subnets/lan'
    location: location.primary.name
    vmSize: 'Standard_D2ds_v4'
    vmzone: '1'
    // Optional code for onboarding to log analytics
    extensionMonitoringAgentConfig: {
      enabled: true
    }
    monitoringWorkspaceId: loganalytics.id
    dataDisks: [
      {
        caching: 'ReadOnly'
        createOption: 'Empty'
        diskSizeGB: '128'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    ]
    publisher: 'microsoftsqlserver'
    offer: 'sql2019-ws2022'
    sku: 'standard-gen2'
  }
}

