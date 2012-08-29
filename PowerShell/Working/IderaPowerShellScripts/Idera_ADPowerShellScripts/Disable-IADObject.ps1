## =====================================================================
## Title       : Disable-IADObject
## Description : Disable a user or computer object in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No Input                 
##                     
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       : 
##               1. Disable computer Server1
##               Get-IADComputer Server1 | Disable-IADObject
##            
## Notes       :
## Tag         : user, computer, activedirectory
## Change log  :
## =====================================================================


filter Disable-IADObject {




  if($_ -is [ADSI] -and $_.psbase.SchemaClassName -match '^(user|computer)$')
  {
    $null = $_.psbase.invokeSet("AccountDisabled",$true)
    $null = $_.SetInfo()
    $_
  }
   else
  {
    Write-Warning "Invalid object type. Only 'User' or 'Computer' objects are allowed."
  }
}