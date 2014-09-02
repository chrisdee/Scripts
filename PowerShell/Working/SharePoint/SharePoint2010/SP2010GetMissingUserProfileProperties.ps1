## SharePoint Server: PowerShell Script to find all user profiles without a specified User Profile Property ##

<#

Usage: Edit the required variables and run the script

Environments: SharePoint Server 2010 / 2013 Farms

Resources: 

http://stevemannspath.blogspot.ch/2013/05/sharepoint-20102013-using-powershell-to.html
http://social.technet.microsoft.com/wiki/contents/articles/20692.sharepoint-2013-get-set-and-copy-user-profile-properties-using-powershell.aspx

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

##### BEGIN VARIABLES #####
$mySiteUrl = "https://mysitewebapp.yourdomain.com" #Provide the path to your My Site Web Application
$findProperty = "PictureUrl" #Provide the User Profile Service Property you want to query
##### END VARIABLES #####
 
Write-Host "Beginning Processing--`n"
 
# Obtain Context based on site
$mySiteHostSite = Get-SPSite $mySiteUrl
$mySiteHostWeb = $mySiteHostSite.OpenWeb()
$context = Get-SPServiceContext $mySiteHostSite
 
# Obtain Profiles from the Profile Manager
$profileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($context)
$AllProfiles = $profileManager.GetEnumerator()
$outputCollection = @()
 
# Loop through profiles and retrieve the desired property
foreach ($profile in $AllProfiles)
{
    $output = New-Object System.Object
    $output | Add-Member -type NoteProperty -Name AccountName -Value $profile["AccountName"].ToString()
    $output | Add-Member -type NoteProperty -Name $findProperty -Value $profile[$findProperty] 
    $outputCollection += $output
}
 
# # List all Accounts that do not contain the property
$outputCollection | Where-Object {[bool]$_.($findProperty) -ne $true}
 
