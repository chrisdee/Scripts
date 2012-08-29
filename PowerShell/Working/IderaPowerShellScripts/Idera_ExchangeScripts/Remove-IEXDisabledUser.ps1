## =====================================================================
## Title       : Remove-IEXDisabledUser
## Description : Delete all disabled user accounts and associated  mailboxes (or mark them for removal)
## Author      : Idera
## Date        : 09/15/2009
## Input       : Remove-IEXDisabledUser [[-Days] <Int32>] [-Permanent] [-Confirm] [-WhatIf]
##   
## Output      : None
## Usage       : 
##               1. Delete all user accounts (and mailboxes) that are disabled more than 40 days ago. Display confirmation message. 
##               Remove-IEXDisabledUser  -Days 40 -Permanent $true
## 
##               2. Delete all user accounts that are disabled more than 30 days ago. The mailboxes will be marked for removal. Suppress confirmation message. 
##               Remove-IEXDisabledUser -confirm:$false 
##            
## Notes       :
## Tag         : Exchange 2007, user, mailbox, remove
## Change log  :
## ===================================================================== 
 
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

function Remove-IEXDisabledUser 
{
    param(
    [int]$Days = 30,
    [bool]$Permanent = $false,
    [switch]$Confirm = $true,
    [switch]$WhatIf
    )
   
    Get-Mailbox -ResultSize Unlimited |
    Where-Object {$_.ExchangeUseraccountControl -eq "AccountDisabled" -and $_.WhenChanged -lt (Get-Date).AddDays(-$Days)} |
    Remove-Mailbox -Permanent:$Permanent -Confirm:$Confirm -WhatIf:$WhatIf
}
