## SharePoint Online: PowerShell SharePoint Online Module Script to Enable / Disable Custom Script Features at Site Collection Level ##

## Usage: Edit the variables below to match your requirements and run the script

## Resources: https://emadmagdy.wordpress.com/2015/06/24/sharepoint-onlineenabling-custom-script

### Start Variables ###
$Tenant = "YourTenant"
$SiteURL = "https://YourSPOsite.sharepoint.com"
$CustomScriptFlag = 0 #Change this boolean value to 1 if you want to disable Custom Script features
### End Variables ###

Import-Module Microsoft.Online.Sharepoint.PowerShell 
$credential = Get-credential 
Connect-SPOService -url ("https://" + "$Tenant" + "-admin.sharepoint.com") -Credential $credential

#Enable / Disable Custom Script at Site Collection Level
Set-SPOsite $SiteURL -DenyAddAndCustomizePages $CustomScriptFlag

#Check the properties of the Site Collection (Note: these changes can take a while to take effect on o365)
Get-SPOSite $SiteURL |fl