<# SharePoint Server: PowerShell Functions To Get Orphaned User Accounts Across Web Applications Or Site Collections

Overview: PowerShell functions that query AD and the Object Model to produce a list of all accounts that exist in SharePoint, but are no longer in AD

Usage: Add your functions with parameters specific to your environment under the 'function StartProcess' area of the script and run the script

Usage Example: GetSharePointOrphanedUsers.ps1 > "orphaned_users_report.txt"

Environments: MOSS 2007 Farms

Resources: http://sharepointpsscripts.codeplex.com/releases/view/21699; http://sharepointpsscripts.codeplex.com/releases/view/21693

#>

function Check_User_In_ActiveDirectory([string]$LoginName, [string]$domaincnx)
{
	$returnValue = $false
	#Filter on User which exists and activated
	#$strFilter = "(&(objectCategory=user)(objectClass=user)(!userAccountControl:1.2.840.113556.1.4.803:=2)(samAccountName=$LoginName))"
	#Filter on User which only exists
	#$strFilter = "(&(objectCategory=user)(objectClass=user)(samAccountName=$LoginName))"
	#Filter on User and NTgroups which only exists
	$strFilter = "(&(|(objectCategory=user)(objectCategory=group))(samAccountName=$LoginName))"
	$objDomain = New-Object System.DirectoryServices.DirectoryEntry($domaincnx)

	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
	$objSearcher.SearchRoot = $objDomain
	$objSearcher.PageSize = 1000
	$objSearcher.Filter = $strFilter
	$objSearcher.SearchScope = "Subtree"

	#$objSearcher.PropertiesToLoad.Add("name")

	$colResults = $objSearcher.FindAll()

	if($colResults.Count -gt 0)
	{
		#Write-Host "Account exists and Active: ", $LoginName
		$returnValue = $true
	}
	return $returnValue
}

function ListOrphanedUsers([string]$SiteCollectionURL, [string]$mydomaincnx)
{
	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null
	$site = new-object Microsoft.SharePoint.SPSite($SiteCollectionURL)
	$web = $site.openweb()

	#Debugging - show SiteCollectionURL
	write-host "SiteCollectionURL: ", $SiteCollectionURL
	Write-Output "SiteCollectionURL - $SiteCollectionURL"

	$siteCollUsers = $web.SiteUsers
	write-host "Users Items: ", $siteCollUsers.Count

	foreach($MyUser in $siteCollUsers)
	{
		if(($MyUser.LoginName.ToLower() -ne "sharepoint\system") -and ($MyUser.LoginName.ToLower() -ne "nt authority\authenticated users") -and ($MyUser.LoginName.ToLower() -ne "nt authority\local service"))
		{
			#Write-Host "  USER: ", $MyUser.LoginName
			$UserName = $MyUser.LoginName.ToLower()
			$Tablename = $UserName.split("\")
			Write-Host "User Login: ", $MyUser.LoginName
			
			$returncheck = Check_User_In_ActiveDirectory $Tablename[1] $mydomaincnx 
			if($returncheck -eq $False)
			{
				#Write-Host "User not exist: ",  $MyUser.LoginName, "on domain", $mydomaincnx 
				Write-Output $MyUser.LoginName 
			}
		}
	}

	$web.Dispose()
	$site.Dispose()

}

function ListOrphanedUsersForAllColl([string]$WebAppURL, [string]$DomainCNX)
{

	[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > $null

	$Thesite = new-object Microsoft.SharePoint.SPSite($WebAppURL)
	$oApp = $Thesite.WebApplication
	write-host "Total of Site Collections: ", $oApp.Sites.Count

	$i = 0
	foreach ($Sites in $oApp.Sites)
	{
		$i = $i + 1
		write-host "Collection N° ", $i, "on ", $oApp.Sites.Count

		if($i -gt 0)
		{
			$mySubweb = $Sites.RootWeb
			$TempRelativeURL = $mySubweb.Url
			ListOrphanedUsers $TempRelativeURL $DomainCNX
		}
    }

}

function StartProcess()
{
	# Create the stopwatch
	[System.Diagnostics.Stopwatch] $sw;
	$sw = New-Object System.Diagnostics.StopWatch
	$sw.Start()
	#cls

    # Call your functions - 'ListOrphanedUsersForAllColl' = web application level; ListOrphanedUsers = site collection level

	ListOrphanedUsersForAllColl "http://myWebApplication" "LDAP://DC=MyDomain,DC=com" #Change this to suit your environment
    ListOrphanedUsers "http://myWebApplication01/mySiteCollection" "LDAP://DC=MyDomain,DC=com" #Change this to suit your environment

	$sw.Stop()

	# Write the compact output to the screen
	write-host "Time: ", $sw.Elapsed.ToString()
}

StartProcess
