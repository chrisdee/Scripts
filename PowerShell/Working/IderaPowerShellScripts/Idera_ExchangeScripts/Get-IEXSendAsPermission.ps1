## =====================================================================
## Title       : Get-IEXSendAsPermission
## Description : Retrieve the users that have "Send As" permission.
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXSendAsPermission [[-Server] <String>] [-Inherited]
##  
## Output      : Microsoft.Exchange.Management.RecipientTasks.ADAcePresentationObject
## Usage       :
##               1. Retrieve the users that have "Send As" permission.
##               Get-IEXSendAsPermission -Server Exch1 | Select-Object Identity,User
##           
## Notes       :
## Tag         : Exchange 2007, mailbox, permission, get
## Change log  :
## =====================================================================
  
 
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 
 
function Get-IEXSendAsPermission
{
 param(


  [string]$Server = $(Throw 'Please, specify a server name.'), 

  [switch]$Inherited
 )
 
 Get-Mailbox -ResultSize Unlimited -Server $server | Get-ADPermission | Where-Object { ($_.ExtendedRights -like "*Send-As*") -AND ($_.IsInherited -eq $Inherited) -AND ($_.User -notlike "*NT AUTHORITY\SELF*") } 

} 
