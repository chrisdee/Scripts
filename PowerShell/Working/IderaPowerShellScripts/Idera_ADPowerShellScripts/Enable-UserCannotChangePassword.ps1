## =====================================================================
## Title       : Enable-UserCannotChangePassword
## Description : Set the 'User Cannot Change Password' checkbox on the user account in ADUC.
##                   The user won't be able to change his password.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No input
##                                                       
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       : Get-IADUser Jim* | Enable-UserCannotChangePassword
##            
## Notes       :
## Tag         : user, password, activedirectory
## Change log  :
## =====================================================================


filter Enable-UserCannotChangePassword {




 if($_ -is [ADSI] -and $_.psbase.SchemaClassName -eq 'user')
 {
  $CHANGE_PASSWORD_GUID = "AB721A53-1E2F-11D0-9819-00AA0040529B"
  'S-1-1-0','S-1-5-10' | Foreach-Object {
   $si = [System.Security.Principal.SecurityIdentifier]$_
   $Deny = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($si,"ExtendedRight","Deny",$CHANGE_PASSWORD_GUID)   
   $user.psbase.ObjectSecurity.AddAccessRule($Deny)
  }   
  $_.psbase.CommitChanges()
  $_
 }
 else
 {
  Write-Warning "Invalid object type, only User objects are allowed"
 } 
}