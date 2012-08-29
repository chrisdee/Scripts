## =====================================================================
## Title       : Get-IADSite
## Description : Retrieve the site(s) information for a forest or current site.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input              
##                     
## Output      : System.DirectoryServices.ActiveDirectory.ActiveDirectorySite, System.Object[]
## Usage       : 
##               1. Retrieve current site information 
##               Get-IADSite 
## 
##               2. Retrieve all sites in the current forest 
##               Get-IADSite -All 
##            
## Notes       :
## Tag         : site, activedirectory
## Change log  :
## =====================================================================





function Get-IADSite { 


    param (
        [switch]$All
    )

    if ($All) 
    {
        [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Sites
    }
    else 
    {
        [DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()
    }
}