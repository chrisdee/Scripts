## =====================================================================
## Title       : Get-IADTombstoneComputer
## Description : Retrieve all deleted computers in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input            
##                     
## Output      : System.DirectoryServices.SearchResult
## Usage       : Get-IADTombstoneComputer
##            
## Notes       :
## Tag         : computer, tombstone, deleted, activedirectory
## Change log  :
## =====================================================================

   
function Get-IADTombstoneComputer 
{ 
 $root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
 $searcher = New-Object System.DirectoryServices.DirectorySearcher($root.defaultNamingContext)
 $searcher.Filter = "(&(isDeleted=TRUE)(objectClass=User)(samaccountname=*$))"
 $searcher.tombstone = $true
 $searcher.FindAll()
}