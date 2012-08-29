## =====================================================================
## Title       : New-IADPassword
## Description : Generates a random password of the specified length.
## Author      : Idera
## Date        : 8/11/2009
## Input       : New-IADPassword [[-Length] <Int32>] [[-NumberOfNonAlphanumericCharacters] <Int32>] [[-HowMany] <Int32>]
##                     
## Output      : System.String 
## Usage       :
##               1. Generate 3 passwords, 8 characters length each with 2 punctuation characters. 
##               New-IADPassword -HowMany 3 -Length 8 -NumberOfNonAlphanumericCharacters 2 
##
## Notes       : http://msdn.microsoft.com/en-us/library/system.web.security.membership.generatepassword.aspx
## Tag         : password, security
## Change log  :
## =====================================================================


function New-IADPassword 

{ 

 param(
  [int]$Length,
  [int]$NumberOfNonAlphanumericCharacters,
  [int]$HowMany=1
  )
  


 begin
 { 

  
 
 $null = [Reflection.Assembly]::LoadWithPartialName("System.Web") 

  

  if($NumberOfNonAlphanumericCharacters -lt 1 -or $NumberOfNonAlphanumericCharacters -gt 128)
  {
   Throw "Length must be between 1 and 128."
  }
   
  if($HowMany -lt 1)
  {
   Throw "HowMany must be equal or greater than 1."
  }
   

 } 

  

 process
 {
  for($i=0; $i -lt $HowMany; $i++)
  {
   [System.Web.Security.Membership]::GeneratePassword($length,$NumberOfNonAlphanumericCharacters)
  }
 }
}