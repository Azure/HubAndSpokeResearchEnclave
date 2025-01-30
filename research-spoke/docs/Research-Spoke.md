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
[workloadName](#workloadname) | True     | The name of the research project for the spoke.
[environment](#environment) | False    | A maximum four-letter moniker for the environment type, such as 'dev', 'test', etc.
[tags](#tags)  | False    | Tags to apply to each deployed Azure resource.
[sequence](#sequence) | False    | The deployment sequence. Each new sequence number will create a new deployment.
[namingConvention](#namingconvention) | False    | The naming convention to use for Azure resource names. Can contain placeholders for {rtype}, {workloadName}, {location}, {env}, and {seq}. The only supported segment separator is '-'.
[deploymentTime](#deploymenttime) | False    | Do not specify. Date and time will be used to create unique deployment names.
[encryptionKeyExpirySeed](#encryptionkeyexpiryseed) | False    | The date and time seed for the expiration of the encryption keys.
[networkAddressSpaces](#networkaddressspaces) | True     | Format: `[ "192.168.0.0/24", "192.168.10.0/24" ]`
[hubFirewallIp](#hubfirewallip) | True     | The private IP address of the hub firewall.
[customDnsIps](#customdnsips) | False    | The DNS IP addresses to use for the virtual network. Defaults to the hub firewall IP.
[hubVNetResourceId](#hubvnetresourceid) | True     | The Azure resource ID of the hub virtual network to peer with.
[hubPrivateDnsZonesResourceGroupId](#hubprivatednszonesresourcegroupid) | True     | The resource ID of the resource group in the hub subscription where storage account-related private DNS zones live.
[additionalSubnets](#additionalsubnets) | False    | The definition of additional subnets that have been manually created.
[desktopAppGroupFriendlyName](#desktopappgroupfriendlyname) | False    | Name of the Desktop application group shown to users in the AVD client.
[workspaceFriendlyName](#workspacefriendlyname) | False    | Name of the Workspace shown to users in the AVD client.
[createPolicyExemptions](#createpolicyexemptions) | False    | Experimental. If true, will create policy exemptions for resources and policy definitions that are not compliant due to issues with common Azure built-in compliance policy initiatives.
[policyAssignmentId](#policyassignmentid) | False    | Required if policy exemptions must be created.
[sessionHostLocalAdminUsername](#sessionhostlocaladminusername) | False    | The username for the local user account on the session hosts. Required if when deploying AVD session hosts in the hub (`useSessionHostAsResearchVm = false`).
[sessionHostLocalAdminPassword](#sessionhostlocaladminpassword) | False    | The password for the local user account on the session hosts. Required if when deploying AVD session hosts in the hub (`useSessionHostAsResearchVm = false`).
[logonType](#logontype) | True     | Specifies if logons to virtual machines should use AD or Entra ID.
[domainJoinUsername](#domainjoinusername) | False    | The username of a domain user or service account to use to join the Active Directory domain. Use UPN notation. Required if using AD join.
[domainJoinPassword](#domainjoinpassword) | False    | The password of the domain user or service account to use to join the Active Directory domain. Required if using AD join.
[filesIdentityType](#filesidentitytype) | True     | The identity type to use for Azure Files. Use `AADKERB` for Entra ID Kerberos, `AADDS` for Entra Domain Services, or `None` for ADDS.
[adDomainFqdn](#addomainfqdn) | False    | The fully qualified DNS name of the Active Directory domain to join. Required if using AD join.
[adOuPath](#adoupath) | False    | Optional. The OU path in LDAP notation to use when joining the session hosts.
[storageAccountOuPath](#storageaccountoupath) | False    | Optional. The OU Path in LDAP notation to use when joining the storage account. Defaults to the same OU as the session hosts.
[sessionHostCount](#sessionhostcount) | False    | Optional. The number of Azure Virtual Desktop session hosts to create in the pool. Defaults to 1.
[sessionHostNamePrefix](#sessionhostnameprefix) | False    | The prefix used for the computer names of the session host(s). Maximum 11 characters.
[sessionHostSize](#sessionhostsize) | False    | A valid Azure Virtual Machine size. Use `az vm list-sizes --location "<region>"` to retrieve a list for the selected location
[useSessionHostAsResearchVm](#usesessionhostasresearchvm) | False    | If true, will configure the deployment of AVD to make the AVD session hosts usable as research VMs. This will give full desktop access, flow the AVD traffic through the firewall, etc.
[researcherEntraIdObjectId](#researcherentraidobjectid) | True     | Entra ID object ID of the user or group (researchers) to assign permissions to access the AVD application groups and storage.
[adminEntraIdObjectId](#adminentraidobjectid) | True     | Entra ID object ID of the admin user or group to assign permissions to administer the AVD session hosts, storage, etc.
[isAirlockReviewCentralized](#isairlockreviewcentralized) | False    | If true, airlock reviews will take place centralized in the hub. If true, the hub* parameters must be specified also.
[airlockApproverEmail](#airlockapproveremail) | True     | The email address of the reviewer for this project.
[allowedIngestFileExtensions](#allowedingestfileextensions) | False    | The allowed file extensions for ingest.
[centralAirlockStorageAccountId](#centralairlockstorageaccountid) | True     | The full Azure resource ID of the hub's airlock review storage account.
[centralAirlockFileShareName](#centralairlockfilesharename) | True     | The file share name for airlock reviews.
[centralAirlockKeyVaultId](#centralairlockkeyvaultid) | True     | The name of the Key Vault in the research hub containing the airlock review storage account's connection string as a secret.
[publicStorageAccountAllowedIPs](#publicstorageaccountallowedips) | False    | The list of allowed IP addresses or ranges for ingest and approved export pickup purposes.
[complianceTarget](#compliancetarget) | False    | The Azure built-in regulatory compliance framework to target. This will affect whether or not customer-managed keys, private endpoints, etc. are used. This will *not* deploy any policy assignments.
[vmSchedulePolicy](#vmschedulepolicy) | False    | The backup schedule policy for virtual machines. Defaults to every four hours starting at midnight each day. Refer to the type definitions at [https://learn.microsoft.com/azure/templates/microsoft.recoveryservices/vaults/backuppolicies?pivots=deployment-language-bicep#schedulepolicy-objects](https://learn.microsoft.com/azure/templates/microsoft.recoveryservices/vaults/backuppolicies?pivots=deployment-language-bicep#schedulepolicy-objects).
[fileShareSchedulePolicy](#fileshareschedulepolicy) | False    | The backup schedule policy for Azure File Shares. Defaults to daily at the retention time. Refer to the type definitions at [https://learn.microsoft.com/azure/templates/microsoft.recoveryservices/vaults/backuppolicies?pivots=deployment-language-bicep#schedulepolicy-objects](https://learn.microsoft.com/azure/templates/microsoft.recoveryservices/vaults/backuppolicies?pivots=deployment-language-bicep#schedulepolicy-objects).
[backupSchedulePolicyTimeZone](#backupschedulepolicytimezone) | False    | The time zone to use for the backup schedule policy.
[retentionBackupTime](#retentionbackuptime) | False    | In case of Hourly backup schedules, this retention time must be set to the time of one of the hourly backups.
[hubManagementVmId](#hubmanagementvmid) | False    | The Azure resource ID of the management VM in the hub. Required if using AD join for Azure Files (`filesIdentityType = 'None'`). This value is output by the hub deployment.
[hubManagementVmUamiPrincipalId](#hubmanagementvmuamiprincipalid) | False    | The Entra ID object ID of the user-assigned managed identity of the management VM. This will be given the necessary role assignment to perform a domain join on the storage account(s). Required if using AD join for Azure Files (`filesIdentityType = 'None'`). This value is output by the hub deployment.
[hubManagementVmUamiClientId](#hubmanagementvmuamiclientid) | False    | The client ID of the user-assigned managed identity of the management VM. Required if using AD join for Azure Files (`filesIdentityType = 'None'`). This value is output by the hub deployment.
[debugMode](#debugmode) | False    | Set to `true` to enable debug mode of the spoke. Debug mode will allow remote access to storage, etc. Should be not be used for production deployments.
[debugRemoteIp](#debugremoteip) | False    | Used when `debugMode = true`. The IP address to allow access to storage, Key Vault, etc.
[debugPrincipalId](#debugprincipalid) | False    | The object ID of the user or group to assign permissions. Only used when `debugMode = true`.

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

Do not specify. Date and time will be used to create unique deployment names.

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

Format: `[ "192.168.0.0/24", "192.168.10.0/24" ]`

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

Experimental. If true, will create policy exemptions for resources and policy definitions that are not compliant due to issues with common Azure built-in compliance policy initiatives.

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

The username for the local user account on the session hosts. Required if when deploying AVD session hosts in the hub (`useSessionHostAsResearchVm = false`).

Metadata | Value
---- | ----
Type | securestring
Default value | `''`

### sessionHostLocalAdminPassword

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The password for the local user account on the session hosts. Required if when deploying AVD session hosts in the hub (`useSessionHostAsResearchVm = false`).

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

The identity type to use for Azure Files. Use `AADKERB` for Entra ID Kerberos, `AADDS` for Entra Domain Services, or `None` for ADDS.

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

The Azure built-in regulatory compliance framework to target. This will affect whether or not customer-managed keys, private endpoints, etc. are used. This will *not* deploy any policy assignments.

Metadata | Value
---- | ----
Type | string
Default value | `NIST80053R5`
Allowed values | `NIST80053R5`, `HIPAAHITRUST`, `CMMC2L2`, `NIST800171R2`

### vmSchedulePolicy

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The backup schedule policy for virtual machines. Defaults to every four hours starting at midnight each day. Refer to the type definitions at [https://learn.microsoft.com/azure/templates/microsoft.recoveryservices/vaults/backuppolicies?pivots=deployment-language-bicep#schedulepolicy-objects](https://learn.microsoft.com/azure/templates/microsoft.recoveryservices/vaults/backuppolicies?pivots=deployment-language-bicep#schedulepolicy-objects).

Metadata | Value
---- | ----
Type | 
Default value | `@{schedulePolicyType=SimpleSchedulePolicyV2; scheduleRunFrequency=Hourly; hourlySchedule=; dailySchedule=; weeklySchedule=}`

### fileShareSchedulePolicy

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The backup schedule policy for Azure File Shares. Defaults to daily at the retention time. Refer to the type definitions at [https://learn.microsoft.com/azure/templates/microsoft.recoveryservices/vaults/backuppolicies?pivots=deployment-language-bicep#schedulepolicy-objects](https://learn.microsoft.com/azure/templates/microsoft.recoveryservices/vaults/backuppolicies?pivots=deployment-language-bicep#schedulepolicy-objects).

Metadata | Value
---- | ----
Type | 
Default value | `@{schedulePolicyType=SimpleSchedulePolicy; scheduleRunFrequency=Daily; scheduleRunDays=; scheduleRunTimes=System.Object[]}`

### backupSchedulePolicyTimeZone

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The time zone to use for the backup schedule policy.

Metadata | Value
---- | ----
Type | string
Default value | `UTC`

### retentionBackupTime

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

In case of Hourly backup schedules, this retention time must be set to the time of one of the hourly backups.

Metadata | Value
---- | ----
Type | string
Default value | `12/31/2023 08:00:00`

### hubManagementVmId

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The Azure resource ID of the management VM in the hub. Required if using AD join for Azure Files (`filesIdentityType = 'None'`). This value is output by the hub deployment.

Metadata | Value
---- | ----
Type | string
Default value | `''`

### hubManagementVmUamiPrincipalId

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The Entra ID object ID of the user-assigned managed identity of the management VM. This will be given the necessary role assignment to perform a domain join on the storage account(s). Required if using AD join for Azure Files (`filesIdentityType = 'None'`). This value is output by the hub deployment.

Metadata | Value
---- | ----
Type | string
Default value | `''`

### hubManagementVmUamiClientId

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

The client ID of the user-assigned managed identity of the management VM. Required if using AD join for Azure Files (`filesIdentityType = 'None'`). This value is output by the hub deployment.

Metadata | Value
---- | ----
Type | string
Default value | `''`

### debugMode

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Set to `true` to enable debug mode of the spoke. Debug mode will allow remote access to storage, etc. Should be not be used for production deployments.

Metadata | Value
---- | ----
Type | bool
Default value | `false`

### debugRemoteIp

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Used when `debugMode = true`. The IP address to allow access to storage, Key Vault, etc.

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
vmBackupPolicyName | string | The name of the backup policy used for Azure VM backups in the spoke.
diskEncryptionSetId | string | The Azure resource ID of the disk encryption set used for customer-managed key encryption of managed disks in the spoke.
computeSubnetId | string | The Azure resource ID of the ComputeSubnet.
computeResourceGroupName | string | The resource group name of the compute resource group.
shortcutTargetPath | string | The UNC path to the 'shared' file share in the spoke's private storage account.

## Use the template

### PowerShell

`./deploy.ps1 -TemplateParameterFile './main.prj.bicepparam' -TargetSubscriptionId '00000000-0000-0000-0000-000000000000' -Location 'eastus'`
