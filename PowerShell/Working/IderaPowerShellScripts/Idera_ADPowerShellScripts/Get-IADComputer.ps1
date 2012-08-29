## =====================================================================
## Title       : Get-IADComputer
## Description : Retrieve all computer objects in a domain or container.
## Author      : Idera
## Date        : 8/11/2009
## Input       : Get-IADComputer [[-Name] <String>] [[-SearchRoot] <String>] [[-PageSize] <Int32>] [[-SizeLimit] <Int32>] [[-SearchScope] <String>]
##                     
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       : 
##               1. Get all domain enabled computers which name starts with WRK
##               Get-IADComputer -Name WRK* -Enabled 
##
##               2. Get all disabled computers from the Computers container
##               Get-IADComputer -SearchRoot 'CN=Computers,DC=Domain,DC=com' -Disabled 
##
## Notes       :
## Tag         : computer, activedirectory
## Change log  :
## =====================================================================



function Get-IADComputer { 
 param(
  [string]$Name = "*",
  [string]$SearchRoot,
  [int]$PageSize = 1000,
  [int]$SizeLimit = 0,
  [string]$SearchScope = "SubTree",
  [switch]$Enabled, 
  [switch]$Disabled
 ) 
  



 if($SearchScope -notmatch '^(Base|OneLevel|Subtree)$')
 {
     Throw "SearchScope Value must be one of: 'Base','OneLevel or 'Subtree'"
 }   
  

 $resolve = "(|(sAMAccountName=$Name)(cn=$Name)(displayName=$Name)(dNSHostName=$Name)(name=$Name))"    
  
if($Enabled) {$Enabledf = "(!userAccountControl:1.2.840.113556.1.4.803:=2)"}
 if($Disabled) {$Disabledf = "(userAccountControl:1.2.840.113556.1.4.803:=2)"}

 if($Enabled) {$EnabledDisabledf = $Enabledf}
 if($Disabled) {$EnabledDisabledf = $Disabledf}
 if($Enabled -and $Disabled) { $EnabledDisabledf = ""}


 $filter = "(&(objectCategory=Computer)(objectClass=User)$EnabledDisabledf$resolve)"

 $root= New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
 $searcher = New-Object System.DirectoryServices.DirectorySearcher $filter   
 if($SearchRoot -eq [string]::Empty) {$SearchRoot=$root.defaultNamingContext}  
 $searcher.SearchRoot = "LDAP://$SearchRoot"
 $searcher.SearchScope = $SearchScope
 $searcher.SizeLimit = $SizeLimit
 $searcher.PageSize = $PageSize
 $searcher.FindAll() | Foreach-Object { $_.GetDirectoryEntry() }
}