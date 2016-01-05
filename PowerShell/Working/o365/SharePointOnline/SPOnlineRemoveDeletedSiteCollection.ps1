## SharePoint Online: PowerShell SharePoint Online Module Script to remove a Deleted Site Collection from the Recycle Bin (SPOnline) ##

## Overview: PowerShell Script that uses the SharePoint Online Module 'Remove-SPODeletedSite' cmdlet to permanently remove a deleted site collection from the Recycle Bin

## Usage: Replace the 'contoso' placeholder value under 'Connect-SPOService' with your own tenant prefix and provide the Site Collection URL under the '$SiteURL' variable

## Resource: https://technet.microsoft.com/en-us/library/fp161368.aspx

$SiteURL = "https://contoso.sharepoint.com/sites/sitetoremove"

Import-Module Microsoft.Online.Sharepoint.PowerShell
$credential = Get-credential 
Connect-SPOService -url https://contoso-admin.sharepoint.com -Credential $credential 

Remove-SPODeletedSite -Identity $SiteURL