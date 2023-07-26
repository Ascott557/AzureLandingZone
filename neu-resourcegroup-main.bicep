param customer string
param tenantId string
param deploytime string = utcNow('MMMM-dd-yyyy-H-mm-ss')
param env string
param location object 
param sub object 
param secretname string
@secure()
param secretvalue string

targetScope = 'subscription'

@description('Tags to be applied on Azure resources based on environment')
var tags = loadJsonContent('shared-tags.json')

//Deploying resource groups in Primary location for connectivity
module rgprinethub '../modules/resourcegroup.bicep' = {
  scope: subscription(sub.connectivity_subid)
  name: '${deploytime}-rgprinethub'
  params: {
    name: 'rg-nethub-${env}-${location.primary.code}-01'
    location: location.primary.name
    tags: tags.prod
  }
}
module rgprinetspkss '../modules/resourcegroup.bicep' = {
  scope: subscription(sub.sharedservices_subid)
  name: '${deploytime}-rgprinetspkss'
  params: {
    name: 'rg-netspk-${env}-${location.primary.code}-01'
    location: location.primary.name
    tags: tags.prod

  }
}

//Deploying resource groups in Secondary Location for connectivity
module rgsecnethub '../modules/resourcegroup.bicep' = {
  scope: subscription(sub.connectivity_subid)
  name: '${deploytime}-rgsecnethub'
  params: {
    name: 'rg-nethub-${env}-${location.secondary.code}-01'
    location: location.secondary.name
    tags: tags.prod
  }
}
module rgsecnetspkss '../modules/resourcegroup.bicep' = {
  scope: subscription(sub.sharedservices_subid)
  name: '${deploytime}-rgsecnetspkss'
  params: {
    name: 'rg-netspk-${env}-${location.secondary.code}-01'
    location: location.secondary.name
    tags: tags.prod

  }
}

//Deploying resource groups in North Europe for management
module rgprimgmt '../modules/resourcegroup.bicep' = {
  scope: subscription(sub.alz1_subid)
  name: '${deploytime}-rgprimgmt'
  params: {
    name: 'rg-mgmt-${env}-${location.primary.code}-01'
    location: location.primary.name
    tags: tags.prod
  }
}

//Deploying resource groups in North Europe for sharedservices
module rgpriss1 '../modules/resourcegroup.bicep' = {
  scope: subscription(sub.sharedservices_subid)
  name: '${deploytime}-rgpriss1'
  params: {
    name: 'rg-mgmt-${env}-${location.primary.code}-01'
    location: location.primary.name
    tags: tags.prod
  }
}

module rgpriss2 '../modules/resourcegroup.bicep' = {
  scope: subscription(sub.sharedservices_subid)
  name: '${deploytime}-rgpriss2'
  params: {
    name: 'rg-epma-${env}-${location.primary.code}-01'
    location: location.primary.name
    tags: tags.prod
  }
}
