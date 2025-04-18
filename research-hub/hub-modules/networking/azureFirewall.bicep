param firewallSubnetId string
@description('The Azure resource ID of the management subnet for a Basic firewall or for a firewall with forced tunneling.')
param firewallManagementSubnetId string = ''

param forcedTunneling bool = false

param namingStructure string
param tags object

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param firewallTier string = 'Basic'

param location string = resourceGroup().location

param includeActiveDirectoryRules bool = false
param includeDnsRules bool = false
param includeManagementSubnetRules bool = false
param dnsServerIPAddresses array = []
param domainControllerIPAddresses array = []
param managementSubnetIPGroupId string = ''
param ipAddressPoolIPGroupId string
param logIngestFqdnPrefix string

var createManagementIPConfiguration = (firewallTier == 'Basic' || forcedTunneling)
// Basic Firewall AND not forced tunneling requires two public IP addresses
var publicIpCount = (firewallTier == 'Basic' && !forcedTunneling) ? 2 : 1

// Create the public IP address(es) for the Firewall
resource firewallPublicIps 'Microsoft.Network/publicIPAddresses@2022-09-01' = [
  for i in range(0, publicIpCount): {
    name: replace(namingStructure, '{rtype}', 'pip-fw${i}')
    location: location
    sku: {
      name: 'Standard'
    }
    properties: {
      publicIPAddressVersion: 'IPv4'
      publicIPAllocationMethod: 'Static'
    }
    zones: pickZones('Microsoft.Network', 'publicIPAddresses', location, 3)
    tags: tags
  }
]

// Create firewall policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-01-01' = {
  name: replace(namingStructure, '{rtype}', 'fwpol')
  location: location
  properties: {
    sku: {
      tier: firewallTier
    }

    // Do not SNAT when in forced tunneling mode
    snat: forcedTunneling
      ? {
          autoLearnPrivateRanges: 'Disabled'
          privateRanges: ['0.0.0.0/0']
        }
      : {}

    dnsSettings: firewallTier != 'Basic'
      ? {
          enableProxy: true
          requireProxyForNetworkRules: true
          servers: dnsServerIPAddresses
        }
      : null
  }

  tags: tags
}

// LATER: Organize rule collection groups with most frequently used rule groups first
var defaultRuleCollectionGroups = {
  AVDRDWeb: {
    rules: json(replace(
      loadTextContent('../../azure-firewall-rules/AVDRDWeb.jsonc'),
      '{{ipAddressPool}}',
      ipAddressPoolIPGroupId
    ))
    priority: 100
  }
  ManagedDevices: {
    rules: json(replace(
      loadTextContent('../../azure-firewall-rules/EntraManagedDevices.jsonc'),
      '{{ipAddressPool}}',
      ipAddressPoolIPGroupId
    ))[az.environment().name]
    priority: 300
  }
  WindowsClient: {
    rules: json(replace(
      loadTextContent('../../azure-firewall-rules/WindowsClient.jsonc'),
      '{{ipAddressPool}}',
      ipAddressPoolIPGroupId
    ))
    priority: 400
  }
  AVD: {
    rules: json(replace(
      loadTextContent('../../azure-firewall-rules/AVD.jsonc'),
      '{{ipAddressPool}}',
      ipAddressPoolIPGroupId
    ))[az.environment().name]
    priority: 500
  }
  Office365Activation: {
    rules: json(replace(
      loadTextContent('../../azure-firewall-rules/Microsoft365Activation.jsonc'),
      '{{ipAddressPool}}',
      ipAddressPoolIPGroupId
    ))[az.environment().name]
    priority: 700
  }
  ResearchDataSources: {
    rules: loadJsonContent('../../azure-firewall-rules/ResearchDataSources.jsonc')
    priority: 600
  }
  Backup: {
    rules: json(replace(
      loadTextContent('../../azure-firewall-rules/AzureBackup.jsonc'),
      '{{ipAddressPool}}',
      ipAddressPoolIPGroupId
    ))
    priority: 800
  }
  AzurePlatform: {
    rules: json(replace(
      replace(
        replace(
          loadTextContent('../../azure-firewall-rules/AzurePlatform.jsonc'),
          '{{ipAddressPool}}',
          ipAddressPoolIPGroupId
        ),
        '{{logAnalyticsWorkspaceId}}',
        logIngestFqdnPrefix
      ),
      '{{vmRegionName}}',
      location
    ))[az.environment().name]
    priority: 1000
  }
}

var activeDirectoryRuleCollectionGroup = includeActiveDirectoryRules && length(domainControllerIPAddresses) > 0
  ? {
      ActiveDirectory: {
        rules: json(replace(
          replace(
            loadTextContent('../../azure-firewall-rules/ActiveDirectory.jsonc'),
            '"{{domainControllerIPAddresses}}"',
            string(domainControllerIPAddresses)
          ),
          '{{ipAddressPool}}',
          ipAddressPoolIPGroupId
        ))
        priority: 250
      }
    }
  : {}

var dnsRuleCollectionGroup = includeDnsRules && length(dnsServerIPAddresses) > 0
  ? {
      DNS: {
        rules: json(replace(
          replace(
            loadTextContent('../../azure-firewall-rules/CustomDns.jsonc'),
            '"{{dnsServerAddresses}}"',
            string(dnsServerIPAddresses)
          ),
          '{{ipAddressPool}}',
          ipAddressPoolIPGroupId
        ))
        priority: 150
      }
    }
  : {}

var managementSubnetRuleCollectionGroup = includeManagementSubnetRules && length(managementSubnetIPGroupId) > 0
  ? {
      ManagementSubnet: {
        rules: json(replace(
          loadTextContent('../../azure-firewall-rules/ManagementSubnet.jsonc'),
          // TODO: Create IP Group for the management subnet
          '{{managementSubnetRange}}',
          managementSubnetIPGroupId
        ))
        priority: 350
      }
    }
  : {}

var ruleCollectionGroupsAll = union(
  defaultRuleCollectionGroups,
  activeDirectoryRuleCollectionGroup,
  dnsRuleCollectionGroup,
  managementSubnetRuleCollectionGroup
)

// LATER: Divide into optional rule collections: AzurePlatform, AVDRDWeb (rename!), ResearchDataSources (?)

@batchSize(1) // Do not process more than one rule collection group at a time
resource ruleCollectionGroups 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-07-01' = [
  for group in items(ruleCollectionGroupsAll): {
    name: group.key
    parent: firewallPolicy
    properties: {
      priority: group.value.priority
      ruleCollections: group.value.rules
    }
  }
]

// In forced tunneling mode, there is only one public IP address, for the Management interface
// (Cannot reference the public IP address directly, as ARM wants both 0 and 1 index to exist when doing so)
var managementIPConfigPublicIPIndex = forcedTunneling ? 0 : 1

// Create Azure Firewall resource
resource firewall 'Microsoft.Network/azureFirewalls@2022-01-01' = {
  name: replace(namingStructure, '{rtype}', 'fw')
  location: location

  properties: {
    ipConfigurations: [
      {
        name: replace(namingStructure, '{rtype}', 'fwip')
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          // If forced tunneling is enabled, the public IP address is not needed
          publicIPAddress: !forcedTunneling
            ? {
                id: firewallPublicIps[0].id
              }
            : null
        }
      }
    ]
    managementIpConfiguration: createManagementIPConfiguration
      ? {
          name: replace(namingStructure, '{rtype}', 'fwmgtip')
          properties: {
            publicIPAddress: {
              id: firewallPublicIps[managementIPConfigPublicIPIndex].id
            }
            subnet: {
              id: firewallManagementSubnetId
            }
          }
        }
      : null

    firewallPolicy: {
      id: firewallPolicy.id
    }

    sku: {
      name: 'AZFW_VNet'
      tier: firewallTier
    }
  }

  zones: pickZones('Microsoft.Network', 'azureFirewalls', location, 3)

  tags: tags

  // This dependency is added manually because otherwise the FW will try to deploy before the rule collections are ready
  dependsOn: [ruleCollectionGroups]
}

output fwPrIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
