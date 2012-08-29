## =====================================================================
## Title       : Set-IADUser
## Description : Modify attributes of a user object in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       :   Set-IADUser [[-DistinguishedName] <String>] [[-sAMAccountname] <String>] [[-FirstName] <String>] [[-LastName] <String>]
##                     [[-Initials] <String>] [[-Description] <String>] [[-UserPrincipalName] <String>] [[-DisplayName] <String>] 
##                     [[-Office] <String>] [[-Department] <String>] [[-ManagerDN] <String>] [[-EmployeeID] <String>] [[-EmployeeNumber] <String>]
##                     [[-HomeDirectory] <String>] [[-HomeDrive] <String>] [[-Mobile] <String>] [[-Password] <String>] 
##                     [[-UserMustChangePassword] <Object>] [[-PasswordNeverExpires] <Object>]
##   
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       :
##               1. Sets the FirstName, LastName and Initials of a user
##               Get-IADUser User1 | Set-IADUser -FirstName Heli -LastName Copter -Initials HC
##
##               2. Set the HomeDirectory and HomeDrive for User1
##               Get-IADUser User1 | Set-IADUser -HomeDirectory '\\server\share\user1' -HomeDrive 'H:'
##
##               3. Set the Office attribute for all users in the Test OU
##               Get-IADUser -SearchRoot 'OU=TEST,DC=Domain,DC=com' | Set-IADUser -Description TestUsers -Office QA
##
##               4. Set the Description attribute for all users in the Test OU and password to never expiry
##               Get-IADUser -SearchRoot 'OU=TEST,DC=Domain,DC=com' | Set-IADUser -Description TestUsers -PasswordNeverExpires  
##            
## Notes       :
## Tag         : user, activedirectory
## Change log  :
## =====================================================================


filter Set-IADUser {
 param(
  [string]$DistinguishedName,
  [string]$sAMAccountname,
  [string]$FirstName,
  [string]$LastName,
  [string]$Initials,
  [string]$Description,
  [string]$UserPrincipalName,
  [string]$DisplayName,
  [string]$Office,
  [string]$Department,
  [string]$ManagerDN,
  [string]$EmployeeID,
  [string]$EmployeeNumber,
  [string]$HomeDirectory,
  [string]$HomeDrive,
  [string]$Mobile,
  [string]$Password,
  $UserMustChangePassword,
  $PasswordNeverExpires  
 ) 
  


 
 function Convert-IADSLargeInteger([object]$LargeInteger){
  
  $type = $LargeInteger.GetType()
  $highPart = $type.InvokeMember("HighPart","GetProperty",$null,$LargeInteger,$null)
  $lowPart = $type.InvokeMember("LowPart","GetProperty",$null,$LargeInteger,$null)
 
  $bytes = [System.BitConverter]::GetBytes($highPart)
  $tmp = New-Object System.Byte[] 8
  [Array]::Copy($bytes,0,$tmp,4,4)
  $highPart = [System.BitConverter]::ToInt64($tmp,0)
  $bytes = [System.BitConverter]::GetBytes($lowPart)
  $lowPart = [System.BitConverter]::ToUInt32($bytes,0)
 
  $lowPart + $highPart
 } 
  

 if($_ -is [ADSI] -and $_.psbase.SchemaClassName -eq 'User')
 {
  $user = $_
 }
 else
 {
     if($DistinguishedName)
     {    
   if(![ADSI]::Exists("LDAP://$DistinguishedName"))
      {
       Write-Error "The user '$DistinguishedName' doesn't exist"
       return
      }
      else
      { 
       $user = [ADSI]"LDAP://$DistinguishedName"
      }
     }
  else
  {
   Write-Error "'DistinguishedName' cannot be empty."
   return   
  }
 }
  
 if($sAMAccountname)
 {
  $null = $user.put("sAMAccountname",$sAMAccountname)
 }
 
 if ($FirstName)
 {
  $null = $user.put("givenName",$FirstName)
 } 
 
 if ($LastName)
 {
  $null = $user.put("sn",$LastName)
 } 
 
 if ($Initials)
 {
  $null = $user.put("initials",$Initials)
 } 
 
 if ($Description)
 {
  $null = $user.put("Description",$Description)
 }
 
 if ($UserPrincipalName)
 {
  $null = $user.put("userPrincipalName",$UserPrincipalName)
 }
 
 if ($UserPrincipalName)
 {
  $null = $user.put("userPrincipalName",$UserPrincipalName)
 }
 
 if($DisplayName)
 {
  $null = $user.put("displayName",$DisplayName)
 }
 
 if ($Office)
 {
  $null = $user.put("physicalDeliveryOfficeName",$Office)
 } 
 
 if ($Department)
 {
  $null = $user.put("department",$Department)
 } 
 
 if($ManagerDN)
 {
  if( ![ADSI]::Exists("LDAP://$ManagerDN"))
  {
   Write-Warning "Manager object '$ManagerDN' doesn't exist"
  }
  else
  {
   $m = [ADSI]"LDAP://$ManagerDN"
   if($m.psbase.SchemaClassName -notmatch 'User|Contact')
   {
    Throw "Wrong object type. Must be 'User' or 'Contact'."
   }
   else
   {
    $null = $user.put("manager",$ManagerDN)
    $null = $user.SetInfo() 
   } 
  }
 }
 
 if($EmployeeID)
 {
  $null = $user.psbase.Invoke("employeeID",$EmployeeID)             
 } 
 
 if($EmployeeNumber)
 {
  $null = $user.psbase.Invoke("employeeNumber",$EmployeeNumber)             
 }
 
 if($HomeDirectory)
 {
  $null = $user.psbase.Invoke("homeDirectory",$HomeDirectory)             
 }
 
 if($HomeDrive)
 {
  $null = $user.psbase.Invoke("homeDrive",$HomeDrive)             
 }
 
 if($Mobile)
 {
  $null = $user.psbase.InvokeSet("mobile",$Mobile)             
 }
 
 if($Password)
 {
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
  $null = $user.psbase.Invoke("setpassword",$Password)             
 } 

 if($UserMustChangePassword -is [bool])
 {
  if($UserMustChangePassword)
  {
   if ($user.userAccountControl[0] -band 65536)
   {
    $err = 'The password is already set to never expire.'
    $err += ' The user will not be required to change the password at next logon.'
    Write-Warning $err
   }
   elseif ($PasswordNeverExpires -and $PasswordNeverExpires -is [bool])
   {
    $err = 'You specified that the password should never expire.'
    $err += ' The user will not be required to change the password at next logon.'
    Write-Warning $err
   }
   else
   {
    $null = $user.pwdLastset=0
   }
  }
 }
 else
 {
  if($UserMustChangePassword -ne $null)
  {
   Write-Error "Parameter UserMustChangePassword only accept booleans, use $true, $false, 1 or 0 instead."
  }
 } 
  

 if($PasswordNeverExpires -is [bool])
 {
  if($PasswordNeverExpires)
  {
   $pwdLastSet = Convert-IADSLargeInteger $user.pwdLastSet[0]
   
   if ($pwdLastSet -eq 0)
   {
    $err = 'You specified that the password should never expire.'
    $err += "The attribute 'User must change password at next logon' will be unchecked."
    Write-Warning $err
   }
   
   $user.userAccountControl[0] = $user.userAccountControl[0] -bor 65536
  }
 }
 else
 {
  if($PasswordNeverExpires -ne $null)
  {
   Write-Error "Parameter PasswordNeverExpires only accept booleans, use $true, $false, 1 or 0 instead."
  }
 } 
 $null = $user.SetInfo()
 $user
}