## SharePoint Server: PowerShell Script to Update User Pictures Mapped to the AD Photo Attribute (thumbnailPhoto) ##

<#

Overview: After configuring the User Property 'Picture' to be mapped to the AD Attribute 'thumbnailPhoto' in your Farms User Profile Service Application; you still need to run a script to create the thumbnails from the AD import

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the '$mySitesUrl' variable and run the script under an account with Farm Admin credentials like the 'spfarm' account

Note: You should run this script as a scheduled task in your farm to add / update any new Photo changes made to the AD 'thumbnailPhoto' Attribute

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue
$mySitesUrl = "https://mysite.yourcompany.com" #Change this to match your environments My Site URL
$mySitesHost = Get-SPSite –Identity $mySitesUrl
Update-SPProfilePhotoStore –MySiteHostLocation $mySitesHost –CreateThumbnailsForImportedPhotos $true