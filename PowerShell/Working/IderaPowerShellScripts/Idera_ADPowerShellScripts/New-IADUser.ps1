## =====================================================================
## Title       : New-IADUser
## Description : Create a new user object in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : New-IADUser [[-Name] <String>] [[-sAMAccountName] <String>] [[-ParentContainer] <String>] [[-Password] <String>]             
##                     
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       :
##               1. Create new user in the Test OU and enable the account
##               New-IADUser -Name 'Idera User' -sAMAccountname 'IUser' -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd' -EnableAccount
##
##               2. Create new user in the Test OU and enable the account. The user will have to change password at next logon
##               New-IADUser -Name 'Idera User' -sAMAccountname 'IUser' -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd' -EnableAccount -UserMustChangePassword
##
##               3.Create new user in the Test OU and enable the account. The user password will not expire.
##               New-IADUser -Name 'Idera User' -sAMAccountname 'IUser' -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd' -EnableAccount -PasswordNeverExpires
##
##               4. Create disabled users from text file in the Test OU (spaces are not allowed in sAMAccountName )
##               Get-Content users.txt | foreach { New-IADUser -Name $_ -sAMAccountName ($_ -replace " ") -ParentContainer 'OU=TEST,DC=Domain,DC=com' -Password 'P@ssw0rd'} 
##            
## Notes       :
## Tag         : user, activedirectory
## Change log  :
## =====================================================================

function New-IADUser {  

 param(
  [string]$Name = $(Throw "Please enter a full user name."),
  [string]$sAMAccountName = $(Throw "Please enter a sAMAccountname."),
  [string]$ParentContainer = $(Throw "Please enter a parent container DN."),
  [string]$Password = $(Throw "Password cannot be empty"),
  [switch]$UserMustChangePassword,
  [switch]$PasswordNeverExpires,
  [switch]$EnableAccount
 ) 
  
 if($sAMAccountName -match '\s') 
 { 
    Write-Error "sAMAccountName cannot contain spaces"

    return 
 } 
  
  if( ![ADSI]::Exists("LDAP://$ParentContainer"))
  {
   Write-Error "ParentContainerject '$ParentContainer' doesn't exist" 
   return 
  }



 $filter = "(&(objectCategory=Person)(objectClass=User)(samaccountname=$sAMAccountname))"
 $root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
 $searcher = New-Object System.DirectoryServices.DirectorySearcher $filter
 $searcher.SearchRoot= "LDAP://"+$root.defaultNamingContext
 $searcher.SizeLimit = 0
 $searcher.PageSize = 1000
 $result = $searcher.FindOne() 
  
 if($result)
 {
  Throw "User with the same sAMAccountname already exists in your domain."
 } 

 if($UserMustChangePassword -and $PasswordNeverExpires) 
 {
  $err = 'You specified that the password should never expire.'
  $err += ' The user will not be required to change the password at next logon.'
  Write-Warning $err
 } 
  
 $Container = [ADSI]"LDAP://$ParentContainer"
 $user = $Container.Create("user","cn=$Name") 
 if($Name -match '\s')
 {
  $n = $Name.Split()
  $FirstName = $n[0]
  $LastName = "$($n[1..$n.length])"
  $null = $user.put("sn",$LastName)
 }
 else
 {
  $FirstName = $Name
 }
   
 $null = $user.put("givenName",$FirstName)
 $null = $user.put("displayName",$Name) 
 $suffix = $root.defaultNamingContext -replace "dc=" -replace ",","."
 $upn = "$samaccountname@$suffix"
 $null = $user.put("userPrincipalName",$upn)
 $null = $user.put("sAMAccountName",$sAMAccountName)
 $null = $user.SetInfo() 
 
 
 trap
 {
  $pwdPol = "The password does not meet the password policy requirements"
  $InnerException=$_.Exception.InnerException 
  if($InnerException -match $pwdPol)
  {
   $script:PasswordChangeError=$true
   Write-Error $InnerException
  }
  else
  {
   Write-Error $_
  } 
  continue
 }
  
 $null = $user.psbase.Invoke("SetPassword",$Password)
   
 
 if($UserMustChangePassword)
 {
  $null = $user.pwdLastset=0
 } 
 if($PasswordNeverExpires)
 {
  $null = $user.userAccountControl[0] = $user.userAccountControl[0] -bor 65536
 } 
 
 if($EnableAccount)
 {
  if($script:PasswordChangeError)
  {
   Write-Warning "Accound cannot be enabled since setting the password did not succeed."   
  }
  else
  {
   $null = $user.psbase.InvokeSet("AccountDisabled",$false)
  }
 }
 else
 {
  $null = $user.psbase.InvokeSet("AccountDisabled",$true)
 } 
 $null = $user.SetInfo()
 $user 
}