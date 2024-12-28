# Research Spoke

Deploys a research spoke associated with a previously deployed research hub.

## Table of Contents

[Parameters](#parameters)

[Outputs](#outputs)

[Use the template](#use-the-template)

## Parameters

Parameter name | Required | Description
-------------- | -------- | -----------
[location](#location) | True     | The Azure region where the spoke will be deployed.
[workloadName](#workloadName) | True     | The name of the research project for the spoke.
[environment](#environment) | False    | A maximum four-letter moniker for the environment type, such as 'dev', 'test', etc.
[tags](#tags)  | False    | Tags to apply to each deployed Azure resource.
[sequence](#sequence) | False    | The deployment sequence. Each new sequence number will create a new deployment.
[namingConvention](#namingConvention) | False    | The naming convention to use for Azure resource names. Can contain placeholders for {rtype}, {workloadName}, {location}, {env}, and {seq}. The only supported segment separator is '-'.
[deploymentTime](#deploymentTime) | False    |
[encryptionKeyExpirySeed](#encryptionKeyExpirySeed) | False    | The date and time seed for the expiration of the encryption keys.
[networkAddressSpaces](#networkAddressSpaces) | True     | Format: [ "192.168.0.0/24", "192.168.10.0/24" ]
[hubFirewallIp](#hubFirewallIp) | True     | The private IP address of the hub firewall.
[customDnsIps](#customDnsIps) | False    | The DNS IP addresses to use for the virtual network. Defaults to the hub firewall IP.
[hubVNetResourceId](#hubVNetResourceId) | True     | The Azure resource ID of the hub virtual network to peer with.
[hubPrivateDnsZonesResourceGroupId](#hubPrivateDnsZonesResourceGroupId) | True     | The resource ID of the resource group in the hub subscription where storage account-related private DNS zones live.
[additionalSubnets](#additionalSubnets) | False    | The definition of additional subnets that have been manually created.
[desktopAppGroupFriendlyName](#desktopAppGroupFriendlyName) | False    | Name of the Desktop application group shown to users in the AVD client.
[workspaceFriendlyName](#workspaceFriendlyName) | False    | Name of the Workspace shown to users in the AVD client.
[createPolicyExemptions](#createPolicyExemptions) | False    | If true, will create policy exemptions for resources and policy definitions that are not compliant due to issues with common Azure built-in compliance policy initiatives.
[policyAssignmentId](#policyAssignmentId) | False    | Required if policy exemptions must be created.
[sessionHostLocalAdminUsername](#sessionHostLocalAdminUsername) | False    |
[sessionHostLocalAdminPassword](#sessionHostLocalAdminPassword) | False    |
[logonType](#logonType) | True     | Specifies if logons to virtual machines should use AD or Entra ID.
[domainJoinUsername](#domainJoinUsername) | False    | The username of a domain user or service account to use to join the Active Directory domain. Use UPN notation. Required if using AD join.
[domainJoinPassword](#domainJoinPassword) | False    | The password of the domain user or service account to use to join the Active Directory domain. Required if using AD join.
[filesIdentityType](#filesIdentityType) | True     |
[adDomainFqdn](#adDomainFqdn) | False    | The fully qualified DNS name of the Active Directory domain to join. Required if using AD join.
[adOuPath](#adOuPath) | False    | Optional. The OU path in LDAP notation to use when joining the session hosts.
[storageAccountOuPath](#storageAccountOuPath) | False    | Optional. The OU Path in LDAP notation to use when joining the storage account. Defaults to the same OU as the session hosts.
[sessionHostCount](#sessionHostCount) | False    | Optional. The number of Azure Virtual Desktop session hosts to create in the pool. Defaults to 1.
[sessionHostNamePrefix](#sessionHostNamePrefix) | False    | The prefix used for the computer names of the session host(s). Maximum 11 characters.
[sessionHostSize](#sessionHostSize) | False    | A valid Azure Virtual Machine size. Use `az vm list-sizes --location "<region>"` to retrieve a list for the selected location
[useSessionHostAsResearchVm](#useSessionHostAsResearchVm) | False    | If true, will configure the deployment of AVD to make the AVD session hosts usable as research VMs. This will give full desktop access, flow the AVD traffic through the firewall, etc.
[researcherEntraIdObjectId](#researcherEntraIdObjectId) | True     | Entra ID object ID of the user or group (researchers) to assign permissions to access the AVD application groups and storage.
[adminEntraIdObjectId](#adminEntraIdObjectId) | True     | Entra ID object ID of the admin user or group to assign permissions to administer the AVD session hosts, storage, etc.
[isAirlockReviewCentralized](#isAirlockReviewCentralized) | False    | If true, airlock reviews will take place centralized in the hub. If true, the hub* parameters must be specified also.
[airlockApproverEmail](#airlockApproverEmail) | True     | The email address of the reviewer for this project.
[allowedIngestFileExtensions](#allowedIngestFileExtensions) | False    | The allowed file extensions for ingest.
[centralAirlockStorageAccountId](#centralAirlockStorageAccountId) | True     | The full Azure resource ID of the hub's airlock review storage account.
[centralAirlockFileShareName](#centralAirlockFileShareName) | True     | The file share name for airlock reviews.
[centralAirlockKeyVaultId](#centralAirlockKeyVaultId) | True     | The name of the Key Vault in the research hub containing the airlock review storage account's connection string as a secret.
[publicStorageAccountAllowedIPs](#publicStorageAccountAllowedIPs) | False    | The list of allowed IP addresses or ranges for ingest and approved export pickup purposes.
[complianceTarget](#complianceTarget) | False    | The Azure built-in regulatory compliance framework to target. This will affect whether or not customer-managed keys, private endpoints, etc. are used. This will *not* deploy a policy assignment.
[hubManagementVmId](#hubManagementVmId) | False    |
[hubManagementVmUamiPrincipalId](#hubManagementVmUamiPrincipalId) | False    |
[hubManagementVmUamiClientId](#hubManagementVmUamiClientId) | False    |
[debugMode](#debugMode) | False    |
[debugRemoteIp](#debugRemoteIp) | False    |
[debugPrincipalId](#debugPrincipalId) | False    | The object ID of the user or group to assign permissions. Only used when `debugMode = true`.

### location

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The Azure region where the spoke will be deployed.

Metadata | Value
---- | ----
Type | string

### workloadName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The name of the research project for the spoke.

Metadata | Value
---- | ----
Type | string

### environment

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

A maximum four-letter moniker for the environment type, such as 'dev', 'test', etc.

Metadata | Value
---- | ----
Type | string
Default value | `dev`
Allowed values | `dev`, `test`, `demo`, `prod`
Maximum length | 4

### tags

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Tags to apply to each deployed Azure resource.

Metadata | Value
---- | ----
Type | object
Default value | ``

### sequence

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The deployment sequence. Each new sequence number will create a new deployment.

Metadata | Value
---- | ----
Type | int
Default value | `1`

### namingConvention

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The naming convention to use for Azure resource names. Can contain placeholders for {rtype}, {workloadName}, {location}, {env}, and {seq}. The only supported segment separator is '-'.

Metadata | Value
---- | ----
Type | string
Default value | `{workloadName}-{subWorkloadName}-{env}-{rtype}-{loc}-{seq}`

### deploymentTime

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Metadata | Value
---- | ----
Type | string
Default value | `[utcNow()]`

### encryptionKeyExpirySeed

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The date and time seed for the expiration of the encryption keys.

Metadata | Value
---- | ----
Type | string
Default value | `[utcNow()]`

### networkAddressSpaces

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Format: [ "192.168.0.0/24", "192.168.10.0/24" ]

Metadata | Value
---- | ----
Type | array
Minimum length | 1

### hubFirewallIp

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The private IP address of the hub firewall.

Metadata | Value
---- | ----
Type | string

### customDnsIps

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The DNS IP addresses to use for the virtual network. Defaults to the hub firewall IP.

Metadata | Value
---- | ----
Type | array
Default value | `[parameters('hubFirewallIp')]`

### hubVNetResourceId

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The Azure resource ID of the hub virtual network to peer with.

Metadata | Value
---- | ----
Type | string

### hubPrivateDnsZonesResourceGroupId

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The resource ID of the resource group in the hub subscription where storage account-related private DNS zones live.

Metadata | Value
---- | ----
Type | string

### additionalSubnets

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The definition of additional subnets that have been manually created.

Metadata | Value
---- | ----
Type | array
Default value | `()`

### desktopAppGroupFriendlyName

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Name of the Desktop application group shown to users in the AVD client.

Metadata | Value
---- | ----
Type | string
Default value | `N/A`

### workspaceFriendlyName

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Name of the Workspace shown to users in the AVD client.

Metadata | Value
---- | ----
Type | string
Default value | `N/A`

### createPolicyExemptions

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

If true, will create policy exemptions for resources and policy definitions that are not compliant due to issues with common Azure built-in compliance policy initiatives.

Metadata | Value
---- | ----
Type | bool
Default value | `false`

### policyAssignmentId

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Required if policy exemptions must be created.

Metadata | Value
---- | ----
Type | string
Default value | `''`

### sessionHostLocalAdminUsername

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Metadata | Value
---- | ----
Type | securestring
Default value | `''`

### sessionHostLocalAdminPassword

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Metadata | Value
---- | ----
Type | securestring
Default value | `''`

### logonType

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Specifies if logons to virtual machines should use AD or Entra ID.

Metadata | Value
---- | ----
Type | string
Allowed values | `ad`, `entraID`

### domainJoinUsername

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The username of a domain user or service account to use to join the Active Directory domain. Use UPN notation. Required if using AD join.

Metadata | Value
---- | ----
Type | securestring
Default value | `''`

### domainJoinPassword

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The password of the domain user or service account to use to join the Active Directory domain. Required if using AD join.

Metadata | Value
---- | ----
Type | securestring
Default value | `''`

### filesIdentityType

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Metadata | Value
---- | ----
Type | string
Allowed values | `AADKERB`, `AADDS`, `None`

### adDomainFqdn

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The fully qualified DNS name of the Active Directory domain to join. Required if using AD join.

Metadata | Value
---- | ----
Type | string
Default value | `''`

### adOuPath

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Optional. The OU path in LDAP notation to use when joining the session hosts.

Metadata | Value
---- | ----
Type | string
Default value | `''`

### storageAccountOuPath

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Optional. The OU Path in LDAP notation to use when joining the storage account. Defaults to the same OU as the session hosts.

Metadata | Value
---- | ----
Type | string
Default value | `[parameters('adOuPath')]`

### sessionHostCount

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Optional. The number of Azure Virtual Desktop session hosts to create in the pool. Defaults to 1.

Metadata | Value
---- | ----
Type | int
Default value | `1`

### sessionHostNamePrefix

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The prefix used for the computer names of the session host(s). Maximum 11 characters.

Metadata | Value
---- | ----
Type | string
Default value | `N/A`
Maximum length | 11

### sessionHostSize

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

A valid Azure Virtual Machine size. Use `az vm list-sizes --location "<region>"` to retrieve a list for the selected location

Metadata | Value
---- | ----
Type | string
Default value | `N/A`

### useSessionHostAsResearchVm

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

If true, will configure the deployment of AVD to make the AVD session hosts usable as research VMs. This will give full desktop access, flow the AVD traffic through the firewall, etc.

Metadata | Value
---- | ----
Type | bool
Default value | `True`

### researcherEntraIdObjectId

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Entra ID object ID of the user or group (researchers) to assign permissions to access the AVD application groups and storage.

Metadata | Value
---- | ----
Type | string

### adminEntraIdObjectId

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Entra ID object ID of the admin user or group to assign permissions to administer the AVD session hosts, storage, etc.

Metadata | Value
---- | ----
Type | string

### isAirlockReviewCentralized

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

If true, airlock reviews will take place centralized in the hub. If true, the hub* parameters must be specified also.

Metadata | Value
---- | ----
Type | bool
Default value | `false`

### airlockApproverEmail

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The email address of the reviewer for this project.

Metadata | Value
---- | ----
Type | string

### allowedIngestFileExtensions

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The allowed file extensions for ingest.

Metadata | Value
---- | ----
Type | array
Default value | `()`

### centralAirlockStorageAccountId

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The full Azure resource ID of the hub's airlock review storage account.

Metadata | Value
---- | ----
Type | string

### centralAirlockFileShareName

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The file share name for airlock reviews.

Metadata | Value
---- | ----
Type | string

### centralAirlockKeyVaultId

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

The name of the Key Vault in the research hub containing the airlock review storage account's connection string as a secret.

Metadata | Value
---- | ----
Type | string

### publicStorageAccountAllowedIPs

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The list of allowed IP addresses or ranges for ingest and approved export pickup purposes.

Metadata | Value
---- | ----
Type | array
Default value | `()`

### complianceTarget

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The Azure built-in regulatory compliance framework to target. This will affect whether or not customer-managed keys, private endpoints, etc. are used. This will *not* deploy a policy assignment.

Metadata | Value
---- | ----
Type | string
Default value | `NIST80053R5`
Allowed values | `NIST80053R5`, `HIPAAHITRUST`, `CMMC2L2`, `NIST800171R2`

### hubManagementVmId

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Metadata | Value
---- | ----
Type | string
Default value | `''`

### hubManagementVmUamiPrincipalId

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Metadata | Value
---- | ----
Type | string
Default value | `''`

### hubManagementVmUamiClientId

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Metadata | Value
---- | ----
Type | string
Default value | `''`

### debugMode

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Metadata | Value
---- | ----
Type | bool
Default value | `false`

### debugRemoteIp

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Metadata | Value
---- | ----
Type | string
Default value | `''`

### debugPrincipalId

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The object ID of the user or group to assign permissions. Only used when `debugMode = true`.

Metadata | Value
---- | ----
Type | string
Default value | `[deployer().objectId]`

## Outputs

Name | Type | Description
---- | ---- | -----------
recoveryServicesVaultId | string | The Azure resource ID of the spoke's Recovery Services Vault. Used in service module templates to add additional resources to the vault.
vmBackupPolicyName | string |
diskEncryptionSetId | string |
computeSubnetId | string |
computeResourceGroupName | string |
shortcutTargetPath | string |

## Use the template

### PowerShell

`./deploy.ps1 -TemplateParameterFile './main.prj.bicepparam' -TargetSubscriptionId '00000000-0000-0000-0000-000000000000' -Location 'eastus'`
