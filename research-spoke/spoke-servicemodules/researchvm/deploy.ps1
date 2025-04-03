<#
.SYNOPSIS
    Performs a deployment of a research VM.

.DESCRIPTION
    Use this for manual deployments only.
    If using a CI/CD pipeline, specify the necessary parameters in the pipeline definition.

.PARAMETER TemplateParameterFile
    The path to the template parameter file in bicepparam format.

.PARAMETER TargetSubscriptionId
    The subscription ID to deploy the resources to. The subscription must already exist.

.PARAMETER Location
    The Azure region to deploy the resources to.

.EXAMPLE
    ./deploy.ps1 -TemplateParameterFile '.\main.bicepparam' -TargetSubscriptionId '00000000-0000-0000-0000-000000000000' -Location 'eastus' 

.EXAMPLE
    ./deploy.ps1 '.\main.prj.bicepparam' '00000000-0000-0000-0000-000000000000' 'eastus'
#>

#Requires -Version 7.4
# Temporary version restriction due to Az PowerShell issue 26752
# https://github.com/Azure/azure-powershell/issues/26752
#Requires -Modules @{ ModuleName="Az.Resources"; MaximumVersion="7.6.0" }
#Requires -PSEdition Core

[CmdletBinding()]
Param(
    [Parameter(Position = 0)]
    [string]$TemplateParameterFile = './main.bicepparam',
    [Parameter(Mandatory, Position = 1)]
    [string]$TargetSubscriptionId,
    [Parameter(Mandatory, Position = 2)]
    [string]$Location,
    [Parameter(Mandatory, Position = 3)]
    [string]$ResourceGroupName,
    [Parameter(Position = 4)]
    [string]$Environment = 'AzureCloud',
    [string]$TemplateFile = './main.bicep'
)

# Define common parameters for the New-AzDeployment cmdlet
[hashtable]$CmdLetParameters = @{
    TemplateFile      = $TemplateFile
    Location          = $Location
    ResourceGroupName = $ResourceGroupName
}

if ($TemplateParameterFile) {
    $CmdLetParameters.Add('TemplateParameterFile', $TemplateParameterFile)
}

[string]$WorkloadName = 'researchvm'

# Generate a unique name for the deployment
[string]$DeploymentName = "$WorkloadName-$(Get-Date -Format 'yyyyMMddThhmmssZ' -AsUTC)"
$CmdLetParameters.Add('Name', $DeploymentName)

# Import the Azure subscription management module
Import-Module ../../../scripts/PowerShell/Modules/AzSubscriptionManagement.psm1

# Determine if a cloud context switch is required
Set-AzContextWrapper -SubscriptionId $TargetSubscriptionId -Environment $Environment

# Ensure the EncryptionAtHost feature is registered for the current subscription
# LATER: Do this with a deployment script in Bicep
Register-AzProviderFeatureWrapper -ProviderNamespace "Microsoft.Compute" -FeatureName "EncryptionAtHost"

# Remove the module from the session
Remove-Module AzSubscriptionManagement -WhatIf:$false

# Execute the deployment
$DeploymentResult = New-AzResourceGroupDeployment @CmdLetParameters

# Evaluate the deployment results
if ($DeploymentResult.ProvisioningState -eq 'Succeeded') {
    Write-Host "🔥 Deployment succeeded."

    $DeploymentResult.Outputs | Format-Table -Property Key, @{Name = 'Value'; Expression = { $_.Value.Value } }
}
else {
    $DeploymentResult
}
