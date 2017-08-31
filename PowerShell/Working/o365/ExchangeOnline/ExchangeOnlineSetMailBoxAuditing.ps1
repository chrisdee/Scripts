## Exchange Online: PowerShell Script to Enable or Disable Mail Box Auditing in Exchange Online (o365) ##

## Resource: https://www.ronnipedersen.com/2017/07/29/automate-mailbox-auditing-office-365

## Connect to Exchange Online
Import-PSSession $(New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Authentication Basic -AllowRedirection -Credential $(Get-Credential))

## Get the current state of audit logging
Get-Mailbox -Filter {RecipientTypeDetails -eq "UserMailbox"} -ResultSize Unlimited | Select Name,AuditEnabled,AuditLogAgeLimit

## Enable / Disable mailbox audit logging
Get-Mailbox -Filter {RecipientTypeDetails -eq "UserMailbox"} -ResultSize Unlimited | Set-Mailbox -AuditEnabled $True #Change this value to $False if you want to disable auditing

## Set the age limit for mailbox audit logging
Get-Mailbox -Filter {RecipientTypeDetails -eq "UserMailbox"} -ResultSize Unlimited | Set-Mailbox -AuditLogAgeLimit 365 #Change this value to the number of days you want to retain the audit logs

## Verify the current state of audit logging
Get-Mailbox -Filter {RecipientTypeDetails -eq "UserMailbox"} -ResultSize Unlimited | Select Name,AuditEnabled,AuditLogAgeLimit
