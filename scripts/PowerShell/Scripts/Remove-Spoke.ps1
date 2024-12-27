<#
.SYNOPSIS
    Deletes all Azure resources for the specified research spoke.

.PARAMETER TemplateParameterFile
    The path to the template parameter file, in bicepparam format, that was used to create the spoke to be deleted.

.PARAMETER TargetSubscriptionId
    The subscription ID where the spoke was created.

.PARAMETER CloudEnvironment
    The Azure environment where the spoke was created. Default is 'AzureCloud'.

.PARAMETER Tenant
    The Azure tenant ID where the spoke was created. Default is the current tenant.

.PARAMETER Force
    DANGER: Forces the deletion of the spoke resources without prompting for confirmation.

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

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory, Position = 1)]
    [string]$TemplateParameterFile,
    [Parameter(Mandatory, Position = 2)]
    [string]$TargetSubscriptionId,
    [Parameter(Position = 3)]
    [string]$CloudEnvironment = 'AzureCloud',
    [Parameter(Position = 4)]
    [string]$Tenant = (Get-AzContext).Tenant.Id,
    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

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

try {
    ################################################################################
    # SET AZURE CONTEXT AND CHECK RESOURCE EXISTENCE
    ################################################################################

    # Import the Azure subscription management module
    Import-Module ..\Modules\AzSubscriptionManagement.psm1

    $OriginalContext = Get-AzContext
    # Determine if a cloud context switch is required
    $AzContext = Set-AzContextWrapper -SubscriptionId $TargetSubscriptionId -Environment $CloudEnvironment -Tenant $Tenant

    # Check if any resource groups exist that match the pattern
    $ResourceGroups = Get-AzResourceGroup -Name $ResourceGroupNamePattern

    if ($ResourceGroups.Count -eq 0) {
        Write-Warning "No resource groups found matching pattern '$ResourceGroupNamePattern' in subscription '$((Get-AzContext).Subscription.Name)'."
        exit
    }

    $Msg1 = "Found $($ResourceGroups.Count) resource groups matching pattern '$ResourceGroupNamePattern' in subscription '$((Get-AzContext).Subscription.Name)'."
    $Msg = "$Msg1`nAny resource locks will be deleted.`nThese actions cannot be undone and data loss might occur. Do you want to continue removing this spoke?"

    if (-not ($WhatIfPreference -or $Force -or $PSCmdlet.ShouldContinue($Msg, 'Confirm Spoke Removal'))) {    
        exit
    }
    
    # If -WhatIf is used, output the number of resource groups found
    if ($WhatIfPreference) {
        Write-Host $Msg1
    }

    if ($Force) {
        Write-Verbose "Force switch specified. Proceeding with deletion of resources."
    }   

    ################################################################################
    # REMOVE ANY RESOURCE LOCKS
    ################################################################################

    Write-Verbose "STEP 1: Removing resource locks..."
    $ResourceGroups | ForEach-Object { 
        Get-AzResourceLock -ResourceGroupName $_.ResourceGroupName | Remove-AzResourceLock -Force | Out-Null
    }

    ################################################################################
    # REMOVE THE RECOVERY SERVICES VAULT
    ################################################################################

    # Check if the expected Recovery Services Vault exists in the expected resource group
    [string]$BackupResourceGroupName = $ResourceGroupNamePattern.Replace("*", "backup")
    [string]$RecoveryServicesVaultName = $ResourceNamePattern.Replace("{rtype}", "rsv")

    $Vault = Get-AzRecoveryServicesVault -ResourceGroupName $BackupResourceGroupName -Name $RecoveryServicesVaultName -ErrorAction SilentlyContinue

    if ($Vault) {
        Write-Verbose "STEP 2: Removing Recovery Services Vault '$RecoveryServicesVaultName' in resource group '$BackupResourceGroupName'..."
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
        Write-Verbose "STEP 3: Removing managed private endpoints from Data Factory '$DataFactoryName' in resource group '$StorageResourceGroupName'..."
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
        Write-Verbose "STEP 4: Removing resource groups..."
        $Jobs += $ResourceGroups | Remove-AzResourceGroup -AsJob -Force -Verbose:$VerbosePreference

        Write-Host "Waiting for $($Jobs.Count) resource groups to be deleted..."
        $Jobs | Get-Job | Wait-Job | Select-Object -Property Id, StatusMessage, Name | Format-Table -AutoSize
    }
    else {
        $ResourceGroups | Remove-AzResourceGroup -WhatIf | Out-Null
    }

    ################################################################################
    # REMOVE THE DISCONNECTED PEERING FROM THE RESEARCH HUB VIRTUAL NETWORK
    ################################################################################

    [string]$HubVirtualNetworkId = $ParameterFileContents.parameters.hubVNetResourceId.value
    [string]$ResourceIDPattern = "/subscriptions/(?<subscriptionId>[^/]+)/resourceGroups/(?<resourceGroupName>[^/]+)/providers/[^/]+/[^/]+/(?<resourceName>[^/]+)"

    if ($HubVirtualNetworkId -match $ResourceIDPattern) {
        [string]$HubSubscriptionId = $Matches['subscriptionId']
        [string]$HubResourceGroupName = $Matches['resourceGroupName']
        [string]$HubVirtualNetworkName = $Matches['resourceName']

        # We could get the virtual network ID from the spoke resources, but it's possible that the virtual network was already deleted but the peering wasn't
        [string]$SpokeVirtualNetworkName = $ResourceNamePattern.Replace("{rtype}", "vnet")
        [string]$NetworkResourceGroupName = $ResourceGroupNamePattern.Replace('*', 'network')
        [string]$SpokeVirtualNetworkResourceId = "/subscriptions/$TargetSubscriptionId/resourceGroups/$NetworkResourceGroupName/providers/Microsoft.Network/virtualNetworks/$SpokeVirtualNetworkName"

        Write-Verbose "STEP 5: Removing disconnected peering to spoke network '$SpokeVirtualNetworkName' from hub virtual network '$HubVirtualNetworkName' in resource group '$HubResourceGroupName' in subscription '$HubSubscriptionId'..."
    
        $AzContext = Set-AzContextWrapper -SubscriptionId $HubSubscriptionId -Environment $CloudEnvironment -Tenant $Tenant

        # Remove peering explicitly from hub
        Get-AzVirtualNetworkPeering -ResourceGroupName $HubResourceGroupName -VirtualNetworkName $HubVirtualNetworkName | `
                # Find the peering using the peering state (to confirm it's disconnected) and the remote virtual network ID
                Where-Object { $_.PeeringState -eq 'Disconnected' -and $_.RemoteVirtualNetwork.Id -eq $SpokeVirtualNetworkResourceId } | `
                Remove-AzVirtualNetworkPeering -Force -Verbose:$VerbosePreference
    }
}
catch {
    Write-Host "An error occurred: $($_)"
    Write-Host $_.ScriptStackTrace
    Write-Host "In context $AzContext"
}
finally {
    Write-Verbose "Setting Azure context back to the original subscription..."
    $AzContext = Set-AzContextWrapper -SubscriptionId $OriginalContext.Subscription.Id -Environment $OriginalContext.Environment.Name -Tenant $OriginalContext.Tenant.Id

    # Remove the module from the session
    Remove-Module AzSubscriptionManagement -WhatIf:$false
    Write-Host "Done!"
}