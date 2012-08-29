## =====================================================================
## Title       : Get-IADEmptyGroup
## Description : Retrieve all groups without members in a domain or container.
## Author      : Idera
## Date        : 8/11/2009
## Input       : Get-IADEmptyGroup [[-SearchRoot] <String>] [[-PageSize] <Int32>] [[-SizeLimit] <Int32>] [[-SearchScope] <String>] 
##                     
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       : Get-IADEmptyGroup
##            
## Notes       :
## Tag         : group, member, activedirectory
## Change log  :
## =====================================================================

  
function Get-IADEmptyGroup 
{

  
param(
 [string]$SearchRoot,
 [int]$PageSize = 1000,
 [int]$SizeLimit = 0,
 [string]$SearchScope = "SubTree"
) 
 

$filter = "(&(objectClass=group)(!member=*))"
 
$root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
$searcher = New-Object System.DirectoryServices.DirectorySearcher $filter 

        
if($SearchRoot -eq [string]::Empty)
{
 $SearchRoot=$root.defaultNamingContext
} 

$searcher.SearchRoot = "LDAP://$SearchRoot"
$searcher.SearchScope = $SearchScope
$searcher.SizeLimit = $SizeLimit
$searcher.PageSize = $PageSize
$searcher.FindAll() | Foreach-Object { $_.GetDirectoryEntry() } 

}