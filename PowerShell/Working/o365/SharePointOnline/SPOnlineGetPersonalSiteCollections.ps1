## SharePoint Online: PowerShell Script to Get All Personal Sites (MySite) for One Drive For Business (OD4B) in a Tenant via CSOM (SPOnline) ##

<#

Overview: PowerShell Script that returns all user Personal Sites for MySite / One Drive For Business in a Tenant via CSOM - with Text file output of the Personal site paths

Usage:

- Replace the 'contoso' placeholder values with your own tenant prefix

- Provide the Tenant Administrator credentials for the following variables '$AdminAccount'; '$AdminPass'

- Provide the path to the text file report in the '$LogFile' variable

Note: The 'Request-SPOPersonalSite' cmdlet requests that the users specified be enqueued so that a Personal Site be created for each. The actual Personal site is created by a Timer Job later.

Resource: https://technet.microsoft.com/en-us/library/dn911464.aspx

#>


$credentials = Get-Credential
Connect-SPOService -Url "https://contoso-admin.sharepoint.com" -credential $credentials


# Specifies the URL for your organization's SPO admin service
$AdminURI = "https://contoso-admin.sharepoint.com"

# Specifies the User account for an Office 365 global admin in your organization
$AdminAccount = "YourUser.Name@contoso.onmicrosoft.com"
$AdminPass = "YourPassword"

# Specifies the location where the list of MySites should be saved
$LogFile = 'C:\BoxBuild\SPDLLs\SPOnlinePersonalSites.txt' #Change this path to match your requirements


# Begin the process by loading the CSOM assemblies

$loadInfo1 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
$loadInfo2 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")
$loadInfo3 = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.UserProfiles")

# Convert the Password to a secure string, then zero out the cleartext version ;)
$sstr = ConvertTo-SecureString -string $AdminPass -AsPlainText -Force
$AdminPass = ""

# Take the AdminAccount and the AdminAccount password, and create a credential

$creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($AdminAccount, $sstr)


# Add the path of the User Profile Service to the SPO admin URL, then create a new webservice proxy to access it
$proxyaddr = "$AdminURI/_vti_bin/UserProfileService.asmx?wsdl"
$UserProfileService= New-WebServiceProxy -Uri $proxyaddr -UseDefaultCredential False
$UserProfileService.Credentials = $creds

# Set variables for authentication cookies
$strAuthCookie = $creds.GetAuthenticationCookie($AdminURI)
$uri = New-Object System.Uri($AdminURI)
$container = New-Object System.Net.CookieContainer
$container.SetCookies($uri, $strAuthCookie)
$UserProfileService.CookieContainer = $container

# Sets the first User profile, at index -1
$UserProfileResult = $UserProfileService.GetUserProfileByIndex(-1)

Write-Host "Starting- This could take a while."

$NumProfiles = $UserProfileService.GetUserProfileCount()
$i = 1

# As long as the next User profile is NOT the one we started with (at -1)...
While ($UserProfileResult.NextValue -ne -1) 
{
Write-Host "Examining profile $i of $NumProfiles"

# Look for the Personal Space object in the User Profile and retrieve it
# (PersonalSpace is the name of the path to a user's OneDrive for Business site. Users who have not yet created a 
# OneDrive for Business site might not have this property set.)
$Prop = $UserProfileResult.UserProfile | Where-Object { $_.Name -eq "PersonalSpace" } 
$Url= $Prop.Values[0].Value

# If "PersonalSpace" (which we've copied to $Url) exists, log it to our file...
if ($Url) {
$Url | Out-File $LogFile -Append -Force
}

# And now we check the next profile the same way...
$UserProfileResult = $UserProfileService.GetUserProfileByIndex($UserProfileResult.NextValue)
$i++
}

Write-Host "Done!"