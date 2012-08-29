## =====================================================================
## Title       : Get-IEXForwardMailbox
## Description : List users with email forwarding enabled (with or without delivering a copy to the original recipient)
## Author      : Idera
## Date        : 09/15/2009
## Input       : No input
##  
## Output      : System.Management.Automation.PSCustomObject
## Usage       : 
##               1. List users with email forwarding enabled  (with or without delivering a copy to the original recipient)
##               Get-IEXForwardMailbox
## 
## Notes       :
## Tag         : Exchange 2007, mailbox, filter, forward, get
## Change log  :
## ===================================================================== 
  
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 
 
function Get-IEXForwardMailbox
{          
  Get-Mailbox -Filter {ForwardingAddress -ne $null} | Select-Object Name,ForwardingAddress,DeliverToMailboxAndForward      
} 
 