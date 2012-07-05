## SharePoint Server 2007 / 2010: PowerShell Script to delete users from Sites and Site Collections in a Web Application ##
## Link: http://blog.isaacblum.com/2011/02/24/remove-delete-users-from-all-sites-and-site-collections-within-a-web-application
## Notes: The script doesn't appear to delete Site Collection 'Owners' and 'Administrators'
## Reference to SharePoint DLL
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
 
##Ask for WebApp Root url to enumerate or scope scan
Write-Host "Please enter root url of WebApplication, ex: http://contoso"
$siteurl = Read-Host "Value "
Write-Host "Please enter the domain search parameter, ex: contoso " #This is essentially the domain of the user
$searchP = Read-Host "Value "
 
##Create Table - ScanTable
$ScanTable = New-Object system.Data.DataTable "ScanTable"
$col1 = New-Object system.Data.DataColumn ("LoginName", [string])
$col2 = New-Object system.Data.DataColumn ("URL", [string])
$ScanTable.columns.add($col1)
$ScanTable.columns.add($col2)
 
##Returning info for use in remainder of script
$webapp = [Microsoft.SharePoint.Administration.SPWebApplication]::Lookup($siteurl)
##Start looping through the sites collections
foreach ($site in $webapp.Sites)
{
    $spSite = new-object Microsoft.SharePoint.SPSite($site.url)
	$spWeb = $spSite.OpenWeb()
 
	##Save file path, guid, and title of each closed webpart
	foreach ($_.LoginName in $spSite.RootWeb.SiteUsers | select LoginName)
	{
	if ($_.LoginName -like "*$searchP*")
	{
	$output = $ScanTable.Rows.Add($_.LoginName, $site.url)
	$spWeb.SiteUsers.Remove($_.LoginName)
	}
	}
 
	##Clean Up
    $spSite.Dispose()
    $spWeb.Dispose()
}
 
##Write txt file
Write-Output $ScanTable | select URL | Sort-Object URL -Unique | Out-File C:\DeletedUsers.txt -Append