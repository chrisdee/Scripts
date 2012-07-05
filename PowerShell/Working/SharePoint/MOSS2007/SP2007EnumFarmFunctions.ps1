## SharePoint 2007: PowerShell Functions To Query Farms, Web Apps, Site Collections Properties ##
# Resources: http://www.dunxd.com/2008/12/17/administering-sharepoint-some-perspectives
#			 http://sharepoint.microsoft.com/Blogs/zach/Script%20Library/functions.ps1.txt

# Load SharePoint assemblies
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server")
 
#####################################################################################
#
# Sharepoint basic functions
#
#####################################################################################
 
#######
#
#	Get-SPFarm
#
#	Gets the Farm on this server
#
#######
 
function global:Get-SPFarm{
	return [Microsoft.SharePoint.Administration.SPFarm]::Local
}
 
#######
#
#	Get-SPWebApps
#
#	Gets all the web apps on a farm
#
#######
 
function global:Get-SPWebApps{
	Get-SPFarm |% {$_.Services} | where {'$_.TYPEName -eq "Windows Sharepoint Services Web Application"'} |% {$_.WebApplications} |% {Write-Output $_}
}
 
#######
#
#	List-SPWebApp-GUID
#
#	Lists the Web Applications on a farm, and their GUIDS
#	(which can be used to grab a single Web App).
#
#######
function global:List-SPWebApp-GUID {
	Get-SPWebApp | Select Id, DisplayName
}
 
#######
#
#	Get-SPWebApp
#
#	Gets a specific web app by its GUID
#	Hint: use List-SPWebApp-GUID to list all the GUIDs
#
#######
function global:Get-SPWebApp($guid){
	# If no guid sent get all the web applications for the farm
	if($guid -eq $null){
		Get-SPFarm |% {$_.Services} | where {'$_.TYPEName -eq "Windows Sharepoint Services Web Application"'} |% {$_.WebApplications} |% {Write-Output $_}
	} else {
		$myfarm = Get-SPFarm;
		return $myfarm.GetObject($guid);
	}
}
 
########
#
#	Get-SPWeb
#
#	Gets a single site by its URL
#
########
function global:Get-SPWeb($url,$site) {
	if($site -ne $null -and $url -ne $null){"Url OR Site can be given"; return}
	#if SPSite is not given, we have to get it...
	if($site -eq $null){
		$site = Get-SPSite($url);
	}
	#Output 1 or more sites...
	if($url -eq $null){
		for($i=0; $i -lt $s.AllWebs.Count;$i++){
			Write-Output $s.AllWebs[$i]; ##Send through Pipeline
			$s.Dispose(); ##ENFORCED DISPOSAL!!!
		}
	}else{
    	Write-Output $site.OpenWeb()
	}
}
 
########
#
#	Check-GUID
#
#	Checks that a given string is the format of a GUID (but doesn't verify that the guid is valid)
#
#########
function global:Check-GUID($guid){
	$regex = "^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$";
	if ($guid -match $regex){
		return $true;
	} else {
		return $false;
	}
}
 
########
#
#	Get-SPSite
#
#	Gets a single Site Collection by its URL
#
########
function global:Get-SPSite($url){
	return New-Object Microsoft.SharePoint.SPSite($url);
}
 
########
#
#	Get-UserProfileConfigManager
#
#	Returns UserProfileConfigManager object used for managing MOSS User Profiles
#
########
function global:Get-UserProfileConfigManager([string]$PortalURL){
	# Get portal context object
	$site = Get-SPSite($PortalURL);
	$servercontext = [Microsoft.Office.Server.ServerContext]::GetContext($site);
	$site.Dispose();
 
	# Return the UserProfileConfigManager
	New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigmanager($servercontext);
}
 
########
#
#	Get-MemberGroupManager
#
#	Gets the MemberGroupManager object for a portal - this can be used to make changes to membership groups
#
########
function global:Get-MemberGroupManager($PortalURL){
	$ugm = Get-UserProfileManager($PortalURL);$m
	$ugm.GetMemberGroups();
}
 
########
#
#	Get-UserProfileManager
#
#	Gets a UserProfileManager object for a specific portal.  This can be used to make changes to
#	user profiles
#
########
function global:Get-UserProfileManager($PortalURL){
	# Get portal context object
	$site = Get-SPSite($PortalURL);
	$servercontext = [Microsoft.Office.Server.ServerContext]::GetContext($site);
	$site.Dispose();
 
	# Return the UserProfileManager object
	New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($servercontext);
}
 
########
#
#	Delete-MemberGroup
#
#	Removes a MemberGroup from the given Portal URL
#
########
function global:Delete-MemberGroup($PortalURL){
	$mm = Get-MemberGroupManager($PortalURL);
	$name = Read-Host "MailNickName";
	foreach ($m in $mm){
		if ($m.MailNickName -eq $name){
			Write-Host "Deleting " $m.MailNickName;
			$m.Delete();
		}
	}
}