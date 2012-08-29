## =====================================================================
## Title       : Get-IADAltRecipient
## Description : Get all objects which has an alternative recipient to receive e-mail
## Author      : Idera
## Date        : 8/11/2009
## Input       :   No Input             
##                     
## Output      : System.Management.Automation.PSCustomObject
## Usage       : Get-IADAltRecipient | Format-Table Name,Description,AltRecipient -AutoSize 
##    
## Notes       :
## Tag         : altrecipient, activedirectory, exchange
## Change log  :
## =====================================================================

function Get-IADAltRecipient 
{ 

 $searcher = New-Object System.DirectoryServices.DirectorySearcher
 $searcher.SearchRoot = [ADSI]""
 $searcher.PageSize = 1000
 $searcher.filter = "(&(sAMAccountType=805306368)(mail=*)(altRecipient=*))" 
  
 $searcher.FindAll() | Foreach-Object {
  $pso = "" | select Name,DN,Description,AltRecipient
  $pso.Name = [string]$_.Properties.name
  $pso.DN = [string]$_.Properties.distinguishedname
  $pso.Description = [string]$_.Properties.description
  $pso.AltRecipient = [string]$_.Properties.altrecipient
  $pso
 }
}