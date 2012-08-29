## =====================================================================
## Title       : Get-IEXMailboxFolderStatistics
## Description : Extend MailboxFolderStatistics object, including Newest and Oldest Item Received Date members in days 
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXMailboxFolderStatistics [[-Server] <String>] [[-Identity] <String>]
##   
## Output      : System.Management.Automation.PSCustomObject 
## Usage       :
##               1. Retrieve extended mailbox folder statistics for TestUser
##               Get-IEXMailboxFolderStatistics -Server ExchangeServerName -Identity TestUser        
##
## Notes       :
## Tag         : Exchange 2007, mailbox, folder, statistics, new
## Change log  :
## ===================================================================== 
 
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

function Get-IEXMailboxFolderStatistics
{  
  
    param( 
       [string]$Server=$(Throw "parameter 'Server' cannot be empty"),
       [string]$Identity="*" 
    ) 
 
 
  
 $Now = Get-Date 

 Get-Mailbox -ResultSize Unlimited -Identity $Identity -Server $Server | Foreach-Object {
 
  $Mailbox = $_
  $FolderStatistics = Get-MailboxFolderStatistics -Identity $Mailbox -IncludeOldestAndNewestItems | Sort-Object -Descending NewestItemReceivedDate,OldestItemReceivedDate  
  

  $FolderStatistics | Foreach-Object { 
 
  
   trap { 
      Write-Error$_
      Continue
   }
 
   $_ | Add-Member -MemberType NoteProperty -Name UserName -Value $Mailbox.Name
 
  
   if($_.NewestItemReceivedDate) {
    $_ | Add-Member -MemberType NoteProperty -Name "NewestItemReceivedDate(Days)" -Value $Now.Subtract($_.NewestItemReceivedDate).Days
   } 

 
   if($_.OldestItemReceivedDate) {
    $_ | Add-Member -MemberType NoteProperty -Name "OldestItemReceivedDate(Days)" -Value $Now.Subtract($_.OldestItemReceivedDate).Days
   } 

  } 

  $FolderStatistics 

 }
} 
