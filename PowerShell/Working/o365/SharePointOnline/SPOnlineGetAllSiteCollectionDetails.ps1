## SharePoint Online: PowerShell SharePoint Online Module Script to Get Deatils on All Site Collections in a Tenant (SPOnline) ##

## Overview: PowerShell Script that uses the SharePoint Online Module to Get useful details on All site collections using the 'Get-SPOSite' commandlet

## Usage: Replace the 'contoso' placeholder value under 'Connect-SPOService' with your own tenant prefix and run the script

## Resource: http://3sharp.com/blog/use-powershell-to-automate-site-collection-setup-in-sharepoint-online

Import-Module Microsoft.Online.Sharepoint.PowerShell 
$credential = Get-credential 
Connect-SPOService -url https://contoso-admin.sharepoint.com -Credential $credential 

Get-SPOSite -Detailed | Sort-Object StorageUsageCurrent -Descending | Format-Table Url, Template, WebsCount, StorageUsageCurrent, StorageQuota, ResourceUsageCurrent, LastContentModifiedDate -AutoSize