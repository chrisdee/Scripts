## =====================================================================
## Title       : Get-IEXMailboxStatistics
## Description : Retrieve extended mailbox statistics information. 
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXMailboxStatistics [[-Server] <String>] [[-Identity] <String>] [[-AddUserProperties] <String[]>]
##   
## Output      : Microsoft.Exchange.Data.Mapi.MailboxStatistics, System.Management.Automation.PSCustomObject
## Usage       : 
##               1. Get mailbox statistics for all mailboxes on a server and extend the results with mailbox user's SamAccountName,FirstName,LastName attributes 
##               Get-IEXMailboxStatistics -Server ServerName -AddUserProperties SamAccountName,FirstName,LastName  
## 
##               2. Get mailbox statistics for a specified mailbox and extend the result with the mailbox user's SamAccountName,FirstName,LastName 
##               Get-IEXMailboxStatistics -Identity Administrator -AddUserProperties SamAccountName,FirstName,LastName | Select SamAccountName,FirstName,LastName,ItemCount,TotalItemSize,DatabaseName 
##       
## Notes       :
## Tag         : Exchange 2007, mailbox, statistics, get
## Change log  :
## ===================================================================== 
  

#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin  
 

function Get-IEXMailboxStatistics
{
 param(
  [string]$Server,
  [string]$Identity,
  [string[]]$AddUserProperties
 )
 
 
 if($Server -AND $Identity)
 {
  Throw "Parameter set cannot be resolved using the specified named parameters."
 }
 
 if($Server)
 {
  if($AddUserProperties)
  {
   Get-MailboxStatistics -Server $Server | Where-Object {$_.ObjectClass -eq 'mailbox'} | Foreach-Object {
   
    $user = Get-User $_.DisplayName
    $mbx = $_
   
    $AddUserProperties | Foreach-Object {   
     Add-Member -InputObject $mbx -MemberType NoteProperty -Name $_ -Value $user.$_
    }
   
    $mbx
   }
  }
  else
  {
   Get-MailboxStatistics -Server $Server
  }
 }
 
 if($Identity)
 { 
  if($AddUserProperties)
  {
   $mbx = Get-MailboxStatistics -Identity $Identity
  
   if($mbx.ObjectClass -eq 'mailbox')
   {  
    $user = Get-User $mbx.DisplayName
    $AddUserProperties | Foreach-Object {   
     Add-Member -InputObject $mbx -MemberType NoteProperty -Name $_ -Value $user.$_
    }
    $mbx
   }
   else
   {
    Write-Error "$Identity has no AD user, no additional properties attached."
    Get-MailboxStatistics -Identity $Identity
   }
  }
  else
  {
   Get-MailboxStatistics -Identity $Identity 
  }
 }
}
 