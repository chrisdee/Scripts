## =====================================================================
## Title       : Get-IADSubnet
## Description : Retrieve the subnets in a forest or current site.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input             
##                     
## Output      : System.Management.Automation.PSCustomObject
## Usage       : 
##               1. Retrieve all subnets in the current site 
##               Get-IADSubnet 
## 
##               2. Retrieve all subnets in the current forest 
##               Get-IADSubnet -All
## Notes       :
## Tag         : subnet, site, activedirectory
## Change log  :
## =====================================================================


function Get-IADSubnet 
{

    param (
        [switch]$All
    )

    if ($All) 
   {
        $sites = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Sites
        $sites | Select-Object -ExpandProperty Subnets
    }
    else 
    {
        $currentSite = [DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()
        $currentSite | Select-Object -ExpandProperty Subnets
    }
}