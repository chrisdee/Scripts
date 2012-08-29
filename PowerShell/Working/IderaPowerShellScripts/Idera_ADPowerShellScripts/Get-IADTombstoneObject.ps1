## =====================================================================
## Title       : Get-IADTombstoneObject
## Description : Retrieve all deleted objects in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input                
##                     
## Output      : System.DirectoryServices.SearchResult
## Usage       : Get-IADTombstoneObject
##            
## Notes       :
## Tag         : tombstone, deleted, activedirectory
## Change log  :
## =====================================================================


function Get-IADTombstoneObject 
 {

  $root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
  $searcher = New-Object System.DirectoryServices.DirectorySearcher($root.defaultNamingContext)
  $searcher.Filter = "(&(isDeleted=TRUE))"
  $searcher.tombstone = $true
  $searcher.FindAll() 
}