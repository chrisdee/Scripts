## =====================================================================
## Title       : New-IEXAddressList
## Description : Create new address list from distribution group
## Author      : Idera
## Date        : 09/15/2009
## Input       : New-IEXAddressList [[-Name] <String>]
##  
## Output      : Microsoft.Exchange.Data.Directory.Management.AddressList
## Usage       : 
##               1. Create new address list from distribution group TestGroup. New address list gets the name of dist. group 
##               Get-DistributionGroup TestGroup | New-IEXAddressList 
##
##               2. Create new address list from distribution group TestGroup with the name 'TestAL' 
##               Get-DistributionGroup TestGroup | New-IEXAddressList -Name TestAL 
##           
## Notes       :
## Tag         : Exchange 2007, address list, distribution group, new
## Change log  :
## ===================================================================== 

 
#requires -pssnapin Microsoft.Exchange.Management.PowerShell.Admin 

  
filter New-IEXAddressList
{
 
 param (
  [string]$Name
 ) 

 if($_ -is [Microsoft.Exchange.Data.Directory.Management.DistributionGroup])
 { 

  trap
  {
   Write-Error $_
   continue
  } 

  $groupDN = $_.Identity.DistinguishedName 

  if(!$Name)
  {
   Write-Warning "No Name has been specified, the DistributionGroup name will be used instead."
   $Name = $_.Name
  }
  
  
  New-AddressList -Name $Name -RecipientFilter "MemberOfGroup -eq '$groupDN'" | Update-AddressList
 }
 else
 {
  Write-Warning "Wrong object type, only DistributionGroup objects are allowed.`nUsage example: Get-DistributionGroup TestGroup | New-IEXAddressList -Name TestAL."
 }
} 

  
