[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)][PSCredential]$Credential,
    [Parameter(Mandatory = $true)][string]$WebUrl,
    [Parameter(Mandatory = $true)][guid]$ListId,
    [Parameter(Mandatory = $true)][int]$StartId,
    [Parameter(Mandatory = $true)][int]$EndId
)

function Load-Assemblies
{
    $scriptDirectory = Split-Path -Parent $PSCommandPath

    $clientAssembly = [System.Reflection.Assembly]::LoadFile($scriptDirectory + "\Microsoft.SharePoint.Client.dll")
    $clientRuntimeAssembly = [System.Reflection.Assembly]::LoadFile($scriptDirectory + "\Microsoft.SharePoint.Client.Runtime.dll")
    $spoClientAssembly = [System.Reflection.Assembly]::LoadFile($scriptDirectory + "\Microsoft.Online.SharePoint.Client.Tenant.dll")

    $assemblies = @($clientAssembly.FullName, $clientRuntimeAssembly.FullName, $spoClientAssembly.FullName)
}

function Get-ListItemPropertyExpression([string] $propertyName)
{
    $parameterExprType = [System.Linq.Expressions.ParameterExpression].MakeArrayType()
    $lambdaMethod = [System.Linq.Expressions.Expression].GetMethods() | ? { $_.Name -eq "Lambda" -and $_.IsGenericMethod -and $_.GetParameters().Length -eq 2 -and $_.GetParameters()[1].ParameterType -eq $parameterExprType }
    $lambdaMethodGeneric = $lambdaMethod.MakeGenericMethod([System.Func[Microsoft.SharePoint.Client.ListItem, System.Object]])
    
    $parameter = [System.Linq.Expressions.Expression]::Parameter([Microsoft.SharePoint.Client.ListItem], "item")
    $name = [System.Linq.Expressions.Expression]::Property($parameter, $propertyName)
    $body = [System.Linq.Expressions.Expression]::Convert($name, [System.Object])
    
    return $lambdaMethodGeneric.Invoke($null, [System.Object[]] @($body, [System.Linq.Expressions.ParameterExpression[]] @($parameter)))
}

try
{   
    Load-Assemblies

    $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($WebUrl)
    $clientContext.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Credential.UserName, $Credential.Password)
    
    $list = $clientContext.Web.Lists.GetById($listId)
    
    $expression = Get-ListItemPropertyExpression("HasUniqueRoleAssignments")
    
    $StartId..$EndId | ForEach-Object {
        try
        {
            Write-Host "ID: $_"
            $item = $list.GetItemById($_)
            $clientContext.Load($item, $expression)
            $clientContext.ExecuteQuery();
            Write-Host "HasUniqueRoleAssignments: $($item.HasUniqueRoleAssignments)" -Foreground Green
        }
        catch [Microsoft.SharePoint.Client.ServerException]
        {
            if ($_.Exception.ServerErrorCode -eq -2147024809 -and $_.Exception.ServerErrorTypeName -eq "System.ArgumentException")
            {
                Write-Host "Item does not exist" -Foreground Yellow
            }
            else 
            {
                Write-Error $_
            }        
        }
    }
}
catch
{
    Write-Error $_
    exit 1
}
finally
{
    if ($clientContext)
    {
        $clientContext.Dispose()
    }
}
