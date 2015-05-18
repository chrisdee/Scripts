## SharePoint Server: PowerShell Script to Update the Values used in the Security Token Service Configuration ##

<#

Overview: When using Claims Based Authentication; Security Token Caching is set as a default in SharePoint Server 2013 Farms to the following values

WindowsTokenLifetime = 600 Minutes 
LogonTokenCacheExpirationWindow = 10 Minutes

If you have an environment where Active Directory Group Memberships are changing more frequently; then these properties can be adjusted

Environments: SharePoint Server 2013 Farms

Usage: Edit the minute values in the following properties: '$sts.WindowsTokenLifetime'; '$sts.LogonTokenCacheExpirationWindow' and run the script

Resources: 

http://blog.trivadis.com/b/collaboration/archive/2014/06/04/ad-group-membership-not-updated-immediately-to-sharepoint.aspx

https://technet.microsoft.com/en-us/library/ff607642.aspx

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$sts = Get-SPSecurityTokenServiceConfig

#Get/Display the current Farms Security Token Service Configuration (Defaults: WindowsTokenLifetime 10:00:00 | LogonTokenCacheExpirationWindow 00:10:00)
$sts

#Now Set the new values for the 'WindowsTokenLifetime' and 'LogonTokenCacheExpirationWindow'. Note: 'LogonTokenCacheExpirationWindow' value must always be lower
$sts.WindowsTokenLifetime = (New-TimeSpan –minutes 30) #Change the number of minutes to match your requirements
$sts.LogonTokenCacheExpirationWindow = (New-TimeSpan –minutes 5) #Change the number of minutes to match your requirements
$sts.Update()

#Now Get/Display the updated Farms Security Token Service Configuration
$sts