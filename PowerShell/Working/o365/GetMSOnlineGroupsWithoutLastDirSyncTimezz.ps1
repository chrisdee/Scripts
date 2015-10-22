## MSOnline: PowerShell Script to Get All MSOnline Groups that have not been Synchronised via DirSync (o365) ##

## Connect to MSOnline Tenant
Import-Module MSOnline
Import-Module MSOnlineExtended
$cred=Get-Credential
Connect-MsolService -Credential $cred

## Retrieve the Groups that don't have a last DirSyncTime
$objDistributionGroups = Get-MSolgroup -All | where lastdirsynctime -eq $null
Foreach
($objDistributionGroup in $objDistributionGroups)

{

Write-host "$($objDistributionGroup.DisplayName + ', ' + $objDistributionGroup.EmailAddress)"

}
