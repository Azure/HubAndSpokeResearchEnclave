<#
.SYNOPSIS
    Generates documentation for select PowerShell modules and ARM templates in this repo.
#>

#Requires -Modules platyPS, Az.Resources, PSDocs.Azure

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
    bicep build ../../../research-spoke/main.bicep
    Invoke-PSDocument -Path ../../../research-spoke/ -OutputPath ./docs
}
finally {
    Remove-Item -Path ../../../research-spoke/main.json -Force
    Remove-Module PSDocs.Azure
}

# TODO: Generate docs for research hub template