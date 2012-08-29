## =====================================================================
## Title       : Test-IEXEmailAddress2
## Description : Check the validity of an email address. Returns $true for all valid email addresses, otherwise $false.
## Author      : Idera
## Date        : 09/15/2009
## Input       : Test-IEXEmailAddress2 [[-EmailAddress] <String>]
##  
## Output      : System.Boolean 
## Usage       :
##               1. Test email address user2@domain.local
##               Test-EmailAddress2 -EmailAddress user2@domain.local
## Notes       :
## Tag         : email address, validity, .NET Framework, test
## Change log  :
## ===================================================================== 


function Test-IEXEmailAddress2

{
    param (
        [string]$EmailAddress=$(throw "EmailAddress cannot be empty.")
    )  
    
    ($EmailAddress -as [System.Net.Mail.MailAddress]).Address -eq $EmailAddress -and $EmailAddress -ne $null 
} 

  