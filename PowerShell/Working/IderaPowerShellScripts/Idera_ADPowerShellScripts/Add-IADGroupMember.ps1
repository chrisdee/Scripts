## =====================================================================
## Title       : Add-IADGroupMember
## Description : Add one or more objects to a group in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : Add-IADGroupMember [[-MemberDN] <String[]>]
##                     
## Output      : No Output
## Usage       :
##               1. Add the domain administrator account to the QA group 
##               Get-IADGroup QA | Add-IADGroupMember -MemberDN 'CN=Administrator,CN=Users,DC=domain,DC=com'  
## 
##               2. Add multiple accounts to the QA group 
##               $members = Get-IADUser -Name QAUser* | Foreach-Object { $_.distinguishedName } 
##               Get-IADGroup QA | Add-IADGroupMember -MemberDN $members 
##            
## Notes       :
## Tag         : group, member, activedirectory
## Change log  :
## =====================================================================


filter Add-IADGroupMember {
 param(
 [string[]]$MemberDN = $(Throw "MemberDN cannot be empty.") 
)
 

 if($_ -is [ADSI] -and $_.psbase.SchemaClassName -eq 'group')
 {
  $group = $_
  trap {
   Write-Error $_
   continue
  } 


  $MemberDN | Where-Object {$_} | ForEach-Object { $null = $group.member.add($_) } 

  $group.psbase.commitChanges()
 }
 else
 {
  Write-Warning "Wrong object type, only Group objects are allowed."
 }
}