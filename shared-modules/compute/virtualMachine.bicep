param virtualMachineName string
param location string = resourceGroup().location
param vmSize string
@description('The operating system\'s host name.')
param vmHostName string
@secure()
param vmLocalAdminUsername string
@secure()
param vmLocalAdminPassword string
param diskEncryptionSetId string = ''
param imageReference object
param nicId string
param uamiId string = ''
param identityType identity
param availabilitySetId string = ''

param deploymentNameStructure string

@description('Required when logonType is "ad".')
param domainJoinInfo activeDirectoryDomainInfo = {
  domainJoinPassword: ''
  domainJoinUsername: ''
  adDomainFqdn: ''
  adOuPath: ''
}

@allowed(['ad', 'entraID'])
param logonType string

@allowed(['Windows', 'Linux'])
param osType string = 'Windows'
param intuneEnrollment bool

// Do not backup by default
param backupPolicyName string = ''
param recoveryServicesVaultId string = ''

param tags object

import { activeDirectoryDomainInfo } from '../types/activeDirectoryDomainInfo.bicep'
import { identity } from '../types/identity.bicep'

var intuneMdmId = '0000000a-0000-0000-c000-000000000000'

// This tag will direct Guest Configuration to use the Azure virtual IP for compliance updates,
// rather than public endpoints of various storage accounts.
var actualVmTags = union(tags, { EnablePrivateNetworkGC: 'TRUE' })

// TODO: Move NIC creation to this module

// Create the virtual machine resource
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachineName
  location: location
  tags: actualVmTags
  properties: {
    // TODO: Consider adding licenseType: 'Windows_Client' (when using default image)
    // LATER: Support for hibernation: additionalCapabilities: { hibernationEnabled: }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmHostName
      adminUsername: vmLocalAdminUsername
      adminPassword: vmLocalAdminPassword
      windowsConfiguration: osType == 'Windows'
        ? {
            // LATER: If leveraging Azure Update Manager, configure for compatibility
            enableAutomaticUpdates: true
          }
        : null
    }
    securityProfile: {
      encryptionAtHost: true
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        osType: osType
        managedDisk: {
          // TODO: Make a parameter
          storageAccountType: 'StandardSSD_LRS'
          diskEncryptionSet: !empty(diskEncryptionSetId)
            ? {
                id: diskEncryptionSetId
              }
            : null
        }
      }
      imageReference: imageReference
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    availabilitySet: !empty(availabilitySetId)
      ? {
          id: availabilitySetId
        }
      : null
  }
  identity: {
    type: identityType
    userAssignedIdentities: !empty(uamiId)
      ? {
          '${uamiId}': {}
        }
      : null
  }
}

// HACK: 2024-07-05: .cloud TLDs (and maybe some others?) don't work by default due to reddog.microsoft.com as the DNS suffix for the connection
// Set the computer's primary DNS suffix to the AD domain FQDN
resource primaryDnsSuffixExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (logonType == 'ad' && endsWith(
  domainJoinInfo.adDomainFqdn,
  '.cloud'
)) {
  name: 'SetPrimaryDnsSuffixScript'
  parent: virtualMachine
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'wmic nicconfig call SetDNSSuffixSearchOrder ${domainJoinInfo.adDomainFqdn}'
    }
  }
}

// Entra ID join, if specified
resource entraIDJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (logonType == 'entraID') {
  name: 'EntraIDJoin'
  parent: virtualMachine
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: intuneEnrollment
      ? {
          mdmId: intuneMdmId
        }
      : null
  }
  dependsOn: [windowsGuestAttestationExtension, windowsVMGuestConfigExtension, antimalwareExtension]
}

// Domain join the session hosts to Active Directory, if specified
resource domainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = if (logonType == 'ad') {
  name: 'DomainJoin'
  parent: virtualMachine
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainJoinInfo.adDomainFqdn
      ouPath: domainJoinInfo.adOuPath
      user: domainJoinInfo.domainJoinUsername
      restart: 'true'
      options: '3'
    }
    protectedSettings: {
      password: domainJoinInfo.domainJoinPassword
    }
  }
  dependsOn: [
    primaryDnsSuffixExtension
    windowsGuestAttestationExtension
    windowsVMGuestConfigExtension
    antimalwareExtension
  ]
}

// Deploy Windows Attestation, for boot integrity monitoring
resource windowsGuestAttestationExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: 'WindowsGuestAttestation'
  parent: virtualMachine
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Security.WindowsAttestation'
    type: 'GuestAttestation'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: ''
          maaTenantName: 'GuestAttestation'
        }
        AscSettings: {
          ascReportingEndpoint: ''
          ascReportingFrequency: ''
        }
        useCustomToken: false
        disableAlerts: false
      }
    }
  }
}

// Deploy the Windows VM Guest Configuration extension which is required for most regulatory compliance initiatives
resource windowsVMGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: 'AzurePolicyforWindows'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
    protectedSettings: {}
  }
}

var rsvRgName = !empty(recoveryServicesVaultId) ? split(recoveryServicesVaultId, '/')[4] : ''

// Create a backup item for each session host
// This must be deployed in a separate module because it's in a different resource group
module backupItems '../recovery/rsvProtectedItem-vm.bicep' = if (!empty(backupPolicyName) && !empty(recoveryServicesVaultId)) {
  name: replace(deploymentNameStructure, '{rtype}', '${vmHostName}-backup')
  scope: resourceGroup(rsvRgName)
  params: {
    backupPolicyName: backupPolicyName
    recoveryServicesVaultId: recoveryServicesVaultId
    virtualMachineId: virtualMachine.id
  }

  dependsOn: [entraIDJoinExtension, domainJoinExtension]
}

// Install IaaSAntimalware extension
resource antimalwareExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: 'IaaSAntimalware'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      AntimalwareEnabled: true
      RealtimeProtectionEnabled: true
      ScheduledScanSettings: {
        isEnabled: true
        scanType: 'Quick'
        day: '7'
        time: '120'
      }
    }
  }
}

// LATER: Deploy NVIDIA or AMD drivers if needed, based on vmSize

output id string = virtualMachine.id
