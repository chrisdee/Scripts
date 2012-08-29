## =====================================================================
## Title       : Get-IEXEmailAddressReport
## Description : Enumerate email addresses
## Author      : Idera
## Date        : 09/15/2009
## Input       : No input
##   
## Output      : System.Management.Automation.PSCustomObject 
## Usage       : 
##              1. Enumerate email addresses per user
##              Get-IEXEmailAddressReport -Server ExchangeServerName
##       
## Notes       :
## Tag         : Exchange 2007, mailbox, email address, get
## Change log  :
## ===================================================================== 
 
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

function Get-IEXEmailAddressReport
{ 

 param(
  [string]$Server = $(Throw 'Please, specify a server name.'), 
  [Microsoft.Exchange.Configuration.Tasks.OrganizationalUnitIdParameter]$OrganizationalUnit = $null  
 ) 

 Get-Mailbox -ResultSize unlimited -Server $Server -OrganizationalUnit $OrganizationalUnit | Select-Object DisplayName -ExpandProperty EmailAddresses | Where-Object {$_.SmtpAddress} | Select-Object DisplayName,SmtpAddress 

} 
