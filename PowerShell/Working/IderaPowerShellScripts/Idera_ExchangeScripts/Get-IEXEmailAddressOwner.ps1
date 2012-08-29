## =====================================================================
## Title       : Get-IEXEmailAddressOwner
## Description : Find who owns an email address
## Author      : Idera
## Date        : 09/15/2009
## Input       : Get-IEXEmailAddressOwner [[-EmailAddress] <String>]
##  
## Output      : Microsoft.Exchange.Data.Directory.Management.Mailbox
## Usage       :    
##              1. Get mailbox owner of a specific email address 
##              Get-IEXEmailAddressOwner -EmailAddress <EmailAddress>        
##
##              2. Get mailbox owner of a specific email address, expand all mailbox email addresses
##              Get-IEXEmailAddressOwner -EmailAddress <EmailAddress>  | Select-Object -ExpandProperty EmailAddresses      
## Notes       :
## Tag         : Exchange 2007, mailbox, email address, owner, get
## Change log  :
## =====================================================================
 
 
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 
 
function Get-IEXEmailAddressOwner
{

 param(
  [string]$EmailAddress
 )

 
    if([Microsoft.Exchange.Data.SmtpProxyAddress]::Parse($EmailAddress).ParseException)
    {
        Throw "Invalid email address: '$EmailAddress'"
    } 

    Get-Mailbox -Filter {EmailAddresses -eq $EmailAddress}
}

