<#
.SYNOPSIS
    Generates documentation for select PowerShell modules and ARM templates in this repo.

.NOTES
    If you encounter an error loading the YamlDotNet assembly, this is because platyPS loads a different version of the assembly than PSDocs.
    platPS loads an older assembly version but appears to work with the newer version PSDocs uses.
    You can backup the YamlDotNet.dll file in the platyPS module folder and replace it with the newer version from the PSDocs module folder.
#>

#Requires -Modules platyPS, Az.Resources, PSDocs

[CmdletBinding()]
param ()

$powerShellRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $powerShellRoot 'Modules\AzSubscriptionManagement.psm1'
$moduleDocsPath = Join-Path $powerShellRoot 'Modules\docs'
$researchSpokePath = Join-Path (Split-Path -Parent (Split-Path -Parent $powerShellRoot)) 'research-spoke'

# Generate markdown help for the AzSubscriptionManagement module using platyPS
try {
    Import-Module platyPS
    Import-Module $modulePath

    New-MarkDownHelp -Module AzSubscriptionManagement -OutputFolder $moduleDocsPath -Force
}
finally {
    Remove-Module AzSubscriptionManagement
    Remove-Module platyPS
}

# Generate markdown help for the research spoke module using PSDocs
$CurrentLocation = Get-Location
try {
    Import-Module PSDocs
    Set-Location -Path $researchSpokePath
    bicep build ./main.bicep
    Invoke-PSDocument -Path . -OutputPath ./docs -InputObject ./main.json
}
finally {
    Remove-Item -Path (Join-Path $researchSpokePath 'main.json') -Force
    Set-Location -Path $CurrentLocation
    Remove-Module PSDocs
}

# TODO: Generate docs for research hub template