---
external help file: AzSubscriptionManagement-help.xml
Module Name: AzSubscriptionManagement
online version:
schema: 2.0.0
---

# Register-AzProviderFeatureWrapper

## SYNOPSIS
Registers an Azure subscription for a resource provider feature.

## SYNTAX

```
Register-AzProviderFeatureWrapper [-ProviderNamespace] <String> [-FeatureName] <String>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Determines if the specified feature for the specified resource provider namespace is registered.
If not, it will register the feature and wait for registration to complete.

## EXAMPLES

### EXAMPLE 1
```
Register-AzProviderFeatureWrapper -ProviderNamespace "Microsoft.Compute" -FeatureName "EncryptionAtHost"
```

This example registers the 'EncryptionAtHost' feature for the 'Microsoft.Compute' resource provider namespace in the current subscription.

## PARAMETERS

### -ProviderNamespace
The namespace of the resource provider to register the feature for.

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

### -FeatureName
The name of the feature to register.

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
The current Azure context will be used to determine the subscription to register the feature in.

## RELATED LINKS
