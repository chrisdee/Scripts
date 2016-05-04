## SharePoint Server: PowerShell Functions to allow People Picker to select user accounts across trusted Domains ##

<#

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the 'SetAppPassword' and 'PeoplePickerSearchADForests' functions parameters at the end of the script, and run this on each machine in your SharePoint Farm

Usage Syntax: SetAppPassword <password>; PeoplePickerSearchADForests <url> "forest:<source forest>;domain:<trusted domain>"

Tip: If prompted to provide trust credentials; ensure that you put the domain prefix before your credentials

Resource: http://blog.hompus.nl/2011/01/17/configure-people-picker-over-a-one-way-trust-using-powershell

STSADM -o setapppassword -password <password>

Trouble-shooting:

In the windows application event log you encounter the following error message: 'An exception occurred in AD claim provider when calling SPClaimProvider.FillSearch(): Requested registry access is not allowed..'

Your Web Application Pool Account needs read access to the following Registry Key: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\15.0\Secure

** Your Web Applications app pool accounts should normally be members of the 'WSS_WPG' group; so add this with read access to the registry key

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

function SetAppPassword([String]$password) {
	$type = [Microsoft.SharePoint.Utilities.SPPropertyBag].Assembly.GetType("Microsoft.SharePoint.Utilities.SPSecureString")
	$method = $type.GetMethod("FromString", "Static, NonPublic", $null, @([String]), $null)
	$secureString = $method.Invoke($null, @($password))
	[Microsoft.SharePoint.SPSecurity]::SetApplicationCredentialKey($secureString)
}


# STSADM -o setproperty -url <url> -pn "peoplepicker-searchadforests" -pv <trust domain value>


function PeoplePickerSearchADForests([String]$webApplicationUrl, [String]$value) {
	$webApplication = Get-SPWebApplication $webApplicationUrl

	$searchActiveDirectoryDomains = $webApplication.PeoplePickerSettings.SearchActiveDirectoryDomains
	$searchActiveDirectoryDomains.Clear()

	$currentDomain = (Get-WmiObject -Class Win32_ComputerSystem).Domain

	if (![String]::IsNullOrEmpty($value)) {
		$value.Split(@(';'), "RemoveEmptyEntries") | ForEach { 
			$strArray = $_.Split(@(';'))
		
			$item = New-Object Microsoft.SharePoint.Administration.SPPeoplePickerSearchActiveDirectoryDomain
		
			[String]$value = $strArray[0]

			$index = $value.IndexOf(':');
			if ($index -ge 0) {
				$item.DomainName = $value.Substring($index + 1);
			} else {
				$item.DomainName = $value;
			}

			if ([System.Globalization.CultureInfo]::InvariantCulture.CompareInfo.IsPrefix($value, "domain:", "IgnoreCase")) {
				$item.IsForest = $false;
			} else {
				$item.IsForest = $true;
			}

			if ($item.DomainName -ne $currentDomain) {
				$credentials = $host.ui.PromptForCredential("Foreign domain trust credentials", "Please enter the trust credentials to connect to the " + $item.DomainName + " domain", "", "")

				$item.LoginName = $credentials.UserName;
				$item.SetPassword($credentials.Password);
			}
	
			$searchActiveDirectoryDomains.Add($item);
		}

		$webApplication.Update()
	}
}

## Example: Allowing a portal application communicate with 'theglobalfund' forest from another domain called 'npe'

SetAppPassword "YourPasswordHere"

PeoplePickerSearchADForests "http://portal.npe.theglobalfund.org" "forest:theglobalfund.org;domain:npe.theglobalfund.org"
