$creds = get-credential

$USER_DEFINED_FOLDER_IN_MAILBOX = "Processed"

# Set the path to your copy of EWS Managed API 
$dllpath = "./Microsoft.Exchange.WebServices.dll" 
# Load the Assemply 
[void][Reflection.Assembly]::LoadFile($dllpath) 

# Create a new Exchange service object 
$service = new-object Microsoft.Exchange.WebServices.Data.ExchangeService 

#These are your O365 credentials
$Service.Credentials = $creds.GetNetworkCredential()

# this TestUrlCallback is purely a security check
$TestUrlCallback = {
    param ([string] $url)
    if ($url -eq "https://autodiscover-s.outlook.com/autodiscover/autodiscover.xml") {$true} else {$false}
}
# Autodiscover using the mail address set above
$service.AutodiscoverUrl($mail,$TestUrlCallback)

# get a handle to the inbox
$inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service,[Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox)

$MailboxRootid = new-object  Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Root, $email) # selection and creation of new root
$MailboxRoot = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service,$MailboxRootid)

$fvFolderView = new-object Microsoft.Exchange.WebServices.Data.FolderView(100) #page size for displayed folders
$fvFolderView.Traversal = [Microsoft.Exchange.WebServices.Data.FolderTraversal]::Deep; #Search traversal selection Deep = recursively
$SfSearchFilter = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.FolderSchema]::Displayname,$USER_DEFINED_FOLDER_IN_MAILBOX) #for each folder in mailbox define search
$findFolderResults = $MailboxRoot.FindFolders($SfSearchFilter,$fvFolderView) 

$ArchiveFolder = ""


# create Property Set to include body and header of email
$PropertySet = New-Object Microsoft.Exchange.WebServices.Data.PropertySet([Microsoft.Exchange.WebServices.Data.BasePropertySet]::FirstClassProperties)


# set email body to text
$PropertySet.RequestedBodyType = [Microsoft.Exchange.WebServices.Data.BodyType]::Text;


# This next loop successfully finds my folder, but it is an inefficient way 
# to do it.  It's ok, because there's not that many folders, but there's tens 
# of thousands of emails to search through in the folder itself, and that will
# need a more efficient search.
foreach ($Fdr in $findFolderResults.Folders)
{
    $theDisplayName = $Fdr.DisplayName
    if($theDisplayName -eq $USER_DEFINED_FOLDER_IN_MAILBOX)
    {
        $ArchiveFolder = $Fdr
    }
}

# Now to actually try and search through the emails in my $ArchiveFolder (the hard way)
$textToFindInSubject = "Remove"

$emailsInFolder = $ArchiveFolder.FindItems(9999)   # <-- Successfully finds ALL emails with no filtering, requiring iterative code to find the ones I want.
foreach($individualEmail in $emailsInFolder.Items)
{
    if($individualEmail.Subject -match "$textToFindInSubject")
    {       
        # found the email i want -  but a super inefficient
        # way to do it
        echo "Successfully found the email!"
    }
}

$searchfilter = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+ContainsSubstring([Microsoft.Exchange.WebServices.Data.EmailMessageSchema]::Subject,$textToFindInSubject)     
$itemView = new-object Microsoft.Exchange.WebServices.Data.ItemView(999)
$searchResults = $service.FindItems($ArchiveFolder.ID, $searchfilter, $itemView)

foreach($result in $searchResults)
{
    $result.Load($PropertySet)
    $subj = $result.Subject

    echo "Subject"$subj
    echo "Body: $($result.Body.Text)"
}