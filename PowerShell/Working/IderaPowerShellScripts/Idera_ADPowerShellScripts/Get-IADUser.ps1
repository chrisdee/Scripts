## =====================================================================
## Title       : Get-IADUser
## Description : Retrieve all users in a domain or container.
## Author      : Idera
## Date        : 8/11/2009
## Input       : Get-IADUser [[-Name] <String>] [[-SearchRoot] <String>] [[-PageSize] <Int32>] [[-SizeLimit] <Int32>] [[-SearchScope] <String>]
##                     
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       : 
##                1. Get all user objects from the domain 
##                Get-IADUser 
##
##                2. Get all disabled users which name starts with J 
##                Get-IADUser -Name J* -Disabled 
##
##                3. Get 10 user accounts from the Developers OU 
##                Get-IADUser -SizeLimit 10 -SearchRoot 'OU=Developers,DC=domain,DC=com' 
##
##                4. Get all enabled users with non-expiring passwords
##                Get-IADUser -Enabled  -PasswordNeverExpires
##          
## Notes       :
## Tag         : user, activedirectory
## Change log  :
## =====================================================================
  
function Get-IADUser {

 
param(
  [string]$Name = "*",
  [string]$SearchRoot,
  [int]$PageSize = 1000,
  [int]$SizeLimit = 0,
  [string]$SearchScope = "SubTree",
  [switch]$Enabled,
  [switch]$Disabled,
  [switch]$AccountNeverExpires,
  [switch]$PasswordNeverExpires
 )
 
 
 if($SearchScope -notmatch '^(Base|OneLevel|Subtree)$')
 {
     Throw "SearchScope Value must be one of: 'Base','OneLevel or 'Subtree'"
 }
 
 $resolve = "(|(sAMAccountName=$Name)(cn=$Name)(displayName=$Name)(givenName=$Name))"
 
 if($Enabled) {$Enabledf = "(!userAccountControl:1.2.840.113556.1.4.803:=2)"}
 if($Disabled) {$Disabledf = "(userAccountControl:1.2.840.113556.1.4.803:=2)"}


 if($Enabled) {$EnabledDisabledf = $Enabledf}
 if($Disabled) {$EnabledDisabledf = $Disabledf}
 if($Enabled -and $Disabled) { $EnabledDisabledf = ""}

 if($AccountNeverExpires) {$AccountNeverExpiresf = "(|(accountExpires=9223372036854775807)(accountExpires=0))"}
 if($PasswordNeverExpires) {$PasswordNeverExpiresf = "(userAccountControl:1.2.840.113556.1.4.803:=65536)"}

 $filter = "(&(objectCategory=Person)(objectClass=User)$EnabledDisabledf$AccountNeverExpiresf$PasswordNeverExpiresf$resolve)"

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