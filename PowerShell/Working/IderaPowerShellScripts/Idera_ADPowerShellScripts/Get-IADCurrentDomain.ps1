## =====================================================================
## Title       : Get-IADCurrentDomain
## Description : Retrieve current domain information like Domain Controllers, DomainMode, Domain Masters, and Forest Root.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input
##                                     
## Output      : System.DirectoryServices.ActiveDirectory.Domain 
## Usage       :
##               1. Retrieve domain FSMO roles holders 
##               Get-IADCurrentDomain | Select-Object *owner 
## 
##               2. Retrieve domain controllers for the current domain 
##               Get-IADCurrentDomain | Select-Object -ExpandProperty DomainControllers
## Notes       :
## Tag         : domain, activedirectory
## Change log  :
## =====================================================================


  
function Get-IADCurrentDomain { 
 [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
}