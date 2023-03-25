[CmdletBinding(DefaultParameterSetName = 'User')]
param
(
    [Parameter(Mandatory = $true, ParameterSetName="User")] 
    [Parameter(Mandatory = $true, ParameterSetName="App")] 
    [guid]$TenantId,

    [Parameter(Mandatory = $true, ParameterSetName="App")]
    [guid]$ClientId,

    [Parameter(Mandatory = $true, ParameterSetName="App")]
    [string]$ClientCertificateThumbprint,

    [Parameter(Mandatory = $true, ParameterSetName="User")] 
    [Parameter(Mandatory = $true, ParameterSetName="App")]
    [System.Uri]$HostUrl,

    [Parameter(Mandatory = $true, ParameterSetName="User")] 
    [Parameter(Mandatory = $true, ParameterSetName="App")] 
    [guid]$SiteId,

    [Parameter(Mandatory = $true, ParameterSetName="User")] 
    [Parameter(Mandatory = $true, ParameterSetName="App")] 
    [guid]$WebId,

    [Parameter(Mandatory = $true, ParameterSetName="User")] 
    [Parameter(Mandatory = $true, ParameterSetName="App")] 
    [guid]$ListId,

    [Parameter(Mandatory = $true, ParameterSetName="User")] 
    [Parameter(Mandatory = $true, ParameterSetName="App")]
    [guid]$UniqueId,    

    [Parameter(Mandatory = $false, ParameterSetName="User")] 
    [Parameter(Mandatory = $false, ParameterSetName="App")] 
    [string]$Version,

    [Parameter(Mandatory = $true, ParameterSetName="User")] 
    [Parameter(Mandatory = $true, ParameterSetName="App")] 
    [string]$OutFile
)


if (Get-Module -ListAvailable Microsoft.Graph*)
{
    Import-Module -Name Microsoft.Graph.Authentication, Microsoft.Graph.Sites
}
else
{
    Write-Host "Installing Microsoft Graph PowerShell SDK..."
    Install-Module -Name Microsoft.Graph -Force -SkipPublisherCheck
    Import-Module -Name Microsoft.Graph.Authentication, Microsoft.Graph.Sites
}

if ($ClientId)
{
    Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $ClientCertificateThumbprint -ForceRefresh
}
else 
{
    Connect-MgGraph -Scopes "Sites.FullControl.All" -TenantId $TenantId -ForceRefresh
}

$graphSiteId = "$($HostUrl.DnsSafeHost),$SiteId,$WebId"

if ($Version)
{
    $drive = Get-MgSiteListDrive -SiteId $graphSiteId -ListId $ListId
    $driveItem = Get-MgSiteListItemDriveItem -SiteId $graphSiteId -ListId $ListId -ListItemId $UniqueId
    
    Get-MgDriveItemVersionContent -DriveId $drive.Id -DriveItemId $driveItem.Id -DriveItemVersionId $Version -OutFile $OutFile
}
else
{
    Get-MgSiteListItemDriveItemContent -ListId $ListId -ListItemId $UniqueId -SiteId $graphSiteId -OutFile $OutFile
}

Disconnect-MgGraph