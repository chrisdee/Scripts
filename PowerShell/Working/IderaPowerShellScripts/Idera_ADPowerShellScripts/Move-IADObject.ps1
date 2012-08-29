## =====================================================================
## Title       : Move-IADObject
## Description : Move one or more objects to a different container in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : Move-IADObject [[-ObjectDN] <Object[]>] [[-NewLocationDN] <String>]                
##                     
## Output      : No output
## Usage       : 
##               1. Get all users which name starts with Test and move them to the Test OU 
##               Get-IADUser test* | Move-IADObject -NewLocationDN "OU=TEST,DC=domain,DC=com" 
## 
##               2. Move users Test1 and Test2 to NewTEST OU 
##               Move-IADObject -ObjectDN "CN=Test1,OU=TEST,DC=domain,DC=com","CN=Test2,OU=TEST,DC=domain,DC=com" -NewLocationDN "OU=NewTEST,DC=domain,DC=com"
##            
## Notes       :
## Tag         : user, computer, group, activedirectory
## Change log  :
## =====================================================================


  


function Move-IADObject { 


 param(
  [object[]]$ObjectDN,
  [string]$NewLocationDN=$(Throw "Parameter 'NewLocationDN' must have a value")
 ) 
  

    
 begin
 {
  if(![ADSI]::Exists("LDAP://$NewLocationDN"))
  {
   Throw "'$NewLocationDN' doesn't exist, please check the value."
  }
  else
  {
   $NewRoot = [ADSI]"LDAP://$NewLocationDN"
  }
 }
 
 process
 {
 
  trap
  {
   Write-Error $_
   continue
  }
  
  if($_ -is [ADSI])
  {
   $_.psbase.MoveTo($NewRoot)
  }
  else
  { 

   $ObjectDN | Foreach-Object { 
    if(!$_)
    {
     Write-Error "ObjectDN must have a value."
    }
    elseif(![ADSI]::Exists("LDAP://$_"))
    {
     Write-Error "ObjectDN '$_' doesn't exist, please check the value."
    }
    else
    {
     $obj = [ADSI]("LDAP://$_")
     $obj.psbase.MoveTo($NewRoot)
    }
   } 
  }   
 }
}