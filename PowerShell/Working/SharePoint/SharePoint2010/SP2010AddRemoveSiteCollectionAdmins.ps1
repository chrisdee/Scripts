## SharePoint Server: PowerShell Script To Add and Remove Site Collection Administrators ##

<#

Overview: PowerShell Script that uses the Object Model to add and remove user accounts from the Site Collectio Administrator role

Environments: MOSS 2007, SharePoint Server 2010 / 2013 Farms

Usage: Edit the variables below to suit your requirements and run the script. Note: When setting the '$add' variable; a '1' value adds the user, while a '0' value removes the user

#>

######################## Start Variables ########################
$newSiteCollectionAdminLoginName = "DOMAIN\AccountName"
$newSiteCollectionAdminEmail = "YourEmail@domain.com"
$newSiteCollectionAdminName = "AccountDisplayName"
$newSiteCollectionAdminNotes = ""
$siteURL = "http://YourSharePointSiteName.com" #URL to any site in the web application.
$add = 1 # 1 for adding the user, 0 to remove the user
######################## End Variables ########################
Clear-Host
$siteCount = 0
[system.reflection.assembly]::loadwithpartialname("Microsoft.SharePoint")
$site = new-object microsoft.sharepoint.spsite($siteURL)
$webApp = $site.webapplication
$allSites = $webApp.sites
foreach ($site in $allSites)
{
    
    $web = $site.openweb()
    $web.allusers.add($newSiteCollectionAdminLoginName, $newSiteCollectionAdminEmail, $newSiteCollectionAdminName, $newSiteCollectionAdminNotes)
    
    $user = $web.allUsers[$newSiteCollectionAdminLoginName]
    $user.IsSiteAdmin = $add
    $user.Update()
    $web.Dispose()
    $siteCount++
}
$site.dispose()
write-host "Updated" $siteCount "Site Collections."