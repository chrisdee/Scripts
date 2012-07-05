## SharePoint Server 2007: PowerShell Script To Output SSP User Profiles To A CSV File ##
## Usage: Composed of 2 scripts you need to run. '1' to view your farm profile properties, and '2' to export these to a CSV file
## Script 1: Run '.\Get-UserProfileConfigManager.ps1 YourSSPName' to get a list of profile properties
## Script 2: Edit your '$arProperties' variable to include the profile properties you want. Can also change other variables

## Script 1: Outputs a list of User profile names - both the internal name, and the name displayed in Sharepoint
 
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.UserProfiles")
# Function:          Get-UserProfileConfigManager
# Description:       return a UserProfileConfigManager object which is used for management of MOSS User Profiles
# Parameters:        SSPName          Shared Service Provider Name    
 
Function global:Get-UserProfileConfigManager($SSPName)
{
$ServerContext = [Microsoft.Office.Server.ServerContext]::GetContext($SSPName);
new-object Microsoft.Office.Server.UserProfiles.UserProfileConfigmanager($servercontext)
}
 
$cm=Get-UserProfileConfigManager("SharedServices");
$cm.getProperties() | ft name,displayname


## Script 2: Outputs a delimited file with specified user profile properties for each user in Sharepoint
 
# Create array of desired properties
$arProperties = 'UserName','FirstName','LastName','Title','WorkEmail','WorkPhone','Manager','AlternateContact','RoleDescription','PictureURL';
# Specify output file
$outfile = 'UserProfiles.csv';
#Specify delimiter character (i.e. not one that might appear in your user profile data)
$delim = '^';
# Specify Shared Service Provider that contains the user profiles.
$SSP = "SharedServices";
 
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.UserProfiles")
 
# Function:          Get-UserProfiles
# Description:       return a UserProfileManager object containing all user profiles
# Parameters:        SSPName          SSPName
 
Function global:Get-UserProfiles($SSPName)
{
	$ServerContext = [Microsoft.Office.Server.ServerContext]::GetContext($SSPName);
	$UPManager = new-object Microsoft.Office.Server.UserProfiles.UserProfileManager($ServerContext);
	return $UPManager.GetEnumerator();
}
$profiles = Get-UserProfiles($SSP);
 
#Initialise Output file with headings
$header = [string]::join($delim,$arProperties);
Write-Output $header | Out-File $outfile
 
#Output the specified properties for each
$profiles | ForEach-Object {
	foreach($p in $arProperties){
		# Get the property name and add it to a new array, which will be used to construct the result string
		$arProfileProps += $_.Item($p);
	}
	$results = [string]::join($delim,$arProfileProps);
	# Get rid of any newlines that may be in there.
	$CleanResults = $results.Replace("`n",'');
	Write-Output $CleanResults
	Remove-Variable -Name arProfileProps
} | Out-File -Append $outfile