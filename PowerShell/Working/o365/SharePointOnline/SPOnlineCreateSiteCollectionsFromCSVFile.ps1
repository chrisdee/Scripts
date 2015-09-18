## SharePoint Online: PowerShell SharePoint Online Module Script to create Multiple Site Collections from a CSV File (SPOnline) ##

<#

Overview: Create multiple SPO Sites from CSV file.  

Usage: Create CSV file with content like the sample below (first line is the header row and needs to remain as is) 

Name,URL,Owner,StorageQuota,ResourceQuota,Template,TimeZoneID
Contoso Team Site,https://contoso.sharepoint.com/sites/TeamSite,user1@contoso.com,1024,300,STS#0,2 
Contoso Blog,https://contoso.sharepoint.com/sites/Blog,user2@contoso.com,512,100,BLOG#0,4

Replace the 'contoso' placeholder value under 'Connect-SPOService' with your own tenant prefix and run the script

Resources: 

http://powershell.office.com/scenarios/create-multiple-sharepoint-site-collections-with-different-owners

http://powershell.office.com/script-samples/create-multiple-spo-sites-from-csv-file

http://3sharp.com/blog/use-powershell-to-automate-site-collection-setup-in-sharepoint-online

https://gallery.technet.microsoft.com/office/How-to-create-several-0be44ce8

https://technet.microsoft.com/en-us/library/fp161370.aspx

#>

#To begin, you will need to load the SharePoint Online module to be able to run commands in PowerShell 
Import-Module Microsoft.Online.Sharepoint.PowerShell 
$credential = Get-credential 
Connect-SPOService -url https://contoso-admin.sharepoint.com -Credential $credential #Replace 'contoso' with your tenant prefix

#The following command will import the content of the CSV, and create a site collection for each row 
Import-Csv .\NewSPOSites.csv| % {New-SPOSite -Owner $_.Owner -StorageQuota $_.StorageQuota -Url $_.Url -NoWait -ResourceQuota $_.ResourceQuota -Template $_.Template -TimeZoneID $_.TimeZoneID -Title $_.Name} 