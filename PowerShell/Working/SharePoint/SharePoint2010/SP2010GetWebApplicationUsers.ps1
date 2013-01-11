## SharePoint Server: PowerShell Script To Export Web Application User Profiles To A CSV File ##

# Environments: SharePoint Server 2010 Farms

# Resource: http://snahta.blogspot.ch/2012/08/powershell-exporting-user-profile.html

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$siteUrl = "http://sp2010WebAppURL" #Change this to suit your environment
$outputFile = "C:\UserProfiles.csv" #Change this path to suit your environment

$serviceContext = Get-SPServiceContext -Site $siteUrl
$profileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($serviceContext);
$profiles = $profileManager.GetEnumerator()

Write-Host "Exporting profiles" 

$collection = @()
foreach ($profile in $profiles) {
 
  $profileData = "" | select "AccountName","FirstName", "LastName","PreferredName","WorkPhone"
   $profileData.AccountName = $profile["AccountName"].Value
   $profileData.FirstName = $profile["FirstName"].Value
   $profileData.LastName = $profile["LastName"].Value
   $profileData.PreferredName = $profile["PreferredName"].Value
   $profileData.WorkPhone = $profile["WorkPhone"].Value
   $collection += $profileData
}

$collection | Export-Csv $outputFile -NoTypeInformation