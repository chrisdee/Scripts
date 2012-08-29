## =====================================================================
## Title       : Get-IEXLastSendAndReceivedDate
## Description : Retrieve the newest/oldest email item dates for each mailbox
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXLastSendAndReceivedDate [[-Server] <String>]
##   
## Output      : System.Management.Automation.PSCustomObject 
## Usage       : Get-IEXLastSendAndReceivedDate -Server ExchangeServerName
##                                                   
## Notes       :
## Tag         : Exchange 2007, mailbox, statistics, get
## Change log  :
## ===================================================================== 

#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

function Get-IEXLastSendAndReceivedDate 
{  
  
 param(
  [string]$Server=$(Throw "parameter 'Server' cannot be empty")
 ) 
  
  
 $Now = Get-Date 

 Get-Mailbox -ResultSize Unlimited -Server $Server | Foreach-Object { 
 
   trap { 
      Write-Error$_
      Continue
   }
 
 
  $FolderStatistics = Get-MailboxFolderStatistics -Identity $_ -IncludeOldestAndNewestItems
  $Newest = $FolderStatistics | Where-Object {$_.NewestItemReceivedDate} | Sort-Object NewestItemReceivedDate -Descending | Select-Object NewestItemReceivedDate -First 1
  $Oldest = $FolderStatistics | Where-Object {$_.OldestItemReceivedDate} | Sort-Object OldestItemReceivedDate | Select-Object OldestItemReceivedDate -First 1 


  $pso = "" | Select-Object UserName,NewestItemReceivedDate,"NewestItemReceivedDate(Days)",OldestItemReceivedDate,"OldestItemReceivedDate(Days)"
  $pso.UserName = $_.Name
  $pso.NewestItemReceivedDate = $Newest.NewestItemReceivedDate  
  $pso.OldestItemReceivedDate = $Oldest.OldestItemReceivedDate 
  
  if($Newest.NewestItemReceivedDate)
  {
   $pso."NewestItemReceivedDate(Days)" = $Now.Subtract($Newest.NewestItemReceivedDate).Days
  
  } 

  if($Oldest.OldestItemReceivedDate)
  {
   $pso."OldestItemReceivedDate(Days)" = $Now.Subtract($Oldest.OldestItemReceivedDate).Days
  
  } 

  $pso
 }
} 