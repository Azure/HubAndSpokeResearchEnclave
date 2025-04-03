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

# Generate markdown help for the AzSubscriptionManagement module using platyPS
try {
    Import-Module platyPS
    Import-Module ../Modules/AzSubscriptionManagement.psm1 -ErrorAction Continue

    New-MarkDownHelp -Module AzSubscriptionManagement -OutputFolder ../Modules/docs -Force
}
finally {
    Remove-Module AzSubscriptionManagement
    Remove-Module platyPS
}

# Generate markdown help for the research hub module using PSDocs
try {
    Import-Module PSDocs
    [string]$CurrentLocation = Get-Location
    Set-Location -Path ../../../research-spoke/
    bicep build ./main.bicep
    Invoke-PSDocument -Path . -OutputPath ./docs -InputObject ./main.json
}
finally {
    Remove-Item -Path ./main.json -Force
    Set-Location -Path $CurrentLocation
    Remove-Module PSDocs
}

# TODO: Generate docs for research hub template