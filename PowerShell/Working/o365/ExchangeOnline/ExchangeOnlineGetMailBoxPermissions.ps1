## Exchange Online: PowerShell Script to List all Users who have 'Full Access' and 'Send As' Rights on other Users Mail Boxes (o365)  ##

## Resource: http://www.ehloworld.com/277

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic –AllowRedirection
Import-PSSession $Session

##Find users who have Full Access to the mailbox of others
Get-Mailbox -ResultSize Unlimited | Get-MailboxPermission | Where-Object {($_.AccessRights -match "FullAccess") -and -not ($_.User -like "NT AUTHORITY\SELF")} | Format-Table Identity, User

##Find users who have Send-As Access to the mailbox of others
Get-Mailbox -Resultsize Unlimited | Get-MailboxPermission | Where-Object {($_.ExtendedRights -like "*send-as*") -and -not ($_.User -like "nt authority\self")} | Format-Table Identity, User -auto