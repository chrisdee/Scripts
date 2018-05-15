## SharePoint Online: PowerShell Script to Replace / Renew / Update Client Secrets and Start / End Dates for a SharePoint Online Add-in (SPOnline) ##

## http://vannick.me/2016/02/13/how-to-renew-sharepoint-add-in-client-secret/
## https://dev.office.com/sharepoint/docs/sp-add-ins/replace-an-expiring-client-secret-in-a-sharepoint-add-in
## App identifiers are also visible at Site Collection Level under 'Site App Permissions' - /_layouts/15/appprincipals.aspx
## https://cann0nf0dder.wordpress.com/2016/05/18/updating-an-expired-client-secret-of-sharepoint-add-in

## Get information about current SharePoint Online Add-Ins ##
## Take note of the 'Client Id' and 'KeyId' values for the following 3 property types: 'Password' (Verify); 'Symmetric' (Verify); 'Symmetric' (Sign)

[CmdletBinding()]
Param(
   [Parameter(Mandatory=$False)]
   [string]$addIn
)

Import-Module MSOnline
Connect-MsolService
$addIn = "*" #Change this wild card '*' value to something more specific if you know the name/s of the SharePoint Online Add-in
$applist = Get-MsolServicePrincipal -all  |Where-Object -FilterScript { ($_.DisplayName -like "*$addIn*") }
foreach ($appentry in $applist)
{
    $principalId = $appentry.AppPrincipalId
    $principalName = $appentry.DisplayName
    Write-Host "----------------------------------`n"
    Write-Host "Name: $principalName"
	Write-Host "Client Id: $principalId"
    
    Get-MsolServicePrincipalCredential -AppPrincipalId $principalId -ReturnKeyValues $false | Where-Object { ($_.Type -ne "Other") -and ($_.Type -ne "Asymmetric") }
} 

## Renew the SharePoint Online Add-in Client Secret with the Client ID you obtained from the 'Get information about current SharePoint Online Add-Ins' query above ##

[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True)]
   [string]$clientId
)

Connect-MsolService
$bytes = New-Object Byte[] 32
$rand = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rand.GetBytes($bytes)
$rand.Dispose()
$newClientSecret = [System.Convert]::ToBase64String($bytes) #Important: Replace this value with your original Client Secret GUID if you want to retain your original Client Secret

$startDate= [System.DateTime]::Now
$endDate = $startDate.AddYears(3) #Can only have a maximum value period of '3' years here
New-MsolServicePrincipalCredential -AppPrincipalId $clientId -Type Symmetric -Usage Sign -Value $newClientSecret -StartDate $startDate -EndDate $endDate
New-MsolServicePrincipalCredential -AppPrincipalId $clientId -Type Symmetric -Usage Verify -Value $newClientSecret -StartDate $startDate -EndDate $endDate 
New-MsolServicePrincipalCredential -AppPrincipalId $clientId -Type Password -Usage Verify -Value $newClientSecret -StartDate $startDate -EndDate $endDate
$newClientSecret

## Cleaning Up Expired Client Secrets for SharePoint Online Add-Ins ##

$clientId = "028c309a-cf90-4667-bacf-7c2353f4553e" #Provide the Client ID you obtained from the 'Get information about current SharePoint Online Add-Ins' query above
$keys = Get-MsolServicePrincipalCredential -AppPrincipalId $clientId -ReturnKeyValues $false
$dtNow = [System.DateTime]::Now
foreach($key in $keys)
{
 if($key.EndDate -lt  $dtNow)
 {
   write-host $key.KeyId "Expired"
   Remove-MsolServicePrincipalCredential -KeyIds @($key.KeyId) -AppPrincipalId $clientId
 }
}

## Removing Keys for a Service Principal for SharePoint Online Add-Ins ##

$clientId = "028c309a-cf90-4667-bacf-7c2353f4553e" #Provide the Client ID you obtained from the 'Get information about current SharePoint Online Add-Ins' query above

## For the '-KeyIds' Provide the 3 KeyID values you got from the 'Get information about current SharePoint Online Add-Ins' query: 'Password' (Verify); 'Symmetric' (Verify); 'Symmetric' (Sign)
Remove-MsolServicePrincipalCredential -KeyIds @("aeee7caa-8d0c-4b8b-91a7-b9c30c331b67","b56bf547-8f3e-4520-bbfc-7a6dbc146254","e2d948ba-fdfe-456d-ae21-25e0d0f839f8") -AppPrincipalId $clientId

## Removing a Service Principal for SharePoint Online Add-Ins (Caution: This removes the whole Service Principal)

$appPrincipal = Get-MsolServicePrincipal -ServicePrincipalName "028c309a-cf90-4667-bacf-7c2353f4553e" #Provide the Client ID you obtained from the 'Get information about current SharePoint Online Add-Ins' query above
Remove-MsolServicePrincipal -ObjectId $appPrincipal.ObjectId
