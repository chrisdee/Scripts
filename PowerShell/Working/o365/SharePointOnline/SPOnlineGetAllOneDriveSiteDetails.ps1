## SharePoint Online: PowerShell Script to Produce a Report on All Users OneDrive Sites (MSOnline / SPOnline) ##

## Overview: PowerShell Script that uses the MSOnline and SPOnline  PowerShell Modules to report on all users OneDrive Sites

## Usage: Find and Replace  all instances of the 'YourTenant' prefix with your own tenant prefix and run the script

## Resource: http://blogs.catapultsystems.com/dbroussard/archive/2015/10/20/pull-onedrive-for-business-usage-using-powershell/

## Imports the MSOnline and SPOnline PowerShell Modules
Import-Module MSOnline
Import-Module MSOnlineExtended
Import-Module Microsoft.Online.Sharepoint.PowerShell

## Connects to MSOnline and SPOnline PowerShell Commandlets
$cred=Get-Credential
Connect-MsolService -Credential $cred
Connect-SPOService -url https://YourTenant-admin.sharepoint.com -Credential $cred

function GetODUsage($url)
{
    $sc = Get-SPOSite $url -Detailed -ErrorAction SilentlyContinue | select url, storageusagecurrent, Owner
    $usage = $sc.StorageUsageCurrent /1024
    return "$($sc.Owner), $($usage), $($url)"
}
foreach($usr in $(Get-MsolUser -All ))
{
    if ($usr.IsLicensed -eq $true)
    {
        $upn = $usr.UserPrincipalName.Replace(".","_")
        $od4bSC = "https://YourTenant-my.sharepoint.com/personal/$($upn.Replace("@","_"))"
        $od4bSC
        foreach($lic in $usr.licenses)
        {
            if ($lic.AccountSkuID -eq "YourTenant:ENTERPRISEPACK") {Write-Host "$(GetODUsage($od4bSC)), E3"}
            elseif ($lic.AccountSkuID -eq "YourTenant:WACONEDRIVESTANDARD") {Write-Host "$(GetODUsage($od4bSC)), OneDrive"} 
        }
    }
}
