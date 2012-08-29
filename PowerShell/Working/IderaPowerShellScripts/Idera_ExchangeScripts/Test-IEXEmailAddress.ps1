## =====================================================================
## Title       : Test-IEXEmailAddress
## Description : Check the validity of an email address. Returns $true for all valid email addresses, otherwise $false.
## Author      : Idera
## Date        : 09/15/2009
## Input       : Test-IEXEmailAddress [[-EmailAddress] <String>]
##  
## Output      : System.Boolean 
## Usage       : 1. Test email address user@domain.local
##               Test-EmailAddress -EmailAddress user@domain.local
## Notes       :
## Tag         : Exchange 2007, email address, validity, .NET Framework, test
## Change log  :
## =====================================================================

 
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 


function Test-IEXEmailAddress
{
 param(
  [string]$EmailAddress=$(throw "EmailAddress cannot be empty.")
 ) 
 
 ![Microsoft.Exchange.Data.SmtpProxyAddress]::Parse($EmailAddress).ParseException
} 
