## SharePoint Online: PowerShell SharePoint Online Module Script to  Perform Bulk Actions from a CSV File (SPOnline) ##

<#

Overview: PowerShell Script to perform Bulk Operations on Site Collections Imported from a CSV File

Usage: Create CSV file with content like the sample below (first line is the header row and needs to remain as is) 

Name,URL,Owner,StorageQuota,ResourceQuota,Template,TimeZoneID
Contoso Team Site,https://contoso.sharepoint.com/sites/TeamSite,user1@contoso.com,1024,300,STS#0,2 
Contoso Blog,https://contoso.sharepoint.com/sites/Blog,user2@contoso.com,512,100,BLOG#0,4

Replace the 'contoso' placeholder value under 'Connect-SPOService' with your own tenant prefix and run the script

Usage Examples:

#Create Site Collections
Import-Csv .\SPOnlineSiteCollections.csv | % {New-SPOSite -Owner $_.Owner -StorageQuota $_.StorageQuota -Url $_.Url -NoWait -ResourceQuota $_.ResourceQuota -Template $_.Template -TimeZoneID $_.TimeZoneID -Title $_.Name} 

#Set Site Collections Properties (storage quota in this case)
Import-Csv .\SPOnlineSiteCollections.csv | % {Set-SpoSite -Identity $_.Url -StorageQuota $_.StorageQuota} 

#Delete and Remove Site Collections from the Recycle Bin
Import-Csv .\SPOnlineSiteCollections.csv | % {Remove-SPOSite -Identity $_.Url } 
Import-Csv .\SPOnlineSiteCollections.csv | % {Remove-SPODeletedSite -Identity $_.Url } 

#>

#To begin, you will need to load the SharePoint Online module to be able to run commands in PowerShell 
Import-Module Microsoft.Online.Sharepoint.PowerShell 
$credential = Get-credential 
Connect-SPOService -url https://tgf-admin.sharepoint.com -Credential $credential #Replace 'contoso' with your tenant prefix

#Now create ypur command/s like the example below

#Import-Csv .\SPOnlineSiteCollections.csv | % {New-SPOSite -Owner $_.Owner -StorageQuota $_.StorageQuota -Url $_.Url -NoWait -ResourceQuota $_.ResourceQuota -Template $_.Template -TimeZoneID $_.TimeZoneID -Title $_.Name} 


