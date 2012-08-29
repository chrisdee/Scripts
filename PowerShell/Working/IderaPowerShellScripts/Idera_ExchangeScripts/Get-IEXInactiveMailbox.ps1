## =====================================================================
## Title       : Get-IEXInactiveMailbox
## Description : Retrieve inactive mailbox by checking the latest email in SentItems folder
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXInactiveMailbox [[-Server] <String>] [[-Days] <Int32>]
##   
## Output      : System.Management.Automation.PSCustomObject 
## Usage       :
##               1. Retrieve mailboxes that have the latest email sent more than 90 days ago.
##               Get-IEXInactiveMailbox -Server ExchangeServerName -Days 90
##
##               2. Retrieve mailboxes that have the latest email sent more than 180 (default) days ago, and sort them in descending order.
##               Get-IEXInactiveMailbox -Server ExchangeServerName | Sort-Object 'LastEmailSent(Days)' -Descending 
##                             
## Notes       :
## Tag         : Exchange 2007, mailbox, get
## Change log  :
## ===================================================================== 
 
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

function Get-IEXInactiveMailbox
{
 param(
  [string]$Server=$(Throw "parameter 'Server' cannot be empty"),
  [int]$Days=180
 )  
 
 
 $Now = Get-Date 

 Get-Mailbox -ResultSize Unlimited -Server $Server | Foreach-Object {
 
   trap { 
      Write-Error$_
      Continue
   }

  $Mailbox = $_
  $FolderStatistics = Get-MailboxFolderStatistics -Identity $Mailbox -IncludeOldestAndNewestItems -FolderScope SentItems | Where-Object {$_.FolderType -eq 'SentItems'}
  Add-Member -Input $FolderStatistics -MemberType NoteProperty -Name UserName -Value $Mailbox.Name 
  
  if($FolderStatistics.NewestItemReceivedDate)
  {
   Add-Member -Input $FolderStatistics -MemberType NoteProperty -Name "LastEmailSent(Days)" -Value $Now.Subtract($FolderStatistics.NewestItemReceivedDate).Days  
  }
  else
  {
   Add-Member -Input $FolderStatistics -MemberType NoteProperty -Name "LastEmailSent(Days)" -Value "No Items Found"
  } 


  $LastEmailSent = $FolderStatistics."LastEmailSent(Days)" 

  if($LastEmailSent -ge $Days -OR $LastEmailSent -eq "No Items Found")
  {
   $FolderStatistics | Select-Object UserName,"LastEmailSent(Days)"
  }
 }
} 
  