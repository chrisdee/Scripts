## =====================================================================
## Title        : Purge-IEXMailbox
##  Description : Permanently delete mailbox(s) from a database
##  Author      : Idera
##  Date        : 09/15/2009
##  Input       : Purge-IEXMailbox [[-Server] <String>] [-Confirm]
##    
##  Output      : None
##  Usage       : 
##                1. Delete all disconnected mailboxes from EX1 server, display confirmation message 
##                Purge-Mailbox -Server EX1
##   
##                2. Delete all disconnected mailboxes from EX1 server, suppress confirmation message 
##                Purge-Mailbox -Server EX1 -Confirm:$false 
##             
##  Notes       :
##  Tag         : Exchange 2007, mailbox, remove
##  Change log  :
##  ===================================================================== 
 
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 
   
function Purge-IEXMailbox {
 
 param(
  [string]$Server=$(throw "Server parameter cannot be empty"),
  [switch]$Confirm
 )
 
 Get-MailboxStatistics -Server $Server | Where-Object {$_.DisconnectDate} | Foreach-Object {
  Remove-Mailbox -Database $_.Database -StoreMailboxIdentity $_.MailboxGuid -Confirm:$Confirm
 }
} 

  