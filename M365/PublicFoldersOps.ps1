# Exchange Online connection block
$scriptDir = Get-Location
. "$scriptDir\ConnectExchangeOnline.ps1"     

Connect-Exo-Basic-with-PSSession admin@tenant.onmicrosoft.com
# End of Exchange Online connection block

function Create-Secondary-PF-Mailbox($PfMailboxName) {
    New-Mailbox -PublicFolder -Name $PfMailboxName
}

function Create-PF-In-Secondary-Mailbox($PfName, $PfMailboxName) {
    New-PublicFolder -Name $PfName -Mailbox $PfMailboxName
}

function Get-All-PF-With-ContentMailbox() {
    Get-PublicFolder -Recurse | ft name, contentmailboxname
}

Get-All-PF-With-ContentMailbox


Remove-Basic-PSSession

