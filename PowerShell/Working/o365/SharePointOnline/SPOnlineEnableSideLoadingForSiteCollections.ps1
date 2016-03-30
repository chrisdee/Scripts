## SharePoint Online: Enable SideLoading Feature for SharePoint Online (SPOnline) Site Collections via CSOM ##

#http://www.raihaniqbal.net/blog/2014/06/enable-app-sideloading-in-sharepoint-online/

#CODE STARTS HERE
#$programFiles = [environment]::getfolderpath("programfiles")
add-type -Path 'C:\ztemp\SPDLLs\Microsoft.SharePoint.Client.dll'
Write-Host 'Ready to enable Sideloading'
$siteurl = Read-Host 'Site Url'
$username = Read-Host "User Name"
$password = Read-Host -AsSecureString 'Password'
 
$outfilepath = $siteurl -replace ':', '_' -replace '/', '_'
 
try
{
[Microsoft.SharePoint.Client.ClientContext]$cc = New-Object Microsoft.SharePoint.Client.ClientContext($siteurl)
[Microsoft.SharePoint.Client.SharePointOnlineCredentials]$spocreds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $password)
$cc.Credentials = $spocreds
$site = $cc.Site;
 
$sideLoadingGuid = new-object System.Guid "AE3A1339-61F5-4f8f-81A7-ABD2DA956A7D"
$site.Features.Add($sideLoadingGuid, $true, [Microsoft.SharePoint.Client.FeatureDefinitionScope]::None);
 
$cc.ExecuteQuery();
 
Write-Host -ForegroundColor Green 'SideLoading feature enabled on site' $siteurl
#Activate the Developer Site feature
}
catch
{
Write-Host -ForegroundColor Red 'Error encountered when trying to enable SideLoading feature' $siteurl, ':' $Error[0].ToString();
}
 
#CODE ENDS HERE