#Welcome to my attempt at using registered expression to collect and output performance data using folder browser with v6 logging 
#Version 1.17
#Author - Jon Nash 4/29/2022

#Note: This is probably not backwards compatible and wont be written that way, atleast by me.

#For now, please run the script in ISE and extract the logs to C:\temp as well as using C:\temp as outputfolder. Increases chances of success until more research time is given.

Add-Type -AssemblyName System.Windows.Forms

Clear-Host
Write-Host "Welcome to the PowerShell attempt at gathering performance statistics in VBOv6, please follow the next two simple prompts to complete the exercise!" -ForegroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host "***Please extract the logs and then select a specific VBO job folder within the bundle!***" -ForegroundColor Green

#open folder browser and select job folder for VBOv6
#code grabbed from stackoverflow https://stackoverflow.com/questions/64659341/how-can-i-make-my-script-stop-when-clicked-on-the-cancel-button
function Get-FolderPath {
    # Show an Open Folder Dialog and return the directory selected by the user.
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [string]$Message = "Select a directory.",

        $InitialDirectory = [System.Environment+SpecialFolder]::MyComputer,

        [switch]$ShowNewFolderButton
    )

    # Browse Dialog Options:
    # https://docs.microsoft.com/en-us/windows/win32/api/shlobj_core/ns-shlobj_core-browseinfoa
    $browserForFolderOptions = 0x00000041                                  # BIF_RETURNONLYFSDIRS -bor BIF_NEWDIALOGSTYLE
    if (!$ShowNewFolderButton) { $browserForFolderOptions += 0x00000200 }  # BIF_NONEWFOLDERBUTTON

    $browser = New-Object -ComObject Shell.Application
    # To make the dialog topmost, you need to supply the Window handle of the current process
    [intPtr]$handle = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle

    # see: https://msdn.microsoft.com/en-us/library/windows/desktop/bb773205(v=vs.85).aspx

    # ShellSpecialFolderConstants for InitialDirectory:
    # https://docs.microsoft.com/en-us/windows/win32/api/shldisp/ne-shldisp-shellspecialfolderconstants#constants

    $folder = $browser.BrowseForFolder($handle, $Message, $browserForFolderOptions, $InitialDirectory)

    $result = if ($folder) { $folder.Self.Path } else { $null }

    # Release and remove the used Com object from memory
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($browser) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    return $result
}

$jobFolder = Get-FolderPath -Message 'Please select the job folder of the extracted V6 Logs!'
Write-Host "You selected"$jobFolder
Write-Host ""
Write-Host ""
Write-Host "***Please select output folder for saving files, Right-Click inside pop-up for new folder options***" -ForegroundColor Green

#open folder browser and select job folder for VBOv6
$outputFolder = Get-FolderPath -Message 'Please select a folder where we can save temporary files to. Right-click for new folder options.'
Write-Host "You selected"$outputFolder
Write-Host ""
Write-Host "This next part will take a few minutes, grab a drink or snack and hang loose." -ForegroundColor Cyan

#basic attempt to get total batches in logs, this grabs both saving and receive rates since we'll just divide in half shortly
#progressbar attempt maybe? $percentComplete = 0 $percentComplete++ inside for each loop while grabbing batches?

$totalBatches = Get-ChildItem -Path $jobFolder | Select-String -Pattern '(\w)* (\d+) B/s'

#print results somewhat neatly
Write-Host ""
Write-Host (($totalBatches.count)/2) "is the total number of batches reviewed in this script." -ForegroundColor Magenta

#write new files for saving and receiving then create input variables
$recinput = Join-Path -Path $outputFolder -ChildPath receive.txt
$savinput = Join-Path -Path $outputFolder -ChildPath saving.txt
$totalBatches -like '*Receive*' > $recinput
$totalBatches -like '*Saving*' > $savinput

#now we're going to create 4 total files, 2 recieve/2 save for reading content by utilizing split to capture digits. Seems inefficient but works
$arrayrecTotal = Get-Content -Path $recinput
$newrecfile = Join-Path -Path $outputFolder -ChildPath receivesplit.txt
$arraysavTotal = Get-Content -Path $savinput
$newsavfile = Join-Path -Path $outputFolder -ChildPath savesplit.txt

#runs through array of log lines and captures specific information, may or may not work in production due to path length
foreach($line in $arrayrecTotal){
 Add-Content $newrecfile $line.Split(('()),:'))[8]
    }
foreach($line in $arraysavTotal){
 Add-Content $newsavfile $line.Split(('()),:'))[8]
    }

#second set of files I mentioned
$arrayrecsecond = Get-Content -Path $newrecfile
$arraysavsecond = Get-Content -Path $newsavfile
$newsecondrecfile = Join-Path -Path $outputFolder -ChildPath receivesplitsecond.txt
$newsecondsavfile = Join-Path -Path $outputFolder -ChildPath savesplitsecond.txt

#splitting again to grab just digits, probably inefficient but works in lab setting
foreach($line in $arrayrecsecond){
 Add-Content $newsecondrecfile $line.Split((' '))[1]
    }
foreach($line in $arraysavsecond){
 Add-Content $newsecondsavfile $line.Split((' '))[1]
    }

#save digits to specific variables for counting batches
$ninedigitRec = get-content -Path $newsecondrecfile | Select-String -Pattern '^\d{9}$' 
$eightdigitRec = get-content -Path $newsecondrecfile | Select-String -Pattern '^\d{8}$' 
$sevendigitRec = get-content -Path $newsecondrecfile | Select-String -Pattern '^\d{7}$' 
$sixdigitRec = get-content -Path $newsecondrecfile | Select-String -Pattern '^\d{6}$' 
$fivedigitRec = get-content -Path $newsecondrecfile | Select-String -Pattern '^\d{5}$' 
$fourdigitRec = get-content -Path $newsecondrecfile | Select-String -Pattern '^\d{4}$' 
$threedigitRec = Get-Content -Path $newsecondrecfile | Select-String -Pattern '^\d{3}$' 
$twodigitRec = Get-Content -Path $newsecondrecfile | Select-String -Pattern '^\d{2}$' 
$onedigitRec = Get-Content -Path $newsecondrecfile | Select-String -Pattern '^\d{1}$' 

$ninedigitSav = get-content -Path $newsecondsavfile | Select-String -Pattern '^\d{9}$' 
$eightdigitSav = get-content -Path $newsecondsavfile | Select-String -Pattern '^\d{8}$' 
$sevendigitSav = get-content -Path $newsecondsavfile | Select-String -Pattern '^\d{7}$' 
$sixdigitSav = get-content -Path $newsecondsavfile | Select-String -Pattern '^\d{6}$' 
$fivedigitSav = get-content -Path $newsecondsavfile | Select-String -Pattern '^\d{5}$' 
$fourdigitSav = get-content -Path $newsecondsavfile | Select-String -Pattern '^\d{4}$' 
$threedigitSav = Get-Content -Path $newsecondsavfile | Select-String -Pattern '^\d{3}$' 
$twodigitSav = Get-Content -Path $newsecondsavfile | Select-String -Pattern '^\d{2}$' 
$onedigitSav = Get-Content -Path $newsecondsavfile | Select-String -Pattern '^\d{1}$' 

#set up total count variables
$total9Rec = (($ninedigitRec.count))
$total8Rec = (($eightdigitRec.count))
$total7Rec = (($sevendigitRec.count))
$total6Rec = (($sixdigitRec.count))
$total5Rec = (($fivedigitRec.count))
$total4Rec = (($fourdigitRec.count))
$total3Rec = (($threedigitRec.count))
$total2Rec = (($twodigitRec.count))
$total1Rec = (($onedigitRec.count))
$total9Sav = (($ninedigitSav.count))
$total8Sav = (($eightdigitSav.count))
$total7Sav = (($sevendigitSav.count))
$total6Sav = (($sixdigitSav.count))
$total5Sav = (($fivedigitSav.count))
$total4Sav = (($fourdigitSav.count))
$total3Sav = (($threedigitSav.count))
$total2Sav = (($twodigitSav.count))
$total1Sav = (($onedigitSav.count))

#need to reword this section to make it not only easier to understand but pretty
Write-Host ""
Write-Host "The number of batches with receive rates between 100-999+ MB/s; $total9Rec total" -ForegroundColor Green
Write-Host "The number of batches with receive rates between 10-99 MB/s; $total8Rec total"  -ForegroundColor Green
Write-Host "The number of batches with receive rates between 1-9 MB/s; $total7Rec total" -ForegroundColor Green
Write-Host "The number of batches with receive rates between .1-.9 MB/s; $total6Rec total" -ForegroundColor Green
Write-Host "The number of batches with receive rates between .01-.09 MB/s; $total5Rec total" -ForegroundColor Green
Write-Host "The number of batches with receive rates between .001-.009 MB/s; $total4Rec total" -ForegroundColor Green
Write-Host "The number of batches with receive rates between 100-999 B/s; $total3Rec total" -ForegroundColor Green
Write-Host "The number of batches with receive rates between 10-99 B/s; $total2Rec total" -ForegroundColor Green
Write-Host "The number of batches with receive rates that are basically 0 B/s; $total1Rec total" -ForegroundColor Green
Write-Host ""
Write-Host ""
Write-Host "The number of batches with save rates between 100-999+ MB/s; $total9Sav total" -ForegroundColor Green
Write-Host "The number of batches with save rates between 10-99 MB/s; $total8Sav total" -ForegroundColor Green
Write-Host "The number of batches with save rates between 1-9 MB/s; $total7Sav total" -ForegroundColor Green
Write-Host "The number of batches with save rates between .1-.9 MB/s; $total6Sav total" -ForegroundColor Green
Write-Host "The number of batches with save rates between .01-.09 MB/s; $total5Sav total" -ForegroundColor Green
Write-Host "The number of batches with save rates between .001-.009 MB/s; $total4Sav total" -ForegroundColor Green
Write-Host "The number of batches with save rates between 100-999 B/s; $total3Sav total" -ForegroundColor Green
Write-Host "The number of batches with save rates between 10-99 B/s; $total2Sav total" -ForegroundColor Green
Write-Host "The number of batches with save rates that are basically 0 B/s; $total1Sav total" -ForegroundColor Green
Write-Host "**This last save rate of zero can indicate a read operation against the repository, indicating a full read but not full write!" -ForegroundColor Cyan
Write-Host ""
Write-Host "There will be files leftover that you'll be prompted shortly to clean-up in $outputFolder." -ForegroundColor Yellow
Write-Host ""

#ask to output results into a text file, named at their choosing but maybe we should standardize it for speed?
$title1    = 'Output'
$question1 = 'Do you want all of us to now save the output of the results?'
$choices1  = '&Yes I do', '&No, I do not need you'
$decision1 = $Host.UI.PromptForChoice($title1, $question1, $choices1, 1)
if ($decision1 -eq 0) {
    Write-Host 'We are now creating a new output file we guess...'
    $resultOutput = Get-FolderPath -Message 'Please select folder to save results to or dont..'
    $resultFilename = Read-Host -Prompt 'Please provide a filename for the results'
    $resultPath = Join-Path -Path $resultOutput -ChildPath $resultFilename
    Add-Content -Path $resultPath -Value "These are the results of the test that was run using this path $jobFolder"
    Add-Content $resultPath ""
    Add-Content $resultPath "The number of batches with receive rates between 100-999+ MB/s; $total9Rec"
    Add-Content $resultPath "The number of batches with receive rates between 10-99 MB/s; $total8Rec"
    Add-Content $resultPath "The number of batches with receive rates between 1-9 MB/s; $total7Rec"
    Add-Content $resultPath "The number of batches with receive rates between .1-.9 MB/s; $total6Rec"
    Add-Content $resultPath "The number of batches with receive rates between .01-.09 MB/s; $total5Rec"
    Add-Content $resultPath "The number of batches with receive rates between .001-.009 MB/s; $total4Rec"
    Add-Content $resultPath "The number of batches with receive rates between 100-999 B/s; $total3Rec"
    Add-Content $resultPath "The number of batches with receive rates between 10-99 B/s; $total2Rec"
    Add-Content $resultPath "The number of batches with receive rates that are basically 0 B/s; $total1Rec"
    Add-Content $resultPath " "
    Add-Content $resultPath "The number of batches with save rates between 100-999+ MB/s; $total9Sav"
    Add-Content $resultPath "The number of batches with save rates between 10-99 MB/s; $total8Sav"
    Add-Content $resultPath "The number of batches with save rates between 1-9 MB/s; $total7Sav"
    Add-Content $resultPath "The number of batches with save rates between .1-.9 MB/s; $total6Sav"
    Add-Content $resultPath "The number of batches with save rates between .01-.09 MB/s; $total5Sav"
    Add-Content $resultPath "The number of batches with save rates between .001-.009 MB/s; $total4Sav"
    Add-Content $resultPath "The number of batches with save rates between 100-999 B/s; $total3Sav"
    Add-Content $resultPath "The number of batches with save rates between 10-99 B/s; $total2Sav"
    Add-Content $resultPath "The number of batches with save rates that are basically 0 B/s; $total1Sav"
    Add-Content $resultPath "**This last save rate of zero can indicate a read operation against the repository, indicating a full read but not full write."
    Write-Host "File may or may not be created in" $resultPath 
    Write-Host ""
    Write-Host 'Finally, we can take a break. Good luck.' -ForegroundColor Red
} else {
    Write-Host ""
    Write-Host 'Finally, we can take a break. Good luck.' -ForegroundColor Red
}

#cleanup temp files by prompting user
$title    = 'Clean-up'
$question = 'Do you want all of us to clean up the temp files that you made us create?'
$choices  = '&Yes I do', '&No, I will handle it'
$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    Write-Host ""
    Write-Host 'We are now cleaning up the files we guess...' -ForegroundColor Red
    Write-Host ""
    Remove-Item -Path $recinput -Confirm
    Remove-Item -Path $savinput -Confirm
    Remove-Item -Path $newrecfile -Confirm
    Remove-Item -Path $newsavfile -Confirm
    Remove-Item -Path $newsecondrecfile -Confirm
    Remove-Item -Path $newsecondsavfile -Confirm
    Write-Host 'Finally, we can take a break. Good luck.' -ForegroundColor Red
} else {
    Write-Host ""
    Write-Host 'Finally, we can take a break. Good luck.' -ForegroundColor Red
}

#end script out
Write-Host ""
Write-Host "Okay scripts all done. Close me out so I can sleep in peace.." -ForegroundColor Red
cmd /c exit

#future enhancements: 
#make prettier
#research more efficient commands/methods/functions
#add functionality to compare save/receieve and automagically output the bottleneck based on that comparison
#add pause on error to capture any failures
#add selection for multiple jobs on proxy maybe?
#progress bar on beginning commands while its reading log files?
