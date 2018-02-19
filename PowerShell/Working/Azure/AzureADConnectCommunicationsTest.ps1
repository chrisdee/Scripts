## AAD Connect: PowerShell Script to Test Connectivity to Azure AD from Azure AD Connect Clients ##

<#
.SYNOPSIS
Test basic connectivity and name resolution for AAD Connect.

.DESCRIPTION
Use this script to test basic network connectivity to on-premises and
online endpoints as well as name resolution.

.PARAMETER AzureCredentialCheck
Check the specified credential for Azure AD suitability (valid password, is a member
of global administrators).

.PARAMETER DCs
Use this parameter to specify DCs to test against. Required if running on-
premises network or DNS tests.  This is auto-populated from the LOGONSERVER
environment variable.  If the server is not joined to a domain, populate this
attribute with a DC for the domain/forest you will be configuration AAD Connect against.

.PARAMETER DebugLogging
Enable debug error logging to log file.

.PARAMETER Dns
Use this parameter to only run on-premises Dns tests. Requires FQDN and DCs parameters
to be specified.

.PARAMETER Logfile
Self-explanatory.

.PARAMETER Network
Use this parameter to only run local network tests. Requires FQDN and DCs parameters
to be specified if they are not automatically populated.  They may not be automatically 
populated if the server running this tool has not been joined to a domain.  That is a 
supported configuration; however, you will need to specify a forest FQDN and at least
one DC.

.PARAMETER OnlineEndPoints
Use this parameter to conduct communication tests against online endpoints.

.PARAMETER SkipAzureCredentialCheck
Skip checking the Azure Credential

.PARAMETER SkipDcDnsPortCheck
If you are not using DNS services provided by the AD Site / Logon DC, then you may want
to skip checking port 53.  You must still be able to resolve _.ldap._tcp.<forestfqdn>
in order for the Active Directory Connector configuration to succeed.

.LINK 
https://blogs.technet.microsoft.com/undocumentedfeatures/2018/02/10/aad-connect-network-and-name-resolution-test/

.LINK
https://gallery.technet.microsoft.com/Azure-AD-Connect-Network-150c20a3

.NOTES
- 2018-02-12	Added additional CRL/OCSP endpoints for Entrust and Verisign.
- 2018-02-12	Added additional https:// test endpoints.
- 2018-02-12	Added DebugLogging parameter and debug logging data.
- 2018-02-12	Added extended checks for online endpoints.
- 2018-02-12	Added check for Azure AD credential (valid/invalid password, is Global Admin)
- 2018-02-12	Updated parameter check when running new mixes of options.
- 2018-02-11	Added default values for ForestFQDN and DCs.
- 2018-02-11	Added SkipDcDnsPortCheck parameter.
- 2018-02-10	Resolved issue where tests would run twice under some conditions.
- 2018-02-09	Initial release.
#>

param (
	[switch]$AzureCredentialCheck,
	[Parameter(HelpMessage="Specify the azure credential to check in the form of user@domain.com or user@tenant.onmicrosoft.com")]$AzureCredential,
	[array]$DCs = (Get-ChildItem Env:\Logonserver).Value.ToString().Trim("\") + "." + (Get-ChildItem Env:\USERDNSDOMAIN).Value.ToString(),
	[switch]$DebugLogging,
	[switch]$Dns,
	[string]$ForestFQDN = (Get-ChildItem Env:\USERDNSDOMAIN).Value.ToString(),
	[string]$Logfile = (Get-Date -Format yyyy-MM-dd) + "_AADConnectConnectivity.txt",
	[switch]$Network,
	[switch]$OnlineEndPoints,
	[switch]$SkipAzureCredentialCheck,
	[switch]$SkipDcDnsPortCheck

)

# If SkipDcDnsPortCheck is enabled, remove 53 from the list of ports to test on DCs
If ($SkipDcDnsPortCheck) { $Ports = @('135', '389', '445', '3268') }
Else {$Ports = @('53', '135', '389', '445', '3268')}

## Functions

# Logging function
function Write-Log([string[]]$Message, [string]$LogFile = $Script:LogFile, [switch]$ConsoleOutput, [ValidateSet("SUCCESS", "INFO", "WARN", "ERROR", "DEBUG")][string]$LogLevel)
{
	$Message = $Message + $Input
	If (!$LogLevel) { $LogLevel = "INFO" }
	switch ($LogLevel)
	{
		SUCCESS { $Color = "Green" }
		INFO { $Color = "White" }
		WARN { $Color = "Yellow" }
		ERROR { $Color = "Red" }
		DEBUG { $Color = "Gray" }
	}
	if ($Message -ne $null -and $Message.Length -gt 0)
	{
		$TimeStamp = [System.DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
		if ($LogFile -ne $null -and $LogFile -ne [System.String]::Empty)
		{
			Out-File -Append -FilePath $LogFile -InputObject "[$TimeStamp] [$LogLevel] $Message"
		}
		if ($ConsoleOutput -eq $true)
		{
			Write-Host "[$TimeStamp] [$LogLevel] :: $Message" -ForegroundColor $Color
		}
	}
}

# Test Office 365 Credentials
function AzureCredential
{
	If ($SkipAzureCredentialCheck) { "Skipping Azure AD Credential Check due to parameter.";  Continue}
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting Office 365 global administrator and credential tests."
	If (!$AzureCredential)
	{
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Credential required to validate Office 365 credentials."
	}
	# Attempt MSOnline installation
	Try { MSOnline }
	Catch { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to proceed with MSOnline check.  Please install the Microsoft Online Services Module separately and re-run the script." -ConsoleOutput}
	
	# Attempt to log on as user
	try
	{
		Write-Log -LogFile $Logfile -LogLevel INFO -Message "Attempting logon as $($Credential.UserName) to Azure Active Directory."
		$LogonResult = Connect-MsolService -Credential $AzureCredential -ErrorAction Stop
		If ($LogonResult -eq $null)
		{
			Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully logged on to Azure Active Directory as $($AzureCredential.UserName)." -ConsoleOutput
			## Attempt to check membership in Global Admins, which is labelled as "Company Administrator" in the tenant
			$RoleId = (Get-MsolRole -RoleName "Company Administrator").ObjectId
			If ((Get-MsolRoleMember -RoleObjectId $RoleId).EmailAddress -match "\b$($AzureCredential.UserName)")
			{
				Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "User $($AzureCredential.Username) is a member of Global Administrators." -ConsoleOutput
			}
			Else
			{
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "User $($AzureCredential.UserName) is not a member of Global Administrators.  In order for Azure Active Directory synchronization to be successful, the user must have the Global Administrators role granted in Office 365.  Grant the appropriate access or select another user account to test."	
			}
		}
		Else
		{
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to verify logon to Azure Active Directory as $($AzureCredential.UserName)." -ConsoleOutput
		}
	}
	catch
	{
		$LogonResultError = $_.Exception
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to log on to Azure Active Directory as $($AzureCredential.UserName).  Check $($Logfile) for additional details." -ConsoleOutput
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($LogonResultError)
	}
} # End Function AzureCredential

function MSOnline
{
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Checking Microsoft Online Services Module."
	If (!(Get-Module -ListAvailable MSOnline -ea silentlycontinue))
	{
		# Check if Elevated
		$wid = [system.security.principal.windowsidentity]::GetCurrent()
		$prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
		$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
		if ($prp.IsInRole($adm))
		{
			Write-Log -LogFile $Logfile -LogLevel SUCCESS -ConsoleOutput -Message "Elevated PowerShell session detected. Continuing."
		}
		else
		{
			Write-Log -LogFile $Logfile -LogLevel ERROR -ConsoleOutput -Message "This application/script must be run in an elevated PowerShell window. Please launch an elevated session and try again."
			Break
		}
		
		Write-Log -LogFile $Logfile -LogLevel INFO -ConsoleOutput -Message "This requires the Microsoft Online Services Module. Attempting to download and install."
		wget https://download.microsoft.com/download/5/0/1/5017D39B-8E29-48C8-91A8-8D0E4968E6D4/en/msoidcli_64.msi -OutFile $env:TEMP\msoidcli_64.msi
		If (!(Get-Command Install-Module))
		{
			wget https://download.microsoft.com/download/C/4/1/C41378D4-7F41-4BBE-9D0D-0E4F98585C61/PackageManagement_x64.msi -OutFile $env:TEMP\PackageManagement_x64.msi
		}
		If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing Sign-On Assistant." }
		msiexec /i $env:TEMP\msoidcli_64.msi /quiet /passive
		If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing PowerShell Get Supporting Libraries." }
		msiexec /i $env:TEMP\PackageManagement_x64.msi /qn
		If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing PowerShell Get Supporting Libraries (NuGet)." }
		Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force -Confirm:$false
		If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing Microsoft Online Services Module." }
		Install-Module MSOnline -Confirm:$false -Force
		If (!(Get-Module -ListAvailable MSOnline))
		{
			Write-Log -LogFile $Logfile -LogLevel ERROR -ConsoleOutput -Message "This Configuration requires the MSOnline Module. Please download from https://connect.microsoft.com/site1164/Downloads/DownloadDetails.aspx?DownloadID=59185 and try again."
			Break
		}
	}
	Import-Module MSOnline -Force
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished Microsoft Online Service Module check."
} # End Function MSOnline

# Test Online Networking Only
function OnlineEndPoints
{
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting Online Endpoints tests."
	$CRL = @("http://crl.microsoft.com/pki/crl/products/microsoftrootcert.crl","http://mscrl.microsoft.com/pki/mscorp/crl/msitwww2.crl","http://ocsp.verisign.com","http://ocsp.entrust.net")
	$RequiredResources = @("adminwebservice.microsoftonline.com", "login.microsoftonline.com", "provisioningapi.microsoftonline.com", "login.windows.net", "secure.aadcdn.microsoftonline-p.com")
	$RequiredResourcesEndpoints = @("https://adminwebservice.microsoftonline.com/provisioningservice.svc","https://login.microsoftonline.com","https://provisioningapi.microsoftonline.com/provisioningwebservice.svc", "https://login.windows.net", "https://secure.aadcdn.microsoftonline-p.com/ests/2.1.5975.9/content/cdnbundles/jquery.1.11.min.js")
	$OptionalResources = @("management.azure.com", "policykeyservice.dc.ad.msft.net")
	$OptionalResourcesEndpoints = @("https://policykeyservice.dc.ad.msft.net/clientregistrationmanager.svc")
	
	foreach ($url in $CRL)
	{
		try
		{
			$Result = Invoke-WebRequest -Uri $url -ea stop -wa silentlycontinue
			Switch ($Result.StatusCode)
			{
				200 { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully obtained CRL from $($url)." -ConsoleOutput }
				400 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Bad request." -ConsoleOutput }
				401 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Unauthorized." -ConsoleOutput }
				403 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Forbidden." -ConsoleOutput }
				404 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Not found." -ConsoleOutput }
				407 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Proxy authentication required." -ConsoleOutput }
				502 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Bad gateway (likely proxy)." -ConsoleOutput }
				503 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Service unavailable (transient, try again)." -ConsoleOutput }
				504 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Gateway timeout (likely proxy)." -ConsoleOutput }
				default
				{
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to obtain CRL from $($url)" -ConsoleOutput
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($Result)"
				}
			}
		}
		catch
		{
			$ErrorMessage = $_
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Unable to obtain CRL from $($url)" -ConsoleOutput
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($ErrorMessage)
		}
		finally
		{
			If ($DebugLogging)
			{
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url)."
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusCode
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusDescription
				If ($Result.RawContent.Length -lt 400)
				{
					$DebugContent = $Result.RawContent -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
				}
				Else
				{
					$DebugContent = $Result.RawContent.Substring(0, 400) -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
				}
			}
		}
	} # End Foreach CRL
	
	foreach ($url in $RequiredResources)
	{
		[array]$ResourceAddresses = (Resolve-DnsName $url).IP4Address
		foreach ($ip4 in $ResourceAddresses)
		{
			try
			{
				$Result = Test-NetConnection $ip4 -Port 443 -ea stop -wa silentlycontinue
				switch ($Result.TcpTestSucceeded)
				{
					true { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:443 successful." -ConsoleOutput }
					false { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($url) [$($ip4)]:443 failed." -ConsoleOutput }
				}
			}
			catch
			{
				$ErrorMessage = $_
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Error resolving or connecting to $($url) [$($ip4)]:443" -ConsoleOutput
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($Error)
			}
			finally
			{
				If ($DebugLogging)
				{
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url) [$($Result.RemoteAddress)]:443."
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($url)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
				}
			}
		}
	} # End Foreach Resources
	
	foreach ($url in $OptionalResources)
	{
		[array]$OptionalResourceAddresses = (Resolve-DnsName $url).IP4Address
		foreach ($ip4 in $OptionalResourceAddresses)
		{
			try
			{
				$Result = Test-NetConnection $ip4 -Port 443 -ea stop -wa silentlycontinue
				switch ($Result.TcpTestSucceeded)
				{
					true { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:443 successful." -ConsoleOutput }
					false {
						Write-Log -LogFile $Logfile -LogLevel WARN -Message "TCP connection to $($url) [$($ip4)]:443 failed." -ConsoleOutput
						If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $($Result) }
					}
				}
			}
			catch
			{
				$ErrorMessage = $_
				Write-Log -LogFile $Logfile -LogLevel WARN -Message "Error resolving or connecting to $($url) [$($ip4)]:443" -ConsoleOutput
				Write-Log -LogFile $Logfile -LogLevel WARN -Message $($ErrorMessage)
			}
			finally
			{
				If ($DebugLogging)
				{
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url) [$($Result.RemoteAddress)]:443."
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($url)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
				}
			}
		}
	} # End Foreach OptionalResources
	
	foreach ($url in $RequiredResourcesEndpoints)
	{
		try
		{
			$Result = Invoke-WebRequest -Uri $url -ea stop -wa silentlycontinue
			Switch ($Result.StatusCode)
			{
				200 { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully connected to $($url)." -ConsoleOutput }
				400 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad request." -ConsoleOutput }
				401 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Unauthorized." -ConsoleOutput }
				403 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Forbidden." -ConsoleOutput }
				404 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Not found." -ConsoleOutput }
				407 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Proxy authentication required." -ConsoleOutput }
				502 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad gateway (likely proxy)." -ConsoleOutput }
				503 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Service unavailable (transient, try again)." -ConsoleOutput }
				504 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Gateway timeout (likely proxy)." -ConsoleOutput }
				default
				{
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "OTHER: Failed to contact $($url)" -ConsoleOutput
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($Result)" -ConsoleOutput
				}
			}
		}
		catch
		{
			$ErrorMessage = $_
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Unable to contact $($url)" -ConsoleOutput
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($ErrorMessage)
		}
		finally
		{
			If ($DebugLogging)
			{
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url)."
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusCode
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusDescription
				If ($Result.RawContent.Length -lt 400)
				{
					$DebugContent = $Result.RawContent -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
				}
				Else
				{
					$DebugContent = $Result.RawContent -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent.Substring(0, 400)
				}
			}
		}
	} # End Foreach RequiredResourcesEndpoints
	
	foreach ($url in $OptionalResourcesEndpoints)
	{
		try
		{
			$Result = Invoke-WebRequest -Uri $url -ea stop -wa silentlycontinue
			Switch ($Result.StatusCode)
			{
				200 { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully connected to $($url)." -ConsoleOutput }
				400 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad request." -ConsoleOutput }
				401 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Unauthorized." -ConsoleOutput }
				403 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Forbidden." -ConsoleOutput }
				404 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Not found." -ConsoleOutput }
				407 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Proxy authentication required." -ConsoleOutput }
				502 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad gateway (likely proxy)." -ConsoleOutput }
				503 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Service unavailable (transient, try again)." -ConsoleOutput }
				504 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Gateway timeout (likely proxy)." -ConsoleOutput }
				default
				{
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "OTHER: Failed to contact $($url)" -ConsoleOutput
					Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($Result)" -ConsoleOutput
				}
			}
		}
		catch
		{
			$ErrorMessage = $_
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Unable to contact $($url)" -ConsoleOutput
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($ErrorMessage)
		}
		finally
		{
			If ($DebugLogging)
			{
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url)."
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusCode
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusDescription
				If ($Result.RawContent.Length -lt 400)
				{
					$DebugContent = $Result.RawContent -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
				}
				Else
				{
					$DebugContent = $Result.RawContent -join ";"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent.Substring(0, 400)
				}
			}
		}
	} # End Foreach RequiredResourcesEndpoints
	
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished Online Endpoints tests."
} # End Function OnlineEndPoints

# Test Local Networking Only
function Network
{
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting local network port tests."
	If (!$DCs)
	{
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "If testing on-premises networking, you must specify at least one on-premises domain controller." -ConsoleOutput
		Break
	}
	Foreach ($Destination in $DCs)
	{
		foreach ($Port in $Ports)
		{
			Try
			{
				$Result = (Test-NetConnection -ComputerName $Destination -Port $Port -ea Stop -wa SilentlyContinue)
				Switch ($Result.TcpTestSucceeded)
				{
					True
					{
						Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($Destination):$($Port) succeeded." -ConsoleOutput
					}
					False
					{
						Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($Destination):$($Port) failed." -ConsoleOutput
						Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$Result"
					}
				} # End Switch
			}
			Catch
			{
				$ErrorMessage = $_
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Error attempting TCP connection to $($Destination):$($Port)." -ConsoleOutput
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message $ErrorMessage
			}
			Finally
			{
				If ($DebugLogging)
				{
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($Destination) [$($Result.RemoteAddress)]:$($Port)."
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($Destination)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
					Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
				}
			}
		} # End Foreach Port
	} # End Foreach Destination
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished local network port tests."
} # End Function Network

# Test local DNS resolution for domain controllers
function Dns
{
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting local DNS resolution tests."
	If (!$ForestFQDN)
	{
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Local Dns resolution, you must specify for Active Directory Forest FQDN." -ConsoleOutput
		Break
	}
	
	If (!$DCs)
	{
		Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Local DNS resolution testing requires the DCs parameter to be specified." -ConsoleOutput
		Break
	}
	# Attempt DNS Resolution
	$DnsTargets = @("_ldap._tcp.$ForestFQDN") + $DCs
	Foreach ($HostName in $DnsTargets)
	{
		Try
		{
			$DnsResult = (Resolve-DnsName -Type ANY $HostName -ea Stop -wa SilentlyContinue)
			If ($DnsResult.Name)
			{
				Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully resolved $($HostName)." -ConsoleOutput
			}
			Else
			{
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Error attempting DNS resolution for $($HostName)." -ConsoleOutput
				Write-Log -LogFile $Logfile -LogLevel ERROR -Message $DnsResult
			}
		}
		Catch
		{
			$ErrorMessage = $_
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Error attempting DNS resolution for $($HostName)." -ConsoleOutput
			Write-Log -LogFile $Logfile -LogLevel ERROR -Message $ErrorMessage
		}
		Finally
		{
			If ($DebugLogging)
			{
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($HostName)."
				Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DnsResult
			}
		}
	}
	Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished local DNS resolution tests."
}

Write-Log -LogFile $Logfile -LogLevel INFO -Message "========================================================="
Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting AAD Connect connectivity and resolution testing."

If ($PSBoundParameters.Keys -notmatch "\bdns\b|onlineendpoints|network|\bazurecredentialcheck\b|\bdebuglogging\b|\bskipazurecredentialcheck\b")
{
	Write-Host "Running all tests."
	OnlineEndPoints; Network; Dns; AzureCredential
}
Else
{
	switch ($PSBoundParameters.Keys)
	{
		OnlineEndPoints { OnlineEndPoints }
		Network { Network }
		Dns { Dns }
		AzureCredentialCheck { AzureCredential }
	}
}
Write-Log -LogFile $Logfile -LogLevel INFO -Message "Done! Logfile is $($Logfile)." -ConsoleOutput
Write-Log -LogFile $Logfile -LogLevel INFO -Message "---------------------------------------------------------"