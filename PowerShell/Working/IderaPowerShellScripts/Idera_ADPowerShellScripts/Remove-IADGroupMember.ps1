## =====================================================================
## Title       : Remove-IADGroupMember
## Description : Remove a member from a group in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : Remove-IADGroupMember [[-MemberDN] <String[]>]
##                     
## Output      : No output 
##
## Usage       :
##               1. Remove the domain administrator account to the QA group 
##               Get-IADGroup QA | Remove-IADGroupMember -MemberDN 'CN=Administrator,CN=Users,DC=domain,DC=com'  
## 
##               2. Remove multiple accounts to the QA group 
##               $members = Get-IADUser -Name QAUser* | Foreach-Object { $_.distinguishedName } 
##               Get-IADGroup QA | Remove-IADGroupMember -MemberDN $members         
## Notes       :
## Tag         : group, member, activedirectory
## Change log  :
## ===================================================================== 
 


filter Remove-IADGroupMember { 
 param(
  [string[]]$MemberDN=$(Throw "MemberDN cannot be empty")
 )  
  

 if($_ -is [ADSI] -and $_.psbase.SchemaClassName -eq 'group')
 {
  $group = $_
  trap {
   Write-Error $_
   continue
  } 


  $MemberDN | Where-Object {$_} | ForEach-Object { $null = $group.member.remove($_) } 

  $group.psbase.commitChanges() 


 }
 else
 {
  Write-Warning "Wrong object type, only Group objects are allowed"
 }
}