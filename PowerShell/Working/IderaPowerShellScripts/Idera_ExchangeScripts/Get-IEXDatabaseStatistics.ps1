## =====================================================================
## Title       : Get-IEXDatabaseStatistics
## Description : Retrieve database info.
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXDatabaseStatistics [[-Server] <String>]
##   
## Output      : System.Management.Automation.PSCustomObject 
## Usage       : Get-IEXDatabaseStatistics -Server Exch1
##       
## Notes       :
## Tag         : Exchange 2007, database, mailbox, get
## Change log  :
## ===================================================================== 
  

#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

function Get-IEXDatabaseStatistics
{
 param(
  [string]$Server=$(Throw "parameter 'Server' cannot be empty")
 ) 
  
 trap { Throw $_} 
  
 $MbxCount = @{Name="MailboxCount";Expression={ $_.Count }}
 $TotalSize = @{Name="TotalSize(GB)";Expression={ "{0:N2}" -f (($_.group | Measure-Object TotalItemSize -Sum).Sum/1GB)}} 

 Get-MailboxStatistics -Server $Server | Group-Object Database | Select-Object Name,$MbxCount,$TotalSize
} 
