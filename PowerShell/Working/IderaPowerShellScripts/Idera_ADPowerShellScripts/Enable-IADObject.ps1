## =====================================================================
## Title       : Enable-IADObject
## Description : Enable a user or computer object in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       : No Input
##                                      
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       : 
##               1. Enable user Test1
##               Get-IADUser Test1 | Enable-IADObject
##            
## Notes       :
## Tag         : user, computer, activedirectory
## Change log  :
## =====================================================================

filter Enable-IADObject {




  if($_ -is [ADSI] -and $_.psbase.SchemaClassName -match '^(user|computer)$') 
  {
     $null = $_.psbase.invokeSet("AccountDisabled",$false)
     $null = $_.SetInfo()
     $_
    }
    else
    {
      Write-Warning "Invalid object type. Only 'User' or 'Computer' objects are allowed."
    }
  }