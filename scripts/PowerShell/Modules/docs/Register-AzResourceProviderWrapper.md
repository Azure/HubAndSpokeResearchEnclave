---
external help file: AzSubscriptionManagement-help.xml
Module Name: AzSubscriptionManagement
online version:
schema: 2.0.0
---

# Register-AzResourceProviderWrapper

## SYNOPSIS
Registers an Azure subscription for a resource provider.

## SYNTAX

```
Register-AzResourceProviderWrapper [-ProviderNamespace] <String> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Determines if the specified resource provider namespace is registered.
If not, it will register the provider and wait for the registration to finish.

## EXAMPLES

### EXAMPLE 1
```
Register-AzResourceProviderWrapper -ProviderNamespace "Microsoft.Network"
```

This example registers the 'Microsoft.Network' resource provider in the current subscription.

## PARAMETERS

### -ProviderNamespace
The namespace of the resource provider to register.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
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

## OUTPUTS

## NOTES
The current Azure context will be used to determine the subscription to register the provider in.

## RELATED LINKS
