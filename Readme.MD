This project contains several PowerShell scripts that can be used for various tasks related to Microsoft 365 administration.

- [VB365/ConnectExchangeOnline](https://github.com/NeverTheSame/VB365-M365-PS-scripts/blob/master/M365/ConnectExchangeOnline.ps1)
- [VB365/Get-Duration](https://github.com/NeverTheSame/VB365-M365-PS-scripts/tree/master/VBM/GetDuration)
- [VB365/PerfStats](https://github.com/NeverTheSame/VB365-M365-PS-scripts/tree/master/VBM/PerfStats)
- [M365/Get-ItemHasUniqueRoleAssignments](https://github.com/NeverTheSame/VB365-M365-PS-scripts/tree/master/M365/GetItemHasUniqueRoleAssignments)
- [M365/ListOdFiles](https://github.com/NeverTheSame/VB365-M365-PS-scripts/tree/master/M365/ListOdFiles)

# VB365
## ConnectExchangeOnline
Library for proper connection to Exchange Online. Has list of functions used in other scripts. 

## PublicFoldersOps
Library for working with Public folders and PF mailboxes in Exchange Online (creation/listing). 
To connect to Exchange Online edit line 5 and provide proper _admin@tenant.onmicrosoft.com_ account.

## Get-Duration
PS script collects backup job metrics, such as backup job's time, transferred and warnings.

**Example output**

<img width="769" alt="image" src="https://user-images.githubusercontent.com/68837588/178778021-4ce7dca8-e82d-46f5-89fa-92aedb9db604.png">

## SyncMailboxFolders/Modern/SyncMbxFoldersAppSecret
PS script synchronizes archive/non-archive mailbox folders.
Edit script and enter the following infromation:
```
$appId = ""
$tenantId = ""
$secret = ""
```
See script SYNOPSIS for more details.

---
# M365

## Get-ItemHasUniqueRoleAssignments
PS script retrievs SPO items property "HasUniqueRoleAssignments".
To load items 
```
$item = Get-PnPListItem -List $list -Id $id
Get-PnPProperty -ClientObject $item -Property HasUniqueRoleAssignments
```

**Example output for Documents list** 
```
Install-Module SharePointPnPPowerShellOnline
Connect-PnPOnline -Url "https://tenant.sharepoint.com"
$item = Get-PnPListItem -List Documents -Id 8
Get-PnPProperty -ClientObject $item -Property HasUniqueRoleAssignments
→ False
```
 


To run script for a range of problematic items in 41588-41613:
```
.\Get-ItemHasUniqueRoleAssignments.ps1 -Credential $cred -WebUrl https://tenant.sharepoint.com/sites/SiteName -ListId $listId -StartId 41588 -EndId 41613
```

## ListOdFiles
PS script lists OneDrive files, number of versions and size for each file.

**Example output** 
```
File                                               Versions Size
----                                               -------- ----
Documents/9cf61d73-47fd-43f9-8208-7d6865a92505.zip 1.0      1.2 MB
Documents/RESTORED-Document.docx                   3.0      10.5 KB
Documents/Document.docx                            4.0      10.6 KB
Morningside/Document.docx                          1.0      10.8 KB
Morningside/TestBook.xlsx                          3.0      7.8 KB
Documents/Book.xlsx                                2.0      7.9 KB
Documents/Document.docx                            2.0      10.3 KB
Tony D/BPomery.ppl                                 1.0      5.0 B
Morningside/Document.docx                          1.0      10.8 KB
Good team notebook/Good team notebook.onetoc2      2.0      7.4 KB
123/aws_backup.pdf                                 1.0      2.3 MB
RESTORED-Morningside/Document.docx                 1.0      10.8 KB

Sum is 3.6 MB
Number of files: 12
```

## PerfStats
PS script helps grab performance information directly from the logs and make it into something readable.

**Example output** 
```
526 is the total number of batches reviewed in this script.
The number of batches with receive rates between 100-999+ MB/s; 0 total
The number of batches with receive rates between 10-99 MB/s; 0 total
The number of batches with receive rates between 1-9 MB/s; 0 total
The number of batches with receive rates between .1-.9 MB/s; 241 total
The number of batches with receive rates between .01-.09 MB/s; 188 total
The number of batches with receive rates between .001-.009 MB/s; 59 total
The number of batches with receive rates between 100-999 B/s; 35 total
The number of batches with receive rates between 10-99 B/s; 3 total
The number of batches with receive rates that are basically 0 B/s; 0 total


The number of batches with save rates between 100-999+ MB/s; 0 total
The number of batches with save rates between 10-99 MB/s; 0 total
The number of batches with save rates between 1-9 MB/s; 26 total
The number of batches with save rates between .1-.9 MB/s; 121 total
The number of batches with save rates between .01-.09 MB/s; 123 total
The number of batches with save rates between .001-.009 MB/s; 102 total
The number of batches with save rates between 100-999 B/s; 129 total
The number of batches with save rates between 10-99 B/s; 25 total
The number of batches with save rates that are basically 0 B/s; 0 total
This last save rate of zero can indicate a read operation against the repository, indicating a full read but not full write!
```