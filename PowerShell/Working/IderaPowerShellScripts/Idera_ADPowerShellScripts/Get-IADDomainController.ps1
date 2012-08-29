## =====================================================================
## Title       : Get-IADDomainController
## Description : Retrieve domain controller information.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input                 
##                      
## Output      : System.Object[]
## Usage       : Get-IADDomainController
##             
## Notes       :
## Tag         : domain, domaincontroller, activedirectory
## Change log  :
## =====================================================================   
 
function Get-IADDomainController { 
   [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().DomainControllers
}