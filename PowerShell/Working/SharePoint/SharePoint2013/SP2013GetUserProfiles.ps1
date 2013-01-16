## SharePoint Server: PowerShell Script To Extract All User Profile Details From A Web Application ##

<#

Overview: The script below was generated using the 'UserProfileExport' tool listed under the resource link below. The script takes all possible user profile properties selectable in the 'UserProfileExport' tool and exports all user profiles from a specified web application.

Usage: Edit the '-Site' parameter in the '$serviceContext' variable to suit your environment, as well as the CSV file details under the 'Add-Content' commandlet. Save and run the script with the farm admin account or farm administrative rights.

Important: The script must be run under the farm account credentials, or with farm administrative rights.

Resource: http://csefi.blogspot.in/2012/02/sharepoint-2010-user-profile-export-to.html

#>

Add-PSSnapin "Microsoft.Sharepoint.PowerShell" -ErrorAction SilentlyContinue

function AppendValue([string] $propertyName)
{
	if($userProfile[$propertyName] -ne "")
	{
		$sb.AppendFormat("{0};", $userProfile[$propertyName])
	}
	else
	{
		$sb.Append(";")
	}
}
$sb = New-Object System.Text.StringBuilder 
	$sb.AppendLine("UserProfile_GUID;AccountName;FirstName;SPS-PhoneticFirstName;LastName;SPS-PhoneticLastName;PreferredName;SPS-PhoneticDisplayName;WorkPhone;Department;Title;SPS-JobTitle;SPS-Department;Manager;AboutMe;PersonalSpace;PictureURL;UserName;QuickLinks;WebSite;PublicSiteRedirect;SPS-DataSource;SPS-MemberOf;SPS-Dotted-line;SPS-Peers;SPS-Responsibility;SPS-SipAddress;SPS-MySiteUpgrade;SPS-DontSuggestList;SPS-ProxyAddresses;SPS-HireDate;SPS-DisplayOrder;SPS-ClaimID;SPS-ClaimProviderID;SPS-ClaimProviderType;SPS-LastColleagueAdded;SPS-OWAUrl;SPS-SavedAccountName;SPS-ResourceAccountName;SPS-ObjectExists;SPS-MasterAccountName;SPS-UserPrincipalName;SPS-PersonalSiteCapabilities;SPS-O15FirstRunExperience;SPS-PersonalSiteInstantiationState;SPS-DistinguishedName;SPS-SourceObjectDN;SPS-LastKeywordAdded;SPS-FeedIdentifier;WorkEmail;CellPhone;Fax;HomePhone;Office;SPS-Location;Assistant;SPS-PastProjects;SPS-Skills;SPS-School;SPS-Birthday;SPS-StatusNotes;SPS-Interests;SPS-HashTags;SPS-EmailOptin;SPS-PrivacyPeople;SPS-PrivacyActivity;SPS-MUILanguages;SPS-ContentLanguages;SPS-TimeZone;SPS-RegionalSettings-FollowWeb;SPS-Locale;SPS-CalendarType;SPS-AltCalendarType;SPS-AdjustHijriDays;SPS-ShowWeeks;SPS-WorkDays;SPS-WorkDayStartHour;SPS-WorkDayEndHour;SPS-Time24;SPS-FirstDayOfWeek;SPS-FirstWeekOfYear;SPS-RegionalSettings-Initialized;")
$serviceContext = Get-SPServiceContext -Site http://YourWebApplication.com #Change this URL to suit your environment
$profileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($serviceContext);
$profiles = $profileManager.GetEnumerator()
foreach($userProfile in $profiles)
{
	AppendValue("UserProfile_GUID")
	AppendValue("AccountName")
	AppendValue("FirstName")
	AppendValue("SPS-PhoneticFirstName")
	AppendValue("LastName")
	AppendValue("SPS-PhoneticLastName")
	AppendValue("PreferredName")
	AppendValue("SPS-PhoneticDisplayName")
	AppendValue("WorkPhone")
	AppendValue("Department")
	AppendValue("Title")
	AppendValue("SPS-JobTitle")
	AppendValue("SPS-Department")
	AppendValue("Manager")
	AppendValue("AboutMe")
	AppendValue("PersonalSpace")
	AppendValue("PictureURL")
	AppendValue("UserName")
	AppendValue("QuickLinks")
	AppendValue("WebSite")
	AppendValue("PublicSiteRedirect")
	AppendValue("SPS-DataSource")
	AppendValue("SPS-MemberOf")
	AppendValue("SPS-Dotted-line")
	AppendValue("SPS-Peers")
	AppendValue("SPS-Responsibility")
	AppendValue("SPS-SipAddress")
	AppendValue("SPS-MySiteUpgrade")
	AppendValue("SPS-DontSuggestList")
	AppendValue("SPS-ProxyAddresses")
	AppendValue("SPS-HireDate")
	AppendValue("SPS-DisplayOrder")
	AppendValue("SPS-ClaimID")
	AppendValue("SPS-ClaimProviderID")
	AppendValue("SPS-ClaimProviderType")
	AppendValue("SPS-LastColleagueAdded")
	AppendValue("SPS-OWAUrl")
	AppendValue("SPS-SavedAccountName")
	AppendValue("SPS-ResourceAccountName")
	AppendValue("SPS-ObjectExists")
	AppendValue("SPS-MasterAccountName")
	AppendValue("SPS-UserPrincipalName")
	AppendValue("SPS-PersonalSiteCapabilities")
	AppendValue("SPS-O15FirstRunExperience")
	AppendValue("SPS-PersonalSiteInstantiationState")
	AppendValue("SPS-DistinguishedName")
	AppendValue("SPS-SourceObjectDN")
	AppendValue("SPS-LastKeywordAdded")
	AppendValue("SPS-FeedIdentifier")
	AppendValue("WorkEmail")
	AppendValue("CellPhone")
	AppendValue("Fax")
	AppendValue("HomePhone")
	AppendValue("Office")
	AppendValue("SPS-Location")
	AppendValue("Assistant")
	AppendValue("SPS-PastProjects")
	AppendValue("SPS-Skills")
	AppendValue("SPS-School")
	AppendValue("SPS-Birthday")
	AppendValue("SPS-StatusNotes")
	AppendValue("SPS-Interests")
	AppendValue("SPS-HashTags")
	AppendValue("SPS-EmailOptin")
	AppendValue("SPS-PrivacyPeople")
	AppendValue("SPS-PrivacyActivity")
	AppendValue("SPS-MUILanguages")
	AppendValue("SPS-ContentLanguages")
	AppendValue("SPS-TimeZone")
	AppendValue("SPS-RegionalSettings-FollowWeb")
	AppendValue("SPS-Locale")
	AppendValue("SPS-CalendarType")
	AppendValue("SPS-AltCalendarType")
	AppendValue("SPS-AdjustHijriDays")
	AppendValue("SPS-ShowWeeks")
	AppendValue("SPS-WorkDays")
	AppendValue("SPS-WorkDayStartHour")
	AppendValue("SPS-WorkDayEndHour")
	AppendValue("SPS-Time24")
	AppendValue("SPS-FirstDayOfWeek")
	AppendValue("SPS-FirstWeekOfYear")
	AppendValue("SPS-RegionalSettings-Initialized")
$sb.AppendLine()
}
Add-Content UserProfileExport.csv $sb #Change the csv file details to suit your environment