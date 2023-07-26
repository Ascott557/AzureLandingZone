param localVnetName string
param remoteVnetName string
param remoteVnetID string
param allowVirtualNetworkAccess bool = true
param allowForwardedTraffic bool = true
param allowGatewayTransit bool = false
param useRemoteGateways bool = false

resource peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: '${localVnetName}/peering-to-${remoteVnetName}'
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnetID
    }
  }
}
