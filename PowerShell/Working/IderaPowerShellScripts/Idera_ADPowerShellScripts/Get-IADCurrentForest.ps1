## =====================================================================
## Title       : Get-IADCurrentForest
## Description : Retrieve current forest information like Domains, Sites, ForestMode, RootDomain, and Forest masters.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input          
##                     
## Output      : System.DirectoryServices.ActiveDirectory.Forest
## Usage       : 
##               1. Retrieve the global catalogs information
##               (Get-IADCurrentForest).GlobalCatalogs
## Notes       :
## Tag         : forest, activedirectory
## Change log  :
## =====================================================================


function Get-IADCurrentForest {  
 [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
} 