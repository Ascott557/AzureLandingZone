param name string 
param location string = 'northeurope'
param tags object
param activeActive bool = false
param enableBgp bool = false
param enableBgpRouteTranslationForNat bool = false
param enableDnsForwarding bool = false
param enablePrivateIpAddress bool = false
param gatewayType string = 'Vpn'
param privateIPAllocationMethod string = 'Dynamic'
param gwSubnetId string
param natRules array = []
param gwSKU string = 'VpnGw1'

@allowed([
  'Generation1'
  'Generation2'
  'None'
])
param vpnGatewayGeneration string = 'Generation1'

@allowed([
  'PolicyBased'
  'RouteBased'
])
param vpnType string = 'RouteBased'

@allowed([
  'Basic'
  'Standard'
])
param pipSKU string = 'Basic'

@allowed([
  'Global'
  'Regional'
])
param pipTier string = 'Regional'




resource vpngw 'Microsoft.Network/virtualNetworkGateways@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    activeActive: activeActive
    enableBgp: enableBgp
    enableBgpRouteTranslationForNat: enableBgpRouteTranslationForNat
    enableDnsForwarding: enableDnsForwarding
    enablePrivateIpAddress: enablePrivateIpAddress
    gatewayType: gatewayType
    ipConfigurations: [
      {
        name: pip.name
        properties: {
          privateIPAllocationMethod: privateIPAllocationMethod
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: gwSubnetId
          }
        }
      }
    ]
    natRules: natRules
    sku: {
      name: gwSKU
      tier: gwSKU
    }
    
    vpnGatewayGeneration: vpnGatewayGeneration
    vpnType: vpnType
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'pip-${name}'
  location: location
  tags: tags
  sku: {
    name: pipSKU
    tier: pipTier
  }
}
