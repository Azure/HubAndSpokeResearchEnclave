---
external help file: AzSubscriptionManagement-help.xml
Module Name: AzSubscriptionManagement
online version:
schema: 2.0.0
---

# Set-AzContextWrapper

## SYNOPSIS
Sets the Azure environment and subscription context for the current session.

## SYNTAX

```
Set-AzContextWrapper [-SubscriptionId] <String> [[-Environment] <String>] [[-Tenant] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Sets the Azure environment and subscription context for the current session.

## EXAMPLES

### EXAMPLE 1
```
Set-AzContextWrapper -SubscriptionId '00000000-0000-0000-0000-000000000000'
```

This example switches the current session to the subscription with the ID '00000000-0000-0000-0000-000000000000'.

### EXAMPLE 2
```
Set-AzContextWrapper -SubscriptionId '00000000-0000-0000-0000-000000000000' -Environment 'AzureUSGovernment'
```

This example switches the current session to the subscription with the ID '00000000-0000-0000-0000-000000000000' in Azure US Government.

## PARAMETERS

### -SubscriptionId
The Azure subscription ID to switch to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Environment
The Azure environment to switch to.
Default is 'AzureCloud'.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: AzureCloud
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tenant
The Azure tenant ID to switch to.
Default is the current tenant.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: (Get-AzContext).Tenant.Id
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### None.
## NOTES
You must already be signed in to Azure using \`Connect-AzAccount\` before calling this function.

## RELATED LINKS
