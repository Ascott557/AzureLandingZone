param customer string
param deploytime string = utcNow('yyyyMMddHHmmssfff')
param env string
param userName string = 'azureadmin'
param location object 
param sub object
param tenantId string
param secretname string
@secure()
param secretvalue string
var tags = loadJsonContent('shared-tags.json')

//Responsible for DNS configuration in Azure Virtual Networks for North Europe and West Europe location
var customDnsServers = {
  primary: {
    dnsServers: [
      '172.29.98.4'
      '172.29.98.5'
      '172.29.114.4'
    ]
  }
  secondary: {
    dnsServers: [
      '172.29.114.4'
      '172.29.98.4'
      '172.29.98.5'
    ]
  }
}

var spokeneroutes = [
  {
    name: 'AllTraffic'
    properties: {
      addressPrefix: '0.0.0.0/0'
      hasBgpOverride: false
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: '172.29.96.164'
    }
  }
]

//Refrencing Key Vault to get password to deploy VMs
resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-${customer}-mgmt-${location.primary.code}-01'
  scope: resourceGroup(sub.management_subid, 'rg-mgmt-${env}-${location.primary.code}-01')
}

/////////////////////////////////////
// North Europe Hub Network
/////////////////////////////////////
//Refrencing North Europe hub network for VMs subnet ID
resource vnethubprdpri 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: 'vnet-${customer}-${location.primary.code}-hub'
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.primary.code}-01')
}

resource vnethubprdsec 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: 'vnet-${customer}-${location.secondary.code}-hub'
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.secondary.code}-01')
}

/////////////////////////////////////
// North Europe ID Spoke Network
/////////////////////////////////////
module vnetspkidprdpri '../modules/network.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-netspk-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetspkid1prdpri'
  params: {
    name: 'vnet-${customer}-${location.primary.code}-${env}-id1'
    tags: tags.prod
    location: location.primary.name
    addressPrefixes: '172.29.98.0/23'
    dnsServers: customDnsServers.primary
    subnets: [
      {
        name: 'ADDSNetwork'
        properties: {
          addressPrefix: '172.29.98.0/24'
          networkSecurityGroup: {
            id: nsgvnetidsnaddsnetwork.outputs.nsgid
          }
          routeTable: {
            id: rt_vnetspkpri.outputs.rtid
          }
        }
      }
    ]
  }
}

module rt_vnetspkpri '../modules/vnet-routetable.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-netspk-${env}-${location.primary.code}-01')
  name: '${deploytime}-rt-vnetspkpri'
  params: {
    name: 'rt-vnet-${customer}-${location.primary.code}-${env}-id1'
    tags: tags.prod
    location: location.primary.name
    routes: spokeneroutes
  }
}

// Peering from NEU HUB TO NEU ID
module vnetpeerprispkidhub '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetpeerprispkid1hub'
  params: {
    localVnetName: vnethubprdpri.name
    remoteVnetID: vnetspkidprdpri.outputs.vnetid
    remoteVnetName: vnetspkidprdpri.outputs.vnetName
  }
}
//Peering from  NEU ID TO NEU HUB
module vnetpeerprishubtoid '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-netspk-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetpeerprispkhubid1'
  params: {
    localVnetName: vnetspkidprdpri.outputs.vnetName
    remoteVnetID: vnethubprdpri.id
    remoteVnetName: vnethubprdpri.name
  }
}

module nsgvnetidsnaddsnetwork '../modules/vnet-nsg.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-netspk-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetidsnaddsnetwork'
  params: {
    name: 'nsg-sn-vnet-${customer}-${location.primary.code}-${env}-id1-addsnetwork'
    location: location.primary.name
    tags: tags.prod
    nsgRules: []
  }
}

/////////////////////////////////////
// West Europe ID Spoke
/////////////////////////////////////
module vnetspkidprdsec '../modules/network.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-netspk-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vnetspkid1prdsec'
  params: {
    name: 'vnet-${customer}-${location.secondary.code}-${env}-id1'
    tags: tags.prod
    location: location.secondary.name
    addressPrefixes: '172.29.114.0/23'
    dnsServers: customDnsServers.secondary
    subnets: [
      {
        name: 'ADDSNetwork'
        properties: {
          addressPrefix: '172.29.114.0/24'
          networkSecurityGroup: {
            id: nsgvnetidswaddsnetwork.outputs.nsgid
          }
          routeTable: {
            id: rt_vnetidsec.outputs.rtid
          }
        }
      }
    ]
  }
}

module nsgvnetidswaddsnetwork '../modules/vnet-nsg.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-netspk-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vnetidswaddsnetwork'
  params: {
    name: 'nsg-sn-vnet-${customer}-${location.secondary.code}-${env}-id1-addsnetwork'
    location: location.secondary.name
    tags: tags.prod
    nsgRules: []
  }
}
module rt_vnetidsec '../modules/vnet-routetable.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-netspk-${env}-${location.secondary.code}-01')
  name: '${deploytime}-rt-vnetidsec'
  params: {
    name: 'rt-vnet-${customer}-${location.secondary.code}-${env}-id1'
    tags: tags.prod
    location: location.secondary.name
    routes: spokeneroutes
  }
}

// Get exsisting log
resource loganalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: 'pmglogs001'
  scope: resourceGroup(sub.management_subid, 'rg-mgmt-${env}-${location.primary.code}-01')
}

// Creating VMs in identity_subid in North Europe
module vmaddspri1 '../modules/vm.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-adds-${env}-${location.primary.code}-01')
  name: '${deploytime}-vm-azpriads001'
  params: {
    vmName: 'vm-azneuads001'
    tags: tags.prod
    username: userName
    password: kv.getSecret('addsrecoverypwd')
    subnetId: '${vnetspkidprdpri.outputs.vnetid}/subnets/ADDSNetwork'
    location: location.primary.name
    vmSize: 'Standard_D2as_v4'
    vmzone: '1'
    // Optional code for onboarding to log analytics
    extensionMonitoringAgentConfig: {
      enabled: true
    }
    monitoringWorkspaceId: loganalytics.id
    dataDisks: [
      {
        name: 'vm-azneuads001_data0'
        createOption: 'Attach'
        caching: 'None'
        diskSizeGB: '128'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    ]
  }
}

module vmaddspri2 '../modules/vm.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-adds-${env}-${location.primary.code}-01')
  name: '${deploytime}-vm-azpriads002'
  params: {
    vmName: 'vm-azneuads002'
    tags: tags.prod
    username: userName
    password: kv.getSecret('addsrecoverypwd')
    subnetId: '${vnetspkidprdpri.outputs.vnetid}/subnets/ADDSNetwork'
    location: location.primary.name
    vmSize: 'Standard_D2as_v4'
    vmzone: '2'
    // Optional code for onboarding to log analytics
    extensionMonitoringAgentConfig: {
      enabled: true
    }
    monitoringWorkspaceId: loganalytics.id
    dataDisks: [
      {
        caching: 'None'
        diskSizeGB: '128'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    ]
  }
}

module vmnpspri1 '../modules/vm.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-nps-${env}-${location.primary.code}-01')
  name: '${deploytime}-vm-azprinps001'
  params: {
    vmName: 'vm-azneunps001'
    tags: tags.prod
    username: userName
    password: kv.getSecret('npsadminpwd')
    subnetId: '${vnetspkidprdpri.outputs.vnetid}/subnets/ADDSNetwork'
    location: location.primary.name
    vmSize: 'Standard_D2a_v4'
    vmzone: '1'
    // Optional code for onboarding to log analytics
    extensionMonitoringAgentConfig: {
      enabled: true
    }
    monitoringWorkspaceId: loganalytics.id
  }
}

module vmnpspri2 '../modules/vm.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-nps-${env}-${location.primary.code}-01')
  name: '${deploytime}-vm-azprinps002'
  params: {
    vmName: 'vm-azneunps002'
    tags: tags.prod
    username: userName
    password: kv.getSecret('npsadminpwd')
    subnetId: '${vnetspkidprdpri.outputs.vnetid}/subnets/ADDSNetwork'
    location: location.primary.name
    vmSize: 'Standard_D2a_v4'
    vmzone: '1'
    // Optional code for onboarding to log analytics
    extensionMonitoringAgentConfig: {
      enabled: true
    }
    monitoringWorkspaceId: loganalytics.id
  }
}

module vmnpssec1 '../modules/vm.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-nps-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vm-azsecnps001'
  params: {
    vmName: 'vm-azweunps001'
    tags: tags.prod
    username: userName
    password: kv.getSecret('npsadminpwd')
    subnetId: '${vnetspkidprdsec.outputs.vnetid}/subnets/ADDSNetwork'
    location: location.secondary.name
    vmSize: 'Standard_D2a_v4'
    vmzone: '1'
    // Optional code for onboarding to log analytics
    extensionMonitoringAgentConfig: {
      enabled: true
    }
    monitoringWorkspaceId: loganalytics.id
  }
}

module vmnpssec2 '../modules/vm.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-nps-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vm-azsecnps002'
  params: {
    vmName: 'vm-azweunps002'
    tags: tags.prod
    username: userName
    password: kv.getSecret('npsadminpwd')
    subnetId: '${vnetspkidprdsec.outputs.vnetid}/subnets/ADDSNetwork'
    location: location.secondary.name
    vmSize: 'Standard_D2a_v4'
    vmzone: '1'
    // Optional code for onboarding to log analytics
    extensionMonitoringAgentConfig: {
      enabled: true
    }
    monitoringWorkspaceId: loganalytics.id
  }
}

//Creating VM in identity_subid in West Europe
module vmaddssec1 '../modules/vm.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-adds-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vm-azsecads001'
  params: {
    vmName: 'vm-azweuads001'
    tags: tags.prod
    username: userName
    password: kv.getSecret('addsrecoverypwd')
    subnetId: '${vnetspkidprdsec.outputs.vnetid}/subnets/ADDSNetwork'
    location: location.secondary.name
    vmSize: 'Standard_D2as_v4'
    vmzone: '1'
    // Optional code for onboarding to log analytics
    extensionMonitoringAgentConfig: {
      enabled: true
    }
    monitoringWorkspaceId: loganalytics.id
    dataDisks: [
      {
        caching: 'ReadOnly'
        diskSizeGB: '128'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    ]
  }
}

// Peering from WEU ID TO NEU HUB
module vnetpeersecspkid1hub '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-netspk-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vnetpeersecspkid1hub'
  params: {
    localVnetName: vnetspkidprdsec.outputs.vnetName
    remoteVnetID: vnethubprdpri.id
    remoteVnetName: vnethubprdpri.name
  }
}

// Peering from NEU HUB TO WEU ID
module vnetpeerprihub2secid '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.primary.code}-01')
  name: '${deploytime}-vnetpeerprihub2secid'
  params: {
    localVnetName: vnethubprdpri.name
    remoteVnetID: vnetspkidprdsec.outputs.vnetid
    remoteVnetName: vnetspkidprdsec.outputs.vnetName
  }
}

// Peering from WEU ID TO WEU Hub
module vnetpeersecshubtoid '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.identity_subid, 'rg-netspk-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vnetpeersecspkhubid1'
  params: {
    localVnetName: vnetspkidprdsec.outputs.vnetName
    remoteVnetID: vnethubprdsec.id
    remoteVnetName: vnethubprdsec.name
  }
}

// Peering from WEU HUB TO WEU ID
module vnetpeersechubtosecid '../modules/vnet-peering.bicep' = {
  scope: resourceGroup(sub.connectivity_subid, 'rg-nethub-${env}-${location.secondary.code}-01')
  name: '${deploytime}-vnetpeersecspkhubid1'
  params: {
    localVnetName: vnethubprdsec.name
    remoteVnetID: vnetspkidprdsec.outputs.vnetid
    remoteVnetName: vnetspkidprdsec.outputs.vnetName
  }
}

//Enable backup for NEU VMs 
var rsvprisrg = 'rg-mgmt-${env}-${location.primary.code}-01'
module vmpriidbak '../modules/rsv.bicep' = {
  name: '${deploytime}-backup-vmaddspri1'
  dependsOn: [
    //  vmaddspri1
    vmaddspri2
  ]
  scope: resourceGroup(sub.identity_subid, rsvprisrg)
  params: {
    existingVirtualMachines: [
      // vmaddspri1.outputs.vmname
      vmaddspri2.outputs.vmname
    ]
    tags: tags.prod
    existingVirtualMachinesResourceGroup: vmaddspri2.outputs.resourcegroup
    isNewPolicy: true
    isNewVault: true
    location: location.primary.name
    vaultName: 'rsv-${location.primary.code}'
  }
}

//Enable backup for WEU VMs 
var rsvsecrg = 'rg-mgmt-${env}-${location.secondary.code}-01'
module vmsecidbak '../modules/rsv.bicep' = {
  name: '${deploytime}-backup-vmaddssec1'
  dependsOn: [
    vmaddssec1
  ]
  scope: resourceGroup(sub.identity_subid, rsvsecrg)
  params: {
    existingVirtualMachines: [
      vmaddssec1.outputs.vmname
    ]
    tags: tags.prod
    existingVirtualMachinesResourceGroup: vmaddssec1.outputs.resourcegroup
    isNewPolicy: true
    isNewVault: true
    location: location.secondary.name
    vaultName: 'rsv-${location.secondary.code}'
  }
}
