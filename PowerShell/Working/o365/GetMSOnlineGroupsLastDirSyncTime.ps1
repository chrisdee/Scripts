## MSOnline: PowerShell Script to Get All MSOnline Groups Last Sync Time via DirSync (o365) ##

## Connect to MSOnline Tenant
Import-Module MSOnline
Import-Module MSOnlineExtended
$cred=Get-Credential
Connect-MsolService -Credential $cred

## Retrieve the Groups that have a last DirSyncTime
$objDistributionGroups = Get-MSolgroup -All | where lastdirsynctime -ne $null
Foreach
($objDistributionGroup in $objDistributionGroups)

{

Write-Output "$($objDistributionGroup.DisplayName + ', ' + $objDistributionGroup.EmailAddress + ', ' + $objDistributionGroup.LastDirSyncTime)"

}
