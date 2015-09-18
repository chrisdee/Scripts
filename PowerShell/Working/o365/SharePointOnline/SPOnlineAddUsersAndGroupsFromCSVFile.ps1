## SharePoint Online: PowerShell SharePoint Online Module Script to add Users / Groups to Multiple Site Collections from a CSV File (SPOnline) ##

<#

Overview: Add Multiple Users or Groups to Multiple SPO Sites from CSV file.

By default each site created from a standard template (eg. STS#0) is created with three membership groups, Owners, Members, and Visitors; with Full Control, Contribute, and View-only site permissions respectively 

Usage: Create CSV file with content like the sample below (first line is the header row and needs to remain as is) 

Site,Group,User 
https://contoso.sharepoint.com/sites/TeamSite,Contoso Team Site Members,user2@contoso.com 
https://contoso.sharepoint.com/sites/TeamSite,Contoso Team Site Members,user3@contoso.com 
https://contoso.sharepoint.com/sites/TeamSite,Contoso Team Site Visitors,user4@contoso.com 
https://contoso.sharepoint.com/sites/Blog,Contoso Blog Members,user5@contoso.com 
https://contoso.sharepoint.com/sites/Blog,Contoso Blog Visitors,user6@contoso.com

In the 'User' column provide the User or Group names you want to add to the respective site collections (appears to work with default groups and custom ones)

Replace the 'contoso' placeholder value under 'Connect-SPOService' with your own tenant prefix and run the script

Resources:

http://powershell.office.com/scenarios/create-multiple-sharepoint-site-collections-with-different-owners

http://powershell.office.com/script-samples/assign-group-members-to-sharepoint-site

http://3sharp.com/blog/use-powershell-to-automate-groups-and-users-provisioning-in-sharepoint-online

https://technet.microsoft.com/en-us/library/fp161371.aspx

#>

#To begin, you will need to load the SharePoint Online module to be able to run commands in PowerShell
Import-Module Microsoft.Online.Sharepoint.PowerShell 
$credential = Get-credential 
Connect-SPOService -url https://contoso-admin.sharepoint.com -Credential $credential #Replace 'contoso' with your tenant prefix
 
#The following command will import the content of the CSV, and assign membership for users or groups for each row
Import-Csv \SPOUserGroups.csv | % {Add-SPOUser -Site $_.Site -Group $_.Group -LoginName $_.User}