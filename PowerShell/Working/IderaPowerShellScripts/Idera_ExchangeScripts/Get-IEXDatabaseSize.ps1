## =====================================================================
## Title       : Get-IEXDatabaseSize 
## Description : Retrieve database size. It must be run on Exchange server.
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXDatabaseSize [[-Server] <String>]
##   
## Output      : System.Management.Automation.PSCustomObject
## Usage       : 
##              1. Retrieve database size on Exchange server Exch1
##              Get-IEXDatabaseSize -Server Exch1
##                        
## Notes       :
## Tag         : Exchange 2007, database, get
## Change log  :
## ===================================================================== 


#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 
 
function Get-IEXDatabaseSize
{
 
 param(
  [string]$Server=$env:COMPUTERNAME
 ) 
  

 if ((Get-MailboxServer).RedundantMachines)
 {
  $server = (Get-ClusteredMailboxServerStatus).Identity
 }
 
 $Size = @{Name="Size(MB)";Expression={"{0:N2}" -f ((Get-ChildItem $_.EdbFilePath).Length/1MB)}}
 Get-MailboxDatabase -Server $Server | Select-Object Server,Name,StorageGroupName,$Size
} 


   