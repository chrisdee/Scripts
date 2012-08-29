## =====================================================================
## Title       : Get-IADObjectSID
## Description : Retrieve AD object's SID.
## Author      : Idera
## Date        : 8/11/2009
## Input       : Get-IADObjectSID [[-InputObject] <Object>]
##                     
## Output      : System.String
## Usage       : 
##               1. Get the SID of the domain administrator account 
##               Get-IADObjectSID -InputObject (Get-IADUser -Name Administrator) 
## 
##               2. Get the SID using the object's DN 
##               Get-IADObjectSID -InputObject 'CN=Guest,CN=Users,DC=Domain,DC=com' 
##            
## Notes       :
## Tag         : security, activedirectory
## Change log  :
## =====================================================================

function Get-IADObjectSID 
{ 

    param (
      $InputObject
    )  

 
 $type = $InputObject.psbase.GetType().Name
 
 if($type -notmatch '^(string|DirectoryEntry)$')
 {
  Throw "InputObject must of type 'String' or 'ADSI'"
 } 

  
 switch($type)
 {
  "DirectoryEntry"
  {
   $Object=$InputObject
   break
  }  
  "String"
  {   
   if(![ADSI]::Exists("LDAP://$InputObject"))
   {
    Throw "ADSI Object '$InputObject' doesn't exist"
   }
   else
   {
    $Object = [ADSI]"LDAP://$InputObject"
    break   
   }
  }
 } 
 
 $objectSid = [byte[]]$Object.objectSid.value
 $sid = new-object System.Security.Principal.SecurityIdentifier $objectSid,0
 $sid.value
}