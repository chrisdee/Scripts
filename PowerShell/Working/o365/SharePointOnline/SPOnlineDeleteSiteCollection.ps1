## SharePoint Online: PowerShell SharePoint Online Module Script to Delete a Site Collection (SPOnline) ##

## Overview: PowerShell Script that uses the SharePoint Online Module 'Remove-SPOSite' cmdlet to delete a site collection. This site collection is then moved to the Recycle Bin

## Note: To delete a site collection permanently, first move the site collection to the Recycle Bin by using the 'Remove-SPOSite' cmdlet, and then delete it by using the 'Remove-SPODeletedSite' cmdlet.

## Usage: Replace the 'contoso' placeholder value under 'Connect-SPOService' with your own tenant prefix and provide the Site Collection URL under the '$SiteURL' variable

## Resource: https://technet.microsoft.com/en-us/library/fp161377.aspx

$SiteURL = "https://contoso.sharepoint.com/sites/sitetoremove"

Import-Module Microsoft.Online.Sharepoint.PowerShell
$credential = Get-credential 
Connect-SPOService -url https://contoso-admin.sharepoint.com -Credential $credential 

Remove-SPOSite -Identity $SiteURL -NoWait