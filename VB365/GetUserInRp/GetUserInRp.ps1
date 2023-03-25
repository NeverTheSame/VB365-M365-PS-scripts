param
(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] 
    [string]$RepositoryName,

    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] 
    [string]$JobName,

    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] 
    [string]$UserName
)

function Import-VBOPSMods {
    Import-Module -Name Veeam.Backup.powershell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    Import-Module -Name Veeam.Archiver.PowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    Import-Module -Name Veeam.Exchange.PowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    Import-Module -Name Veeam.SharePoint.PowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    Import-Module -Name Veeam.Teams.PowerShell -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
}
    
Import-VBOPSMods
$repo = Get-VBORepository -name $RepositoryName
$VBJob = Get-VBOJob -Name $JobName
$restorePoints = Get-VBORestorePoint -Repository $repo -Job $VBJob
for ($i=0; $i -lt $restorePoints.count; $i++) {
    write-host "Looking for" $UserName "in RP:" $restorePoints[$i].backuptime
    $pointNum = $restorePoints[$i]
    $session = Start-VBOExchangeItemRestoreSession -RestorePoint $pointNum -ShowDeleted -ShowAllVersions
    $getSession = Get-VBOExchangeItemRestoreSession
    $db = Get-VEXDatabase -Session $session

    if (Get-VEXMailbox -Database $db -name $UserName) {
        $email = (Get-VEXMailbox -Database $db -name $UserName).Email
        write-host $email "is in" $restorePoints[$i].backuptime "RP"
    } else {
        write-host "This account doesn't exist in" $restorePoints[$i].backuptime "PIT"
    }
    foreach ($sessTest in $getSession) {
        Stop-VBOExchangeItemRestoreSession -Session $sessTest
    }
}