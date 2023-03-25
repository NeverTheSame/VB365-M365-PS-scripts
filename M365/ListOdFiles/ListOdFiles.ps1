 <#
.SYNOPSIS
Lists OneDrive files, number of versions and size for each file.
.NOTES
    Author: Kirill Kuklin
    Date:   2022-03-04
#>
param
(
    [Parameter(Mandatory = $true,HelpMessage='Must be of https://org-my.sharepoint.com/personal/user_org_onmicrosoft_com format', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] 
    [string]$SiteURL,

    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] 
    [PSCredential]$Cred
)

$global:totalSize = 0
$global:numberOfFiles = 0
$LibraryName="Documents"

function Get-AllFilesFromFolder([Microsoft.SharePoint.Client.Folder]$Folder) {
    <#
        .SYNOPSIS
            Gets all files of a folder
    #>
    $Ctx =  $Folder.Context
    $Ctx.load($Folder.files)
    $Ctx.ExecuteQuery()
  
    ForEach ($File in $Folder.files) {
        $Ctx.Load($File)
        $Ctx.Load($File.Versions)
        $Ctx.ExecuteQuery()
        $global:numberOfFiles++
        $File | select-object `
            @{label = "File"; Expression = { (DisplayParentAndLeaf($_.ServerRelativeUrl)) } },
            @{label = "Versions"; Expression = { ($_.UIVersionLabel) } },
            @{label = "Size"; Expression = { "{0:N2}" -f (DisplayInBytes($_.Length)) } } 

        $global:totalSize = $global:totalSize + $File.Length
    }
          
    # Recursively Call the function to get files of all folders
    $Ctx.load($Folder.Folders)
    $Ctx.ExecuteQuery()
  
    # Exclude "Forms" system folder and iterate through each folder
    ForEach($SubFolder in $Folder.Folders | Where-Object {$_.Name -ne "Forms"}) {
        Get-AllFilesFromFolder -Folder $SubFolder
    }
}

function Get-SPODocumentLibraryFiles() {
    <#
        .SYNOPSIS
            lists all documents in sharepoint online library.
    #>
    param
    (
        [Parameter(Mandatory=$true)] [string] $SiteURL,
        [Parameter(Mandatory=$true)] [string] $LibraryName,
        [Parameter(Mandatory=$true)] [System.Management.Automation.PSCredential] $Credential
    )
    Try {
        # Setup the context
        $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
        $Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.UserName,$Cred.Password)
  
        # Get the Library and Its Root Folder
        $Library=$Ctx.web.Lists.GetByTitle($LibraryName)
        $Ctx.Load($Library)
        $Ctx.Load($Library.RootFolder)
        $Ctx.ExecuteQuery()
  
        # Call the function to get Files of the Root Folder
        Get-AllFilesFromFolder -Folder $Library.RootFolder
    }
    Catch {
        write-host -f Red "Error:" $_.Exception.Message
    }
}

function DisplayParentAndLeaf($ServerRelativeUrl) {
    $dirpath = [System.IO.Path]::GetDirectoryName($ServerRelativeUrl)
    $dirname = [System.IO.Path]::GetFileName($dirpath)
    $leaf = Split-Path $ServerRelativeUrl -Leaf
    "{0}/{1}" -f $dirname, $leaf 
}

function DisplayInBytes($num) {
    $suffix = "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"
    $index = 0
    while ($num -gt 1kb) {
        $num = $num / 1kb
        $index++
    } 

    "{0:N1} {1}" -f $num, $suffix[$index]
}
  
function Load-Assemblies
{
    $CurrentDir=Get-Location
    Add-Type -Path "$CurrentDir\Microsoft.SharePoint.Client.dll"
    Add-Type -Path "$CurrentDir\Microsoft.SharePoint.Client.Runtime.dll"
}
Load-Assemblies

# Call the function to Get All Files from a document library
Get-SPODocumentLibraryFiles -SiteURL $SiteURL -LibraryName $LibraryName -Credential $Cred
Write-Host "`nSum is $(DisplayInBytes($($global:totalSize)))" 
Write-Host "Number of files: $($global:numberOfFiles)" 
