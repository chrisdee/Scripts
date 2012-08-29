## =====================================================================
## Title       : Get-IEXMailboxAddressCount
## Description : Get email addresses count for all users.
## Author      : Idera
## Date        : 09/15/2009
## Input       : No input
##   
## Output      : Microsoft.Exchange.Data.Directory.Management.Mailbox
## Usage       : 
##               1. Get email addresses count for all users, use Format-Table to alter results.
##               Get-IEXMailboxAddressCount | Format-Table Name,@{Label="AddressCount";Expression={$_.EmailAddresses.Count}} 
##
## Notes       :
## Tag         : Exchange 2007, email, user, get, mailbox
## Change log  :
## ===================================================================== 
  

#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 


function Get-IEXMailboxAddressCount
{
 Get-Mailbox -resultSize unlimited | Where-Object {$_.EmailAddresses.count -gt 1}
} 

 