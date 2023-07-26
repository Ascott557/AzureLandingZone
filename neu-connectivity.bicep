@description('Customer name in short form, currently used in VNet names')
param customer string
param deploytime string = utcNow('MMMM-dd-yyyy-H-mm-ss')
@description('Environment in short form')
param env string
@description('location of resources')
param location object 
@description('Target subscription/Management group')
param sub object
@description('Customer tenant ID')
param tenantId string
param secretname string
@secure()
param secretvalue string
@description('Tags to be applied on Azure resources based on environment')
var tags = loadJsonContent('shared-tags.json')

targetScope = 'subscription'


/////////////////////////////////////
// North Europe Hub Network
/////////////////////////////////////
module vnethubprdpri '../modules/network.bicep' = {
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnethubprdpri'
  params: {
    name: 'vnet-${customer}-${location.primary.code}-hub'
    tags: tags.prod
    location: location.primary.name
    addressPrefixes: '172.29.96.0/23'
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '172.29.96.0/27'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '172.29.96.64/26'
        }
      }
    ]
  }
}

module vnetpeerprihubhubsec '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetpeerprihubhubsec'
  params: {
    localVnetName: vnethubprdpri.outputs.vnetName
    remoteVnetID: vnethubprdsec.outputs.vnetid
    remoteVnetName: vnethubprdsec.outputs.vnetName
  }
}

module vnetpeerprihubspkss1 '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetpeerprihubspkss1'
  params: {
    localVnetName: vnethubprdpri.outputs.vnetName
    remoteVnetID: vnetspkss1prdpri.outputs.vnetid
    remoteVnetName: vnetspkss1prdpri.outputs.vnetName
  }
}
module vnetpeersechubspkss1 '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetpeersechubspkss1'
  params: {
    localVnetName: vnethubprdpri.outputs.vnetName
    remoteVnetID: vnetspkss1prdsec.outputs.vnetid
    remoteVnetName: vnetspkss1prdsec.outputs.vnetName
  }
}

module vnethubbastion '../modules/mgmt-bastion.bicep' = {
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.primary.code}-01')
  name: '${deploytime}-bas-${location.primary.code}-${env}-01'
  params: {
    name: 'bas-${location.primary.code}-${env}-01'
    vnet: vnethubprdpri.outputs.vnetName
    tags: tags.prod
    location: location.primary.name
  }
}

/////////////////////////////////////
//West Europe Hub Network
/////////////////////////////////////
module vnethubprdsec '../modules/network.bicep' = {
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vnethubprdsec'
  params: {
    name: 'vnet-${customer}-${location.secondary.code}-hub'
    tags: tags.prod
    location: location.secondary.name
    addressPrefixes: '172.29.112.0/23'
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '172.29.112.0/27'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '172.29.112.64/26'
        }
      }
    ]
  }
}
module vnetpeersechubhub '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vnetpeersechubhub'
  params: {
    localVnetName: vnethubprdsec.outputs.vnetName
    remoteVnetID: vnethubprdpri.outputs.vnetid
    remoteVnetName: vnethubprdpri.outputs.vnetName
  }
}


///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                       Shared Services Network                         //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

// North Europe Shared Services Network
module vnetspkss1prdpri '../modules/network.bicep' = {
  scope: resourceGroup(sub.sharedservices_subid, 'rg-netspk-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetspkss1prdpri'
  params: {
    name: 'vnet-${customer}-${location.primary.code}-spk-ss1'
    tags: tags.prod
    location: location.primary.name
    addressPrefixes: '172.29.100.0/23'
    subnets: [
      {
        name: 'lan'
        properties: {
          addressPrefix: '172.29.100.0/24'
          networkSecurityGroup: {
            id: nsgvnetssprispkss1network.outputs.nsgid
          }
        }
      }
    ]
  }
}
module vnetpeerprispkss1hub '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.sharedservices_subid, 'rg-netspk-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetpeerprispkss1hub'
  params: {
    localVnetName: vnetspkss1prdpri.outputs.vnetName
    remoteVnetID: vnethubprdpri.outputs.vnetid
    remoteVnetName: vnethubprdpri.outputs.vnetName
  }
}

module nsgvnetssprispkss1network '../modules/vnet-nsg.bicep' = {
  scope: resourceGroup(sub.sharedservices_subid, 'rg-netspk-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetspkss1snlan'
  params: {
    name: 'nsg-sn-vnet-${customer}-${location.primary.code}-spk-ss1'
    location: location.primary.name
    tags: tags.prod
    nsgRules: []
  }
}

resource alz1netspkrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-netspk-${env}-${location.primary.code}-01'
  location: location.primary.name
  tags: tags.prod
}

// West Europe Shared Services Network
module vnetspkss1prdsec '../modules/network.bicep' = {
  scope: resourceGroup(sub.sharedservices_subid, 'rg-netspk-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vnetspkss1prdsec'
  params: {
    name: 'vnet-${customer}-${location.secondary.code}-spk-ss1'
    tags: tags.prod
    location: location.secondary.name
    addressPrefixes: '172.29.116.0/23'
    subnets: [
      {
        name: 'lan'
        properties: {
          addressPrefix: '172.29.116.0/24'
          networkSecurityGroup: {
            id: nsgvnetsssecspkss2network.outputs.nsgid
          }
        }
      }
    ]
  }
}
module vnetpeersecspkss1hub '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.sharedservices_subid, 'rg-netspk-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vnetpeersecspkss1hub'
  params: {
    localVnetName: vnetspkss1prdsec.outputs.vnetName
    remoteVnetID: vnethubprdpri.outputs.vnetid
    remoteVnetName: vnethubprdpri.outputs.vnetName
  }
}
module nsgvnetsssecspkss2network '../modules/vnet-nsg.bicep' = {
  scope: resourceGroup(sub.sharedservices_subid, 'rg-netspk-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vnetsecspkss1snlan'
  params: {
    name: 'nsg-sn-vnet-${customer}-${location.secondary.code}-spk-ss1'
    location: location.secondary.name
    tags: tags.prod
    nsgRules: []
  }
}
