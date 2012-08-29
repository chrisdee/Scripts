## =====================================================================
## Title       : Get-IEXMailboxCountReport
## Description : Get mailbox count per mailbox database
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXMailboxCountReport [[-Server] <String>]
##  
## Output      : Microsoft.PowerShell.Commands.GroupInfo
## Usage       : 
##               1. Get mailbox count per mailbox database on server ExchangeServerName 
##               Get-IEXMailboxCountReport -Server ExchangeServerName
##           
## Notes       :
## Tag         : Exchange 2007, mailbox, get
## Change log  :
## ===================================================================== 
  
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 
   

function Get-IEXMailboxCountReport{ 
 param( 
     [string]$Server = $(Throw 'Please specify a server name.') 
 )  
  
 Get-Mailbox -Server $Server | Group-Object {$_.Database.Name} -NoElement | Sort-Object -Property Count -Descending 
}
  