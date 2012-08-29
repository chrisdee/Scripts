## =====================================================================
## Title       : Get-IADGroupMembership
## Description : Retrieve all groups to which an object belongs.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No Input
##                     
## Output      : System.DirectoryServices.DirectoryEntry,System.String
## Usage       :
##               1. Retrieve all groups to which computer Server1 belongs and return the results as DirectoryEntry types
##               Get-IADComputer Server1 | Get-IADGroupMembership -Resolve
##
##               2. Retrieve all groups to which user Test1 belongs, including nested ones
##               Get-IADUser Test1 | Get-IADGroupMembership -ExpandNested
##            
## Notes       :
## Tag         : group, member, activedirectory
## Change log  :
## =====================================================================


filter Get-IADGroupMembership {
 param(
  [switch]$ExpandNested,
  [switch]$Resolve
 ) 
  
  
 if($_ -is [ADSI] -and $_.MemberOf)
 {
  trap
  {
   Write-Error $_
   continue
  } 
  $_.MemberOf | foreach {
  
   if($Resolve)
   {
    $group = [ADSI]"LDAP://$_"       
    $group
    
    if($ExpandNested)
    {     
     $group  | Get-IADGroupMembership -ExpandNested:$ExpandNested -Resolve:$Resolve  
    }   
   }
   elseif($ExpandNested)
   {
    $group = [ADSI]"LDAP://$_"       
    $group  
    $group | Get-IADGroupMembership -ExpandNested:$ExpandNested 
   }
   else
   {
    $_
   }
  }
 }
}