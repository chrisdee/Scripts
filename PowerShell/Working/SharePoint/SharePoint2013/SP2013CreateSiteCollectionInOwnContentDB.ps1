## SharePoint Server: PowerShell Script to provision a new Site Collection in it's own Content Database ##

<#

Environments: SharePoint Server 2010 / 2013 Farms

Usage: After provisioning the Site Collection; when you go to the $site URL you will need to choose a site template

The new content database will be visible in Central Admin under: Central Administration -- Manage Content Databases

Note: The script will set the Maximum Sites count on the new content database to 1 (-MaxSiteCount). Change this if needed

#>

Add-PSSnapin Microsoft.SharePoint.PowerShell –ErrorAction SilentlyContinue
Write-Host "Lets first provision the new content database" -ForegroundColor Yellow
$server = Read-Host "Enter SQL Server"
$dbname = Read-Host "Enter Database Name"
$webapp = Read-Host "Enter Web Application URL"
Write-Host "Now lets provision the site collection" -ForegroundColor Yellow
$site = Read-Host "Enter New Site Collection URL"
$owner1 = Read-Host "Enter Primary Site Collection Admin"
$owner2 = Read-Host "Enter Secondary Site Collection Admin"
Write-Host "Thanks, attempting to create these now" -ForegroundColor Yellow
##Provisions the new content database (Resource: http://technet.microsoft.com/en-us/library/ff607572.aspx)
New-SPContentDatabase -Name $dbname -DatabaseServer $server -WebApplication $webapp | out-null
##Provisions the new site collection (Resource: http://technet.microsoft.com/en-us/library/ff607937.aspx)
New-SPSite -URL $site -OwnerAlias $owner1 -SecondaryOwnerAlias $owner2 -ContentDatabase $dbname | out-null
##Sets the Maximum Number of site collections
Get-SPContentDatabase -Site $site | Set-SPContentDatabase -MaxSiteCount 1 -WarningSiteCount 0
Write-Host " "
Write-Host "Site Collection at" $site "has been created in the" $dbname "content database" -ForegroundColor Yellow