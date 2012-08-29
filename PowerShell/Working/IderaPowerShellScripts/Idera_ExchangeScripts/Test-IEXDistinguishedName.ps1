## =====================================================================
## Title       : Test-IEXDistinguishedName
## Description : Check the validity of distinguished name string.
## Author      : Idera
## Date        : 09/15/2009
## Input       : Test-IEXDistinguishedName [[-dn] <String>]
##  
## Output      : System.Boolean
## Usage       : Test-IEXDistinguishedName "OU=DisabledUsers,DC=domain,DC=com"
##    
## Notes       :
## Tag         : Exchange 2007, distinguished name, validity, .NET Framework, test
## Change log  :
## =====================================================================
 
 
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

function Test-IEXDistinguishedName
{
    param(
        [string]$dn
    )
   
   [Microsoft.Exchange.Data.Directory.ADObjectId]::IsValidDistinguishedName($dn)
}
 