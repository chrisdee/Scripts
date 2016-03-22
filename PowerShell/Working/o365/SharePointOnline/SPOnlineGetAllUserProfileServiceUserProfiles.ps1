## SharePoint Online: PowerShell Script to Export User Profile Service Profiles Data From a Tenant via CSOM (SPOnline) ##

<#

Overview: PowerShell Script that Exports All User Profile Service User Profiles to a CSV File via CSOM

Usage: Provide parameters listed below, and the paths to your SharePoint binaries for the CSOM

Provide the required Parameters below in the Script: 

$site: SharePoint Online My Site Collection
$admin: SharePoint Online Account with SPAdmin access 
$password: Provide the password for the Admin account when prompted

Provide the paths to your SharePoint DLLs for CSOM under '#Adding the CSOM Assemblies'

Provide the path to your CSV report file under '$collection'

Note: You can add / map additional properties under '#Add required User Information fields'

List of main User Profile Properties:

UserProfile_GUID
SID
ADGuid
AccountName
FirstName
SPS-PhoneticFirstName
LastName
SPS-PhoneticLastName
PreferredName
SPS-PhoneticDisplayName
WorkPhone
Department
Title
SPS-JobTitle
SPS-Department
Manager
AboutMe
PersonalSpace
PictureURL
UserName
QuickLinks
WebSite
SPS-DataSource  
SPS-MemberOf   
SPS-Dotted-line   
SPS-Peers  
SPS-Responsibility  
SPS-SipAddress   
SPS-MySiteUpgrade   
SPS-DontSuggestList   
SPS-ProxyAddresses   
SPS-HireDate   
SPS-DisplayOrder   
SPS-ClaimID   
SPS-ClaimProviderID   
SPS-ClaimProviderType   
SPS-LastColleagueAdded   
SPS-OWAUrl   
SPS-SavedAccountName   
SPS-SavedSID   
SPS-ResourceSID   
SPS-ResourceAccountName   
SPS-ObjectExists   
SPS-MasterAccountName   
SPS-UserPrincipalName   
SPS-PersonalSiteCapabilities   
SPS-O15FirstRunExperience   
SPS-PersonalSiteFirstCreationTime  
SPS-PersonalSiteLastCreationTime   
SPS-PersonalSiteNumberOfRetries   
SPS-PersonalSiteFirstCreationError  
SPS-DistinguishedName   
SPS-SourceObjectDN   
SPS-LastKeywordAdded   
SPS-FeedIdentifier   
SPS-PersonalSiteInstantiationState   
WorkEmail   
CellPhone  
Fax   
HomePhone   
Office  
SPS-Location   
Assistant   
SPS-PastProjects   
SPS-Skills   
SPS-School   
SPS-Birthday   
SPS-StatusNotes   
SPS-Interests   
SPS-HashTags  
SPS-PictureTimestamp   
SPS-EmailOptin   
SPS-PicturePlaceholderState   
SPS-PrivacyPeople   
SPS-PrivacyActivity   
SPS-PictureExchangeSyncState   
SPS-MUILanguages   
SPS-ContentLanguages  
SPS-TimeZone   
SPS-RegionalSettings-FollowWeb   
SPS-Locale   
SPS-CalendarType   
SPS-AltCalendarType  
SPS-AdjustHijriDays   
SPS-ShowWeeks   
SPS-WorkDays   
SPS-WorkDayStartHour  
SPS-WorkDayEndHour   
SPS-Time24   
SPS-FirstDayOfWeek   
SPS-FirstWeekOfYear   
SPS-RegionalSettings-Initialized   
OfficeGraphEnabled

Resource: http://social.technet.microsoft.com/wiki/contents/articles/29415.export-sharepoint-online-user-profile-information-using-powershell-csom.aspx

#>

#Adding the CSOM Assemblies
Add-Type -Path "C:\ztemp\SPDLLs\Microsoft.SharePoint.Client.dll" #Change this path to match your environment
Add-Type -Path "C:\ztemp\SPDLLs\Microsoft.SharePoint.Client.Runtime.dll"  #Change this path to match your environment
Add-Type -Path 'C:\ztemp\SPDLLs\Microsoft.SharePoint.Client.UserProfiles.dll' #Change this path to match your environment

#Mysite URL
$site = 'https://TenantName-my.sharepoint.com/'

#Admin User Principal Name
$admin = 'User.Name@TenantName.onmicrosoft.com'

#Get Password as secure String
$password = Read-Host 'Enter Password' -AsSecureString

#Get the Client Context and Bind the Site Collection
$context = New-Object Microsoft.SharePoint.Client.ClientContext($site)

#Authenticate
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($admin , $password)
$context.Credentials = $credentials

#Fetch the users in Site Collection
$users = $context.Web.SiteUsers
$context.Load($users)
$context.ExecuteQuery()

#Create an Object [People Manager] to retrieve profile information
$people = New-Object Microsoft.SharePoint.Client.UserProfiles.PeopleManager($context)
$collection = @()
Foreach($user in $users)
{
    $userprofile = $people.GetPropertiesFor($user.LoginName)
    $context.Load($userprofile)
    $context.ExecuteQuery()
    if($userprofile.Email -ne $null)
    {
        $upp = $userprofile.UserProfileProperties
        foreach($ups in $upp)
        {
            #Add required User Information fields.
            $profileData = "" | Select "AccountName", "FirstName" , "LastName" , "Department", "WorkEmail" , "Title" , "Responsibility"
            $profileData.AccountName = $ups.AccountName
            $profileData.FirstName = $ups.FirstName
            $profileData.LastName = $ups.LastName
            $profileData.Department = $ups.Department
            $profileData.WorkEmail = $ups.WorkEmail
            $profileData.Responsibility = $ups.'SPS-Responsibility'
            $collection += $profileData
        }
    }
}
$collection | Export-Csv 'C:\ztemp\SPDLLs\SPOnlineUserProfileInformation.csv' -NoTypeInformation -Encoding UTF8 #Change the 'Export-Csv' path to match your environment