## =====================================================================
## Title       : Get-IADDomainController2
## Description : Retrieve domain controllers.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input
##                                    
## Output      : System.Object[]
## Usage       : Get-IADDomainController2 -descending
##            
## Notes       :
## Tag         : domain, domaincontroller, activedirectory
## Change log  :
## =====================================================================


function Get-IADDomainController2 { 
  
 param ( 
  [switch]$descending

 )   
  
 $domaindn = ([ADSI]"").distinguishedName 
 $searcher = New-Object System.DirectoryServices.DirectorySearcher
 $searcher.searchroot = "LDAP://OU=Domain Controllers,$domaindn"
 $searcher.filter = "objectCategory=computer"
 $searcher.sort.propertyname = "name"
 
 if ($descending)
 {
  $searcher.sort.direction = "Descending"
 } 
  
 $searcher.FindAll() | Foreach-Object { $_.GetDirectoryEntry() }
}