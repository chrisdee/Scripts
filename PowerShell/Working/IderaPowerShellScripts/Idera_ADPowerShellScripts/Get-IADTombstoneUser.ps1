## =====================================================================
## Title       : Get-IADTombstoneUser
## Description : Retrieve all deleted users in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input               
##                     
## Output      : System.DirectoryServices.SearchResult
## Usage       : Get-IADTombstoneUser
##            
## Notes       :
## Tag         : user, tombstone, deleted, activedirectory
## Change log  :
## =====================================================================

function Get-IADTombstoneUser 
{

$root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
$searcher = New-Object System.DirectoryServices.DirectorySearcher($root.defaultNamingContext)
$searcher.Filter = "(&(isDeleted=TRUE)(objectClass=User)(!(samaccountname=*$)))"
$searcher.tombstone = $true
$searcher.FindAll()
}