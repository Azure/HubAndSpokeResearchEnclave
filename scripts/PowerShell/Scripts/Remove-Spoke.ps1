<#
.SYNOPSIS
    Deletes all Azure resources for the specified research spoke.

.PARAMETER TemplateParameterFile
    The path to the template parameter file, in bicepparam format, that was used to create the spoke to be deleted.

.PARAMETER TargetSubscriptionId
    The subscription ID where the spoke was created.

.PARAMETER CloudEnvironment
    The Azure environment where the spoke was created. Default is 'AzureCloud'.

.EXAMPLE
    ./deploy.ps1 -TemplateParameterFile '.\main.hub.bicepparam' -TargetSubscriptionId '00000000-0000-0000-0000-000000000000'

.EXAMPLE
    ./deploy.ps1 '.\main.hub.bicepparam' '00000000-0000-0000-0000-000000000000'

.EXAMPLE
    ./deploy.ps1 '.\main.hub.bicepparam' '00000000-0000-0000-0000-000000000000' 'AzureUSGovernment'
#>

# LATER: Be more specific about the required modules; it will speed up the initial call
#Requires -Modules Az.Resources, Az.RecoveryServices, Az.Network, Az.DataFactory
#Requires -PSEdition Core

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory, Position = 1)]
    [string]$TemplateParameterFile,
    [Parameter(Mandatory, Position = 2)]
    [string]$TargetSubscriptionId,
    [Parameter(Position = 3)]
    [string]$CloudEnvironment = 'AzureCloud'
)

################################################################################
# PREPARE VARIABLES
################################################################################

# Process the template parameter file and read relevant values for use here
Write-Verbose "Using template parameter file '$TemplateParameterFile'"
[string]$TemplateParameterJsonFile = [System.IO.Path]::ChangeExtension($TemplateParameterFile, 'json')
bicep build-params $TemplateParameterFile --outfile $TemplateParameterJsonFile

# Read the values from the parameters file, to use when generating the $DeploymentName value
$ParameterFileContents = (Get-Content $TemplateParameterJsonFile | ConvertFrom-Json)
[string]$WorkloadName = $ParameterFileContents.parameters.workloadName.value
[string]$Location = $ParameterFileContents.parameters.location.value
[int]$Sequence = $ParameterFileContents.parameters.sequence.value
[string]$Environment = $ParameterFileContents.parameters.environment.value
[string]$NamingConvention = $ParameterFileContents.parameters.namingConvention.value

# Taken from research-spoke/main.bicep
[string]$SequenceFormat = "00"

[string]$ResourceNamePatternSubWorkload = $NamingConvention.Replace("{workloadName}", $WorkloadName).Replace("{seq}", $Sequence.ToString($SequenceFormat)).Replace("{location}", $Location).Replace("{env}", $Environment).Replace("{loc}", $Location)
[string]$ResourceNamePattern = $ResourceNamePatternSubWorkload.Replace("-{subWorkloadName}", "")
[string]$ResourceGroupNamePattern = $ResourceNamePattern.Replace("{rtype}", "rg-*")
Write-Verbose "Looking for resource groups matching pattern '$ResourceGroupNamePattern'."

$ErrorActionPreference = 'Stop'

################################################################################
# SET AZURE CONTEXT AND CHECK RESOURCE EXISTENCE
################################################################################

# Import the Azure subscription management module
Import-Module ..\Modules\AzSubscriptionManagement.psm1

# Determine if a cloud context switch is required
Set-AzContextWrapper -SubscriptionId $TargetSubscriptionId -Environment $CloudEnvironment

# Remove the module from the session
Remove-Module AzSubscriptionManagement -WhatIf:$false

# Check if any resource groups exist that match the pattern
$ResourceGroups = Get-AzResourceGroup -Name $ResourceGroupNamePattern

if ($ResourceGroups.Count -eq 0) {
    Write-Warning "No resource groups found matching pattern '$ResourceGroupNamePattern' in subscription '$((Get-AzContext).Subscription.Name)'."
    return
}
else {
    Write-Host "Found $($ResourceGroups.Count) resource groups matching pattern '$ResourceGroupNamePattern' in subscription '$((Get-AzContext).Subscription.Name)'."
}

################################################################################
# REMOVE ANY RESOURCE LOCKS
################################################################################

$ResourceGroups | ForEach-Object { 
    Get-AzResourceLock -ResourceGroupName $_.ResourceGroupName | Remove-AzResourceLock -Force 
}

################################################################################
# REMOVE THE RECOVERY SERVICES VAULT
################################################################################

# Check if the expected Recovery Services Vault exists in the expected resource group
[string]$BackupResourceGroupName = $ResourceGroupNamePattern.Replace("*", "backup")
[string]$RecoveryServicesVaultName = $ResourceNamePattern.Replace("{rtype}", "rsv")

$Vault = Get-AzRecoveryServicesVault -ResourceGroupName $BackupResourceGroupName -Name $RecoveryServicesVaultName -ErrorAction SilentlyContinue

if ($Vault) {
    Write-Verbose "Removing Recovery Services Vault '$RecoveryServicesVaultName' in resource group '$BackupResourceGroupName'."
    & ./Recovery/Remove-rsv.ps1 -VaultName $RecoveryServicesVaultName `
        -ResourceGroup $BackupResourceGroupName -SubscriptionId $TargetSubscriptionId `
        -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
}

################################################################################
# REMOVE THE DATA FACTORY MANAGED PRIVATE ENDPOINTS
################################################################################

[string]$StorageResourceGroupName = $ResourceGroupNamePattern.Replace('*', 'storage')
[string]$DataFactoryName = $ResourceNamePatternSubWorkload.Replace('{rtype}', 'adf').Replace('{subWorkloadName}', 'airlock')

# Check if the expected Data Factory exists in the expected resource group
$Factory = Get-AzDataFactoryV2 -ResourceGroupName $StorageResourceGroupName -Name $DataFactoryName -ErrorAction SilentlyContinue

if ($Factory) {
    & ./DataFactory/Remove-ManagedPrivateEndpoints.ps1 -DataFactoryName $DataFactoryName `
        -ResourceGroup $StorageResourceGroupName -SubscriptionId $TargetSubscriptionId `
        -WhatIf:$WhatIfPreference -Verbose:$VerbosePreference
}

################################################################################
# REMOVE THE RESOURCE GROUPS
################################################################################

# Two separate commands needed because -AsJob does not support specifying a variable
if ($PSCmdlet.ShouldProcess("spoke resource groups", "Remove")) {
    $Jobs = @()
    $Jobs += $ResourceGroups | Remove-AzResourceGroup -AsJob -Force -Verbose:$VerbosePreference

    Write-Host "Waiting for $($Jobs.Count) resource groups to be deleted..."
    $Jobs | Get-Job | Wait-Job | Select-Object -Property Id, StatusMessage, Name | Format-Table -AutoSize
}
else {
    $ResourceGroups | Remove-AzResourceGroup -WhatIf | Out-Null
}

# LATER: Remove peering explicitly from hub