## =====================================================================
## Title       : Get-IADGroupMember
## Description : Retrieve the members of a group in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No Input
##                     
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       :
##               1. Retrieve all members of a group TestGroup
##               Get-IADGroup TestGroup | Get-IADGroupMember
##            
## Notes       :
## Tag         : group, member, activedirectory
## Change log  :
## =====================================================================
  
filter Get-IADGroupMember {
param (
[switch]$Resolve
) 
  

 if($_ -is [ADSI] -and $_.psbase.SchemaClassName -eq 'group')
 {
  if ($Resolve) {
   $_.member |foreach {[ADSI]"LDAP://$_"}
  }
  else {
   $_.member
  }
 }
 else
 {
  Write-Warning "Invalid object type. Only 'Group' objects are allowed"
 }
} 