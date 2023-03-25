<#
.SYNOPSIS
Collects backup job metrics, such as backup job's time, transferred and warnings.
.NOTES
    Author: Kirill Kuklin
    Date:   2022-03-04
#>

try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12
} catch {
    Write-Warning "Unable to set up requested security protocol."
    exit(0)
}

function CreateArray($arrayName, $titleStartsWith) {
    $arrayName = @()
    foreach($title in $session.Log) {
        if($title.Title.StartsWith($titleStartsWith)) {
            $arrayName += [pscustomobject] [ordered] @{
                Title      = $title
                }
        }
    }
    return $arrayName
}

$backupJobNames = (Get-VBOJob).Name -join ', '
$backupJob = Read-Host "Enter backup job name. Available jobs are: $backupJobNames"
if ($null -eq $backupJob) {
    Write-Warning "Empty job name supplied, unable to continue."
    return
}

$backupJobNamesLower = ((Get-VBOJob).Name).ToLower()
if (!$backupJobNamesLower.Contains($backupJob.ToLower())) {
    Write-Warning "$backupJob job not found, unable to continue."
    return
}

# setting up job sessions
$job = Get-VBOJob -Name $backupJob
$sessions = Get-VBOJobSession -Job $job 

$results = @()

foreach ($session in $sessions) {
    $startDate = $session.CreationTime
    $endDate = $session.EndTime
    $status = $session.Status
    if ($status -eq "Failed") {
        $errors = CreateArray $errors, "[Error]"
    } elseif ($status -eq "Warning") {
        $warnings = @() 
        foreach($title in $session.Log) {
            if($title.Title.StartsWith("[Warning]")) {
                $warnings += [pscustomobject] [ordered] @{
                    Title      = $title 
                    }
            }
            $failedMessage = $warnings.Title -join $nl
        }
        # case when the job finishes with warning, but there is one object failed
        if($warnings.Count -eq 1) {
            $errors = @()
            foreach($title in $session.Log) {
                if($title.Title.StartsWith("[Error]")) {
                    $errors += [pscustomobject] [ordered] @{
                        Title      = $title 
                    }
                    $failedMessage = $errors.Title -join $nl
                }
            }
        }
    } else {
        $failedMessage = "Job finished successfully"
    }

    $timespan = New-TimeSpan -Start $startDate -End $endDate
    $duration = @{
        Days = $timespan.Days
        Hours = $timespan.Hours
        Minutes = $timespan.Minutes
    }

    $results += [pscustomobject] [ordered] @{
        Jobname      = $session.JobName
        CreationTime = $session.CreationTime      
        Status       = $status 
        Duration     = (New-TimeSpan -Days $duration.Days -Hours $duration.Hours -Minutes $duration.Minutes).ToString()
        Transferred  = $session.Statistics.TransferredData
        Message      = $failedMessage.ToString()
    }  
}




$outputCSVFile = Read-Host "Enter location for the output CSV file. Click enter to write to C:\Results.csv"
if ("" -eq $outputCSVFile) {
    $outputCSVFile = "C:\Results.csv"
} 


$results  | Export-Csv -Path $outputCSVFile -NoTypeInformation
