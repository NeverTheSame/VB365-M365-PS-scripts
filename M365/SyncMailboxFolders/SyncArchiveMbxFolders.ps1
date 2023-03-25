Import-Module .\Microsoft.Exchange.WebServices.dll

function DoSync($service, $folder) {

	Write-Host "Syncing: " $folder.DisplayName

    $state = $null

    $n = 0;

    do
    {
	    $changes = $service.SyncFolderItems($folder.Id, [Microsoft.Exchange.WebServices.Data.PropertySet]::FirstClassProperties, $null, 100, [Microsoft.Exchange.WebServices.Data.SyncFolderItemsScope]::NormalItems, $state)  
        #Write-Host "   Found: " $changes.Count
	    $changes | ForEach-Object {

            Write-Host "   " $_.ItemId
        }

        $state = $changes.SyncState

        $n = $n + $changes.Count
    }
    while ($changes.Count -ne 0)

    Write-Host "Total changes: " $n
}

function LoadSubfolders($folder) {
       
    Write-Host "Loading children: " $folder.DisplayName

    $list = [System.Collections.ArrayList]::new()

    $offset = 0

    do
    {
        $folderView = [Microsoft.Exchange.WebServices.Data.FolderView]::new(100, $offset, [Microsoft.Exchange.WebServices.Data.OffsetBasePoint]::Beginning )
        $folderView.PropertySet = [Microsoft.Exchange.WebServices.Data.PropertySet]::FirstClassProperties
        $folderView.Traversal = [Microsoft.Exchange.WebServices.Data.FolderTraversal]::Shallow
        $found = $folder.FindFolders($folderView)
        $list.AddRange($found.Folders)
        $offset = $found.NextPageOffset
    }
    While( $found.MoreAvailable )

    if ($list.Count -ne 0) {

        Write-Host "   Found children: " $list.Count
    }

    return $list
}

$creds = get-credential 

$email = Read-Host -Prompt 'Mailbox UPN address'

$service = [Microsoft.Exchange.WebServices.Data.ExchangeService]::new()
$service.Credentials = $creds.GetNetworkCredential()
$service.Url = "https://outlook.office365.com/EWS/Exchange.asmx"

$impersonation = [Microsoft.Exchange.WebServices.Data.ImpersonatedUserId]::new([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::PrincipalName, $email)
$service.ImpersonatedUserId = $impersonation

$mailbox = [Microsoft.Exchange.WebServices.Data.Mailbox]::new($email)
$rootId = [Microsoft.Exchange.WebServices.Data.FolderId]::new([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::ArchiveMsgFolderRoot, $mailbox)
$root = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service, $rootId)
Write-Host 'Root folder: ' $root.DisplayName

$all = [System.Collections.ArrayList]::new()
$stack = [System.Collections.Stack]::new()
$stack.Push($root)

While ($stack.Count -ne 0)
{
    $folder = $stack.Pop()

    $children = LoadSubfolders $folder
    $children | ForEach-Object {

        #Write-Host "   " $_.DisplayName
 
        $n = $all.Add( $_ )
        $stack.Push( $_ )
    }
}

Write-Host "Total folders: " $all.Count

$all | ForEach-Object {

    DoSync $service $_
}


& cmd /c pause
exit
