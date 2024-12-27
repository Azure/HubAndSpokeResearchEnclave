[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory)]
    [string]$DataFactoryName,
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$SubscriptionId
)

# From research-spoke/spoke-modules/airlock/adf.bicep
[string]$DataFactoryApiVersion = '2018-06-01'

$RestMethodParameters = @{
    Method               = 'GET'
    SubscriptionId       = $SubscriptionId
    ResourceGroupName    = $ResourceGroupName
    ResourceProviderName = 'Microsoft.DataFactory'
    ResourceType         = @('factories', 'managedVirtualNetworks', 'managedPrivateEndpoints')
    # 'default' is hardcoded because it's the only possible name for a managed virtual network
    Name                 = @($DataFactoryName, 'default')
    ApiVersion           = $DataFactoryApiVersion
}

$ManagedPrivateEndpoints = ((Invoke-AzRestMethod @RestMethodParameters).Content | ConvertFrom-Json).value
Write-Host "Deleting $($ManagedPrivateEndpoints.Count) managed private endpoints in Data Factory '$DataFactoryName' in resource group '$ResourceGroupName'..."

# If there are any managed private endpoints
if ($ManagedPrivateEndpoints -and $ManagedPrivateEndpoints.Count -gt 0) {
    # Update the REST method parameters for the DELETE request
    $RestMethodParameters.Method = 'DELETE'

    foreach ($ManagedPrivateEndpoint in $ManagedPrivateEndpoints) {
        # Update the REST method parameter to specify the name of the endpoint to be deleted
        $RestMethodParameters.Name = @($DataFactoryName, 'default', $ManagedPrivateEndpoint.Name)

        if ($PSCmdlet.ShouldProcess($ManagedPrivateEndpoint.Name, "DELETE")) {
            # Debug Note: This call returns HTTP status code 200 even if the delete failed due to a resource lock
            $Response = Invoke-AzRestMethod @RestMethodParameters
            Write-Verbose "DELETE HTTP request returned status code: $($Response.StatusCode)"
        }
    }
}
