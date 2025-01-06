<#
.SYNOPSIS
    A function to break out parameters from an ARM template.
#>
function global:GetTemplateParameter {
    param (
        [Parameter(Mandatory = $True)]
        [String]$Path
    )
    process {
        $template = Get-Content $Path | ConvertFrom-Json;
        foreach ($property in $template.parameters.PSObject.Properties) {
            [PSCustomObject]@{
                Name          = $property.Name
                Description   = $property.Value.metadata.description
                Type          = $property.Value.type
                Required      = !("defaultValue" -in $property.Value.PSObject.Properties.Name -or $property.Value.nullable)
                DefaultValue  = if ("defaultValue" -in $property.Value.PSObject.Properties.Name) {
                    if ($property.Value.defaultValue) { $property.Value.defaultValue } else {
                        switch ($property.Value.type) {
                            'string' { '''''' }
                            'object' { '{ }' }
                            'array' { '()' }
                            'bool' { 'false' }
                            'securestring' { '''''' }
                        } 
                    } 
                }
                AllowedValues = if ($property.Value.allowedValues) {
                    "``$($property.Value.allowedValues -join '`, `')``" 
                }
                MinLength     = $property.Value.minLength
                MaxLength     = $property.Value.maxLength
            }
        }
    }
}

<#
.SYNOPSIS
    A function to import metadata from the ARM template file.
#>
function global:GetTemplateMetadata {
    param (
        [Parameter(Mandatory = $True)]
        [String]$Path
    )
    process {
        $template = Get-Content $Path | ConvertFrom-Json;
        return $template.metadata;
    }
}

<#
.SYNOPSIS
    A function to import outputs from the ARM template file.
#>
function global:GetTemplateOutput {
    param (
        [Parameter(Mandatory = $True)]
        [String]$Path
    )
    process {
        $template = Get-Content $Path | ConvertFrom-Json;
        foreach ($property in $template.outputs.PSObject.Properties) {
            [PSCustomObject]@{
                Name        = $property.Name
                Description = $property.Value.metadata.description
                Type        = $property.Value.type
            }
        }
    }
}

Document Research-Spoke {
    # Read the ARM template file
    $metadata = GetTemplateMetadata -Path $PSScriptRoot/main.json;
    $parameters = GetTemplateParameter -Path $PSScriptRoot/main.json;
    $outputs = global:GetTemplateOutput -Path $PSScriptRoot/main.json;

    Title $metadata.name

    $metadata.description

    Section 'Table of Contents' {
        "[Parameters](#parameters)" 
        "[Outputs](#outputs)"
        "[Use the template](#use-the-template)"
    }

    # Add each parameter to a table
    Section 'Parameters' {
        $parameters | Table -Property @{ Name = 'Parameter name'; Expression = { "[$($_.Name)](#$($_.Name.ToLower()))" } }, Required, Description

        $parameters | ForEach-Object { 
            Section $_.Name {
                if ($_.Required) {
                    "![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)"
                }
                else {
                    "![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)"
                }
                $_.Description
                
                $Details = "Metadata | Value`n---- | ----`nType | $($_.Type)"
                if ($_.DefaultValue) {
                    $Details += "`nDefault value | ``$($_.DefaultValue)``"
                }
                if ($_.AllowedValues) {
                    $Details += "`nAllowed values | $($_.AllowedValues)"
                }
                if ($_.MinLength) {
                    $Details += "`nMinimum length | $($_.MinLength)"
                }
                if ($_.MaxLength) {
                    $Details += "`nMaximum length | $($_.MaxLength)"
                }
                $Details
            }
        }
    }

    # Add outputs
    Section 'Outputs' {
        $outputs | Table -Property Name, Type, Description
    }

    # Add sample
    Section 'Use the template' {
        Section 'PowerShell' {
            '`./deploy.ps1 -TemplateParameterFile ''./main.prj.bicepparam'' -TargetSubscriptionId ''00000000-0000-0000-0000-000000000000'' -Location ''eastus''`'
        }
    }
}