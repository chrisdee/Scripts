## =====================================================================
## Title       : Get-IADObjectBySID
## Description : Retrieve domain account for known SID.
## Author      : Idera
## Date        : 8/11/2009
## Input       : Get-IADObjectBySID [[-SID] <String>]
##                                                      
## Output      : System.String
## Usage       : Get-IADObjectBySID -SID  'S-1-5-21-3889274798-524451202-2197197945-1112'
##            
## Notes       :
## Tag         : security, activedirectory
## Change log  :
## =====================================================================


function Get-IADObjectBySID 
{

 param(
  [string]$SID
 ) 
  
 $si = New-Object System.Security.Principal.SecurityIdentifier $SID
 
 if($si.IsAccountSid())
 {  
  $si.Translate([System.Security.Principal.NTAccount]).Value
 }
 else
 {
  Write-Error "'$si' is not a valid Windows account SID."
 }
}