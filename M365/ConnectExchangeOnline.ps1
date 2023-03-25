function Connect-Exo-Basic($UserPrincipalName) {
    Import-Module ExchangeOnlineManagement
    Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName
}

$o365Endpoint = "outlook.office365.com"

function Connect-Exo-Basic-with-PSSession($UserPrincipalName) {
    if ($(get-pssession | select -Property ComputerName).Computername -eq $o365Endpoint) {
        Write-Host "Already connected to $o365Endpoint"
    }
    else {
        $UserCredential = Get-Credential -Credential $UserPrincipalName
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://$($o365Endpoint)/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
        Import-PSSession $Session
    }
}

function Remove-Basic-PSSession() {
    Remove-PSSession -ComputerName $o365Endpoint
    Write-Host "Disconnected from $o365Endpoint"
}





