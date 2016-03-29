##  MSOnline: PowerShell Script to Get Detailed Office 365 User Information With Regards To User MSOnline and Exchange Online Properties (o365 / MSOnline / ExchangeOnline) ##

#------------------------------------------------------------------------------
#
# Copyright © 2012 Microsoft Corporation.  All rights reserved.
#
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR 
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#
#------------------------------------------------------------------------------
#
# PowerShell Source Code
#
# NAME:
#    GetMSOnlineUserReport.ps1
#
# AUTHOR(s):
#    Thomas Ashworth
#
#------------------------------------------------------------------------------

<#
	.SYNOPSIS
		Generates a CSV report containing both general and Exchange Online related information about
		users in Office 365.

	.DESCRIPTION
		This script will establish a connection with the Office 365 provision web service API and Exchange
		Online (https://ps.outlook.com/powershell) and collect information about users including licenses,
		mailbox usage, retention, activesync devices, etc.

		If a credential is specified, it will be used to establish a connection with the provisioning
		web service API.
		
		If a credential is not specified, an attempt is made to identify an existing connection to
		the provisioning web service API.  If an existing connection is identified, the existing
		connection is used.  If an existing connection is not identified, the user is prompted for
		credentials so that a new connection can be established.
			
		If a credential is specified, it will be used to establish a new remote PowerShell session connected
		to Exchange Online.  If a PowerShell session(s) exists that is connected to Exchange Online, the 
		session(s) will be removed so that a new session can be created using the specified credential.
		
		If a credential is not specified, an attempt is made to connect to Exchange Online.  If the connection
		attempt is successful, the existing connection is used.  If it is not successful, the user is prompted
		for credentials so that a new connection can be established.

	.PARAMETER Credential
		Specifies the credential to use when connecting to the Office 365 provisioning web service API
		using Connect-MsolService, and when connecting to Exchange Online (https://ps.outlook.com/powershell).

	.PARAMETER OutputFile
		Specifies the name of the output file.  The arguement can be the full path including the file
		name, or only the path to the folder in which to save the file (uses default name).
		
		Default filename is in the format of "YYYYMMDDhhmmss_MsolUserReport.csv"

	.EXAMPLE
		PS> .\GetMSOnlineUserReport.ps1

	.EXAMPLE
		PS> .\GetMSOnlineUserReport.ps1 -Credential (Get-Credential)

	.EXAMPLE
		PS> .\GetMSOnlineUserReport.ps1 -OutputFile "C:\Folder\Sub Folder"

	.EXAMPLE
		PS> .\GetMSOnlineUserReport.ps1 -OutputFile "C:\Folder\Sub Folder\File Name.csv"

	.EXAMPLE
		PS> .\GetMSOnlineUserReport.ps1 -Credential (Get-Credential) -OutputFile "C:\Folder\Sub Folder"

	.EXAMPLE
		PS> .\GetMSOnlineUserReport.ps1 -Credential (Get-Credential) -OutputFile "C:\Folder\Sub Folder\File Name.csv"

	.INPUTS
		System.Management.Automation.PsCredential
		System.String

	.OUTPUTS
		A CSV file.

	.NOTES

#>


[CmdletBinding()]
param
(
	[Parameter(Mandatory = $False)]
	[System.Management.Automation.PsCredential]$Credential,
	
	[Parameter(Mandatory = $False)]
	[String]$OutputFile = "$((Get-Date -uformat %Y%m%d%H%M%S).ToString())_MsolUserReport.csv"
)


Function WriteConsoleMessage
{
	<#
		.SYNOPSIS
			Writes the specified message of the specified message type to
			the PowerShell console.

		.DESCRIPTION
			Writes the specified message of the specified message type to
			the PowerShell console.

		.PARAMETER Message
			Specifies the actual message to be written to the console.

		.PARAMETER MessageType
			Specifies the type of message to be written of either "error", "warning",
			"verbose", or "information".  The message type simply changes the 
			background and foreground colors so that the type of message is known
			at a glance.

		.EXAMPLE
			PS> WriteConsoleMessage -Message "This is an error message" -MessageType "Error"

		.EXAMPLE
			PS> WriteConsoleMessage -Message "This is a warning message" -MessageType "Warning"

		.EXAMPLE
			PS> WriteConsoleMessage -Message "This is a verbose message" -MessageType "Verbose"

		.EXAMPLE
			PS> WriteConsoleMessage -Message "This is an information message" -MessageType "Information"

		.INPUTS
			System.String

		.OUTPUTS
			A message is written to the PowerShell console.

		.NOTES

	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, Position = 0)]
		[string]$Message,
		
		[Parameter(Mandatory = $True, Position = 1)]
		[ValidateSet("Error", "Warning", "Verbose", "Information")]
		[string]$MessageType
	)
	
	Switch ($MessageType)
	{
		"Error"
		{
			$Message = "ERROR: SCRIPT: {0}" -f $Message
			Write-Host $Message -ForegroundColor Black -BackgroundColor Red
		}
		"Warning"
		{
			$Message = "WARNING: SCRIPT: {0}" -f $Message
			Write-Host $Message -ForegroundColor Black -BackgroundColor Yellow
		}
		"Verbose"
		{
			$Message = "VERBOSE: SCRIPT: {0}" -f $Message
			If ($VerbosePreference -eq "Continue") {Write-Host $Message -ForegroundColor Gray -BackgroundColor Black}
		}
		"Information"
		{
			$Message = "INFORMATION: SCRIPT: {0}" -f $Message
			Write-Host $Message -ForegroundColor Cyan -BackgroundColor Black
		}
	}
}


Function TestFolderExists
{
	<#
		.SYNOPSIS
			Verifies that the specified folder/path exists.

		.DESCRIPTION
			Verifies that the specified folder/path exists.

		.PARAMETER Folder
			Specifies the absolute or relative path to the file.

		.EXAMPLE
			PS> TestFolderExists -Folder "C:\Folder\Sub Folder\File name.csv"

		.EXAMPLE
			PS> TestFolderExists -Folder "File name.csv"

		.EXAMPLE
			PS> TestFolderExists -Folder "C:\Folder\Sub Folder"

		.EXAMPLE
			PS> TestFolderExists -Folder ".\Folder\Sub Folder"

		.INPUTS
			System.String

		.OUTPUTS
			System.Boolean

		.NOTES

	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[string]$Folder
	)

	If ([System.IO.Path]::HasExtension($Folder)) {$PathToFile = ([System.IO.Directory]::GetParent($Folder)).FullName}
	Else {$PathToFile = [System.IO.Path]::GetFullPath($Folder)}
	If ([System.IO.Directory]::Exists($PathToFile)) {Return $True}
	Return $False
}


Function GetElapsedTime
{
	<#
		.SYNOPSIS
			Calculates a time interval between two DateTime objects.

		.DESCRIPTION
			Calculates a time interval between two DateTime objects.

		.PARAMETER Start
			Specifies the start time.

		.PARAMETER End
			Specifies the end time.

		.EXAMPLE
			PS> GetElapsedTime -Start "1/1/2011 12:00:00 AM" -End "1/2/2011 2:00:00 PM"

		.EXAMPLE
			PS> GetElapsedTime -Start ([datetime]"1/1/2011 12:00:00 AM") -End ([datetime]"1/2/2011 2:00:00 PM")

		.INPUTS
			System.String

		.OUTPUTS
			System.Management.Automation.PSObject

		.NOTES

	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True, Position = 0)]
		[DateTime]$Start,
		
		[Parameter(Mandatory = $True, Position = 1)]
		[DateTime]$End
	)
	
	$TotalSeconds = ($End).Subtract($Start).TotalSeconds
	$objElapsedTime = New-Object PSObject
	
	# less than 1 minute
	If ($TotalSeconds -lt 60)
	{
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Days -Value 0
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Hours -Value 0
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Minutes -Value 0
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Seconds -Value $($TotalSeconds)
	}

	# more than 1 minute, less than 1 hour
	If (($TotalSeconds -ge 60) -and ($TotalSeconds -lt 3600))
	{
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Days -Value 0
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Hours -Value 0
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Minutes -Value $([Math]::Truncate($TotalSeconds / 60))
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Seconds -Value $([Math]::Truncate($TotalSeconds % 60))
	}

	# more than 1 hour, less than 1 day
	If (($TotalSeconds -ge 3600) -and ($TotalSeconds -lt 86400))
	{
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Days -Value 0
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Hours -Value $([Math]::Truncate($TotalSeconds / 3600))
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Minutes -Value $([Math]::Truncate(($TotalSeconds % 3600) / 60))
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Seconds -Value $([Math]::Truncate($TotalSeconds % 60))
	}

	# more than 1 day, less than 1 year
	If (($TotalSeconds -ge 86400) -and ($TotalSeconds -lt 31536000))
	{
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Days -Value $([Math]::Truncate($TotalSeconds / 86400))
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Hours -Value $([Math]::Truncate(($TotalSeconds % 86400) / 3600))
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Minutes -Value $([Math]::Truncate((($TotalSeconds - 86400) % 3600) / 60))
		Add-Member -InputObject $objElapsedTime -MemberType NoteProperty -Name Seconds -Value $([Math]::Truncate($TotalSeconds % 60))
	}
	
	Return $objElapsedTime
}


Function ConnectProvisioningWebServiceAPI
{
	<#
		.SYNOPSIS
			Connects to the Office 365 provisioning web service API.

		.DESCRIPTION
			Connects to the Office 365 provisioning web service API.
			
			If a credential is specified, it will be used to establish a connection with the provisioning
			web service API.
			
			If a credential is not specified, an attempt is made to identify an existing connection to
			the provisioning web service API.  If an existing connection is identified, the existing
			connection is used.  If an existing connection is not identified, the user is prompted for
			credentials so that a new connection can be established.

		.PARAMETER Credential
			Specifies the credential to use when connecting to the provisioning web service API
			using Connect-MsolService.

		.EXAMPLE
			PS> ConnectProvisioningWebServiceAPI

		.EXAMPLE
			PS> ConnectProvisioningWebServiceAPI -Credential
			
		.INPUTS
			[System.Management.Automation.PsCredential]

		.OUTPUTS

		.NOTES

	#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $False)]
		[System.Management.Automation.PsCredential]$Credential
	)
	
	# if a credential was supplied, assume a new connection is intended and create a new
	# connection using specified credential
	If ($Credential)
	{
		If ((!$Credential) -or (!$Credential.Username) -or ($Credential.Password.Length -eq 0))
		{
			WriteConsoleMessage -Message ("Invalid credential.  Please verify the credential and try again.") -MessageType "Error"
			Exit
		}
		
		# connect to provisioning web service api
		WriteConsoleMessage -Message "Connecting to the Office 365 provisioning web service API.  Please wait..." -MessageType "Information"
		Connect-MsolService -Credential $Credential
		If($? -eq $False){WriteConsoleMessage -Message "Error while connecting to the Office 365 provisioning web service API.  Quiting..." -MessageType "Error";Exit}
	}
	Else
	{
		WriteConsoleMessage -Message "Attempting to identify an open connection to the Office 365 provisioning web service API.  Please wait..." -MessageType "Information"
		$getMsolCompanyInformationResults = Get-MsolCompanyInformation -ErrorAction SilentlyContinue
		If (!$getMsolCompanyInformationResults)
		{
			WriteConsoleMessage -Message "Could not identify an open connection to the Office 365 provisioning web service API." -MessageType "Information"
			If (!$Credential)
			{
				$Credential = $Host.UI.PromptForCredential("Enter Credential",
					"Enter the username and password of an Office 365 administrator account.",
					"",
					"userCreds")
			}
			If ((!$Credential) -or (!$Credential.Username) -or ($Credential.Password.Length -eq 0))
			{
				WriteConsoleMessage -Message ("Invalid credential.  Please verify the credential and try again.") -MessageType "Error"
				Exit
			}
			
			# connect to provisioning web service api
			WriteConsoleMessage -Message "Connecting to the Office 365 provisioning web service API.  Please wait..." -MessageType "Information"
			Connect-MsolService -Credential $Credential
			If($? -eq $False){WriteConsoleMessage -Message "Error while connecting to the Office 365 provisioning web service API.  Quiting..." -MessageType "Error";Exit}
			$getMsolCompanyInformationResults = Get-MsolCompanyInformation -ErrorAction SilentlyContinue
			WriteConsoleMessage -Message ("Connected to Office 365 tenant named: `"{0}`"." -f $getMsolCompanyInformationResults.DisplayName) -MessageType "Information"
		}
		Else
		{
			WriteConsoleMessage -Message ("Connected to Office 365 tenant named: `"{0}`"." -f $getMsolCompanyInformationResults.DisplayName) -MessageType "Warning"
		}
	}
	If (!$Script:Credential) {$Script:Credential = $Credential}
}


Function ConnectExchangeOnline
{
	<#
		.SYNOPSIS
			Connects to the Exchange Online PowerShell web service (http://ps.outlook.com/powershell).

		.DESCRIPTION
			Connects to the Exchange Online PowerShell web service (http://ps.outlook.com/powershell).
			
			If a credential is specified, it will be used to establish a new remote PowerShell session connected
			to Exchange Online.  If a PowerShell session(s) exists that is connected to Exchange Online, the 
			session(s) will be removed so that a new session can be established using the specified credential.
			
			If a credential is not specified, an attempt is made to connect to Exchange Online.  If the connection
			attempt is successful, the existing connection is used.  If it is not successful, the user is prompted
			for credentials so that a new connection can be established.

		.PARAMETER Credential
			Specifies the credential to use when connecting to Exchange Online.

		.EXAMPLE
			PS> ConnectExchangeOnline

		.EXAMPLE
			PS> ConnectExchangeOnline -Credential
			
		.INPUTS
			[System.Management.Automation.PsCredential]

		.OUTPUTS
			

		.NOTES

	#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $False)]
		[System.Management.Automation.PsCredential]$Credential
	)
	
	# if a credential was supplied, assume a new connection is intended and create a new
	# connection using specified credential
	If ($Credential)
	{
		If ((!$Credential) -or (!$Credential.Username) -or ($Credential.Password.Length -eq 0))
		{
			WriteConsoleMessage -Message ("Invalid credential.  Please verify the credential and try again.") -MessageType "Error"
			Exit
		}
		
		# check if existing sessions exist that are connected to Exchange Online (http://ps.outlook.com/powershell)
		# and remove them so that a new connection can be established using specified credential
		If ((Get-PSSession | Where-Object {If (($_.configurationname -eq "microsoft.exchange") -and ($_.Runspace.ConnectionInfo.ConnectionUri.Host -like "*.outlook.com")) {Return $True}}))
		{
			WriteConsoleMessage -Message "Existing connection(s) to Exchange Online detected." -MessageType "Warning"
			WriteConsoleMessage -Message "Removing existing connection(s) to Exchange Online." -MessageType "Warning"
			Get-PSSession | Where-Object {($_.configurationname -eq "microsoft.exchange") -and ($_.Runspace.ConnectionInfo.ConnectionUri.Host -like "*.outlook.com")} | Remove-PSSession
		}
		
		# connect to Exchange Online (http://ps.outlook.com/powershell) remote powershell web service
		WriteConsoleMessage -Message "Connecting to Exchange Online.  Please wait..." -MessageType "Information"
		$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell/" -Credential $Credential -Authentication "Basic" -AllowRedirection
		Import-PSSession $session -AllowClobber
		$getOrganizationalUnitResults = Get-OrganizationalUnit
		WriteConsoleMessage -Message ("Connected to Exchange Online organization named: `"{0}`"." -f $getOrganizationalUnitResults.Identity) -MessageType "Information"
		WriteConsoleMessage -Message ("Connected to Exchange Online as: `"{0}`"." -f $session.Runspace.ConnectionInfo.Credential.UserName) -MessageType "Information"
		
	}
	Else
	{
		WriteConsoleMessage -Message "Identifying a session connected to Exchange Online whose state is `"Opened`".  Please wait..." -MessageType "Information"
		$ErrorActionPreference = "SilentlyContinue"
		$getOrganizationalUnitResults = Get-OrganizationalUnit
		$ErrorActionPreference = "Continue"
		If (!$getOrganizationalUnitResults)
		{
			WriteConsoleMessage -Message "Could not identify a session connected to Exchange Online whose state is `"Opened`"." -MessageType "Information"
			If (!$Credential)
			{
				$Credential = $Host.UI.PromptForCredential("Enter Credential",
					"Enter the username and password of an Office 365 administrator account (e.g. jdoe@contoso.com).",
					"",
					"userCreds")
			}
			If ((!$Credential) -or (!$Credential.Username) -or ($Credential.Password.Length -eq 0))
			{
				WriteConsoleMessage -Message ("Invalid credential.  Please verify the credential and try again.") -MessageType "Error"
				Exit
			}
			
			# check if existing sessions exist that are connected to Exchange Online (http://ps.outlook.com/powershell)
			# and remove them so that a new connection can be established using specified credential
			# if we are here, then it is assumed that there are no open sessions.  otherwise, we would not be here.  
			# therefore, we do not have to explicitly check the connection state to see if it is "opened"
			If ((Get-PSSession | Where-Object {If (($_.configurationname -eq "microsoft.exchange") -and ($_.Runspace.ConnectionInfo.ConnectionUri.Host -like "*.outlook.com")) {Return $True}}))
			{
				WriteConsoleMessage -Message "Identified a session(s) connected to Exchange Online whose state is not `"Opened`"." -MessageType "Warning"
				WriteConsoleMessage -Message "Removing existing session(s) connected to Exchange Online." -MessageType "Warning"
				Get-PSSession | Where-Object {($_.configurationname -eq "microsoft.exchange") -and ($_.Runspace.ConnectionInfo.ConnectionUri.Host -like "*.outlook.com")} | Remove-PSSession
			}
			
			# connect to Exchange Online (http://ps.outlook.com/powershell) remote powershell web service
			WriteConsoleMessage -Message "Connecting to Exchange Online.  Please wait..." -MessageType "Information"
			$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell/" -Credential $Credential -Authentication "Basic" -AllowRedirection
			If($? -eq $False){WriteConsoleMessage -Message "Error while connecting to Exchange Online.  Quiting..." -MessageType "Error";Exit}
			Import-PSSession $session -AllowClobber
			$getOrganizationalUnitResults = Get-OrganizationalUnit
			WriteConsoleMessage -Message ("Connected to Exchange Online organization named: `"{0}`"." -f $getOrganizationalUnitResults.Identity) -MessageType "Information"
			WriteConsoleMessage -Message ("Connected to Exchange Online as: `"{0}`"." -f $session.Runspace.ConnectionInfo.Credential.UserName) -MessageType "Information"
		}
		Else
		{
			$openSessionInfo = Get-PSSession -InstanceId ($getOrganizationalUnitResults.RunspaceId)
			WriteConsoleMessage -Message ("Connected to Exchange Online organization named: `"{0}`"." -f $getOrganizationalUnitResults.Identity) -MessageType "Warning"
			WriteConsoleMessage -Message ("Connected to Exchange Online as: `"{0}`"." -f $openSessionInfo.Runspace.ConnectionInfo.Credential.UserName) -MessageType "Warning"
		}
	}
	If (!$Script:Credential) {$Script:Credential = $Credential}
}


Function GetUpnSuffix
{
	<#
		.SYNOPSIS
			Gets the UPN suffix of an object.

		.DESCRIPTION
			Gets the UPN suffix of an object.

		.PARAMETER UserPrincipalName
			Specifies the UserPrincipalName attribute to parse from which to obtain
			the UPN suffix.

		.EXAMPLE
			PS> GetUpnSuffix -UserPrincipalName "john.doe@contoso.com"

		.INPUTS
			System.String

		.OUTPUTS
			System.String

		.NOTES

	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[String]$UserPrincipalName
	)

	$UpnSuffix = ($UserPrincipalName).SubString($UserPrincipalName.IndexOf("@")+1)
	Return $UpnSuffix
}


Function GetUser
{
	<#
		.SYNOPSIS
			Gets user information using the Exchange cmdlet "Get-User".

		.DESCRIPTION
			Gets user information using the Exchange cmdlet "Get-User".

		.PARAMETER UserPrincipalName
			Specifies the UserPrincipalName of the identity about which	to collect information.

		.EXAMPLE
			PS> GetUser -UserPrincipalName "john.doe@contoso.com"

		.INPUTS
			System.String

		.OUTPUTS
			System.Management.Automation.PSCustomObject

		.NOTES
			
	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[String]$UserPrincipalName
	)

	$objProperties = New-Object PSObject
	
	$getUserResults = Get-User -Identity $UserPrincipalName
	
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name RecipientType -Value $getUserResults.recipienttype
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name RecipientTypeDetails -Value $getUserResults.recipienttypedetails
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name WhenCreatedUTC -Value $getUserResults.whencreatedutc
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name WhenChangedUTC -Value $getUserResults.whenchangedutc
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name Company -Value $getUserResults.company
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name Department -Value $getUserResults.department
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name Manager -Value $getUserResults.manager
	
	Return $objProperties
}


Function GetRecipient
{
	<#
		.SYNOPSIS
			Gets recipient information using the Exchange cmdlet "Get-Recipient".

		.DESCRIPTION
			Gets user information using the Exchange cmdlet "Get-Recipient".

		.PARAMETER UserPrincipalName
			Specifies the UserPrincipalName of the identity about which	to collect information.

		.EXAMPLE
			PS> GetRecipient -UserPrincipalName "john.doe@contoso.com"

		.INPUTS
			System.String

		.OUTPUTS
			System.Management.Automation.PSCustomObject

		.NOTES
			
	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[String]$UserPrincipalName
	)

	$objGetRecipient = New-Object PSObject
	
	$getRecipientResults = Get-Recipient -Identity $UserPrincipalName
	
	Add-Member -InputObject $objGetRecipient -MemberType NoteProperty -Name "AuthenticationType" -Value $getRecipientResults.authenticationtype
	Add-Member -InputObject $objGetRecipient -MemberType NoteProperty -Name "PrimarySmtpAddress" -Value $getRecipientResults.emailaddresses
	Add-Member -InputObject $objGetRecipient -MemberType NoteProperty -Name "EmailAddresses" -Value $getRecipientResults.emailaddresses
	Add-Member -InputObject $objGetRecipient -MemberType NoteProperty -Name "ExternalEmailAddress" -Value $getRecipientResults.externalemailaddress
	Add-Member -InputObject $objGetRecipient -MemberType NoteProperty -Name "HiddenFromAddressListsEnabled" -Value $getRecipientResults.hiddenfromaddresslistsenabled
	
	Return $objProperties
}


Function GetMailUser
{
	<#
		.SYNOPSIS
			Gets mail-enabled user information using the Exchange cmdlet "Get-MailUser".

		.DESCRIPTION
			Gets mail-enabled user information using the Exchange cmdlet "Get-MailUser".

		.PARAMETER UserPrincipalName
			Specifies the UserPrincipalName of the identity about which	to collect information.

		.EXAMPLE
			PS> GetMailUser -UserPrincipalName "john.doe@contoso.com"

		.INPUTS
			System.String

		.OUTPUTS
			System.Management.Automation.PSCustomObject

		.NOTES
			
	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[String]$UserPrincipalName
	)

	$objPropertiess = New-Object PSObject
	
	$getMailUserResults = Get-MailUser -Identity $UserPrincipalName
	
	Add-Member -InputObject $objPropertiess -MemberType NoteProperty -Name "EmailAddresses" -Value $getMailUserResults.emailaddresses
	Add-Member -InputObject $objPropertiess -MemberType NoteProperty -Name "PrimarySmtpAddress" -Value $getMailUserResults.primarysmtpaddress
	Add-Member -InputObject $objPropertiess -MemberType NoteProperty -Name "UseMapiRichTextFormat" -Value $getMailUserResults.usemapirichtextformat
	Add-Member -InputObject $objPropertiess -MemberType NoteProperty -Name "ExternalEmailAddress" -Value $getMailUserResults.externalemailaddress
	Add-Member -InputObject $objPropertiess -MemberType NoteProperty -Name "HiddenFromAddressListsEnabled" -Value $getMailUserResults.hiddenfromaddresslistsenabled
	
	Return $objPropertiess
}


Function GetMailbox
{
	<#
		.SYNOPSIS
			Gets mailbox-enabled user information using the Exchange cmdlet "Get-Mailbox".

		.DESCRIPTION
			Gets mailbox-enabled user information using the Exchange cmdlet "Get-Mailbox".

		.PARAMETER UserPrincipalName
			Specifies the UserPrincipalName of the identity about which	to collect information.

		.EXAMPLE
			PS> GetMailbox -UserPrincipalName "john.doe@contoso.com"

		.INPUTS
			System.String

		.OUTPUTS
			System.Management.Automation.PSCustomObject

		.NOTES
			
	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[String]$UserPrincipalName
	)

	$objProperties = New-Object PSObject
	
	$getMailboxResults = Get-Mailbox -Identity $UserPrincipalName
	
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "EmailAddresses" -Value $getMailboxResults.emailaddresses
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "HiddenFromAddressListsEnabled" -Value $getMailboxResults.hiddenfromaddresslistsenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MaxSendSize" -Value $getMailboxResults.maxsendsize
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MaxReceiveSize" -Value $getMailboxResults.maxreceivesize
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "RetentionPolicy" -Value $getMailboxResults.retentionpolicy
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "RetentionHoldEnabled" -Value $getMailboxResults.retentionholdenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "StartDateForRetentionHold" -Value $getMailboxResults.startdateforretentionhold
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "EndDateForRetentionHold" -Value $getMailboxResults.enddateforretentionhold
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "RetainDeletedItemsFor" -Value $getMailboxResults.retaindeleteditemsfor
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "SingleItemRecoveryEnabled" -Value $getMailboxResults.singleitemrecoveryenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "LitigationHoldEnabled" -Value $getMailboxResults.litigationholdenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "LitigationHoldDate" -Value $getMailboxResults.litigationholddate
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "ManagedFolderMailboxPolicy" -Value $getMailboxResults.managedfoldermailboxpolicy
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "DeliverToMailboxAndForward" -Value $getMailboxResults.delivertomailboxandforward
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "ForwardingAddress" -Value $getMailboxResults.forwardingAddress
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "ForwardingSmtpAddress" -Value $getMailboxResults.forwardingSmtpAddress

	Return $objProperties
}


Function GetCASMailbox
{
	<#
		.SYNOPSIS
			Gets mailbox-enabled user information using the Exchange cmdlet "Get-CASMailbox".

		.DESCRIPTION
			Gets mailbox-enabled user information using the Exchange cmdlet "Get-CASMailbox".

		.PARAMETER UserPrincipalName
			Specifies the UserPrincipalName of the identity about which	to collect information.

		.EXAMPLE
			PS> GetCASMailbox -UserPrincipalName "john.doe@contoso.com"

		.INPUTS
			System.String

		.OUTPUTS
			System.Management.Automation.PSCustomObject

		.NOTES
			
	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[String]$UserPrincipalName
	)

	$objProperties = New-Object PSObject
	
	$getCASMailboxResults = Get-CASMailbox -Identity $UserPrincipalName
	
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name ActiveSyncEnabled -Value $getCASMailboxResults.activesyncenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name OWAEnabled -Value $getCASMailboxResults.owaenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name POPEnabled -Value $getCASMailboxResults.popenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name IMAPEnabled -Value $getCASMailboxResults.imapenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name MAPIEnabled -Value $getCASMailboxResults.mapienabled

	Return $objProperties
}


Function GetMailboxStatistics
{
	<#
		.SYNOPSIS
			Gets mailbox-enabled user information using the Exchange cmdlet "Get-MailboxStatistics".

		.DESCRIPTION
			Gets mailbox-enabled user information using the Exchange cmdlet "Get-MailboxStatistics".

		.PARAMETER UserPrincipalName
			Specifies the UserPrincipalName of the identity about which	to collect information.

		.EXAMPLE
			PS> GetMailboxStatistics -UserPrincipalName "john.doe@contoso.com"

		.INPUTS
			System.String

		.OUTPUTS
			System.Management.Automation.PSCustomObject

		.NOTES
			
	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[String]$UserPrincipalName
	)

	$objProperties = New-Object PSObject
	
	$getMailboxStatisticsResults = Get-MailboxStatistics -Identity $UserPrincipalName
	
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name TotalItemSize -Value $getMailboxStatisticsResults.totalitemsize.value
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name ItemCount -Value $getMailboxStatisticsResults.itemcount
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name TotalDeletedItemSize -Value $getMailboxStatisticsResults.totaldeleteditemsize.value
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name DeletedItemCount -Value $getMailboxStatisticsResults.deleteditemcount

	Return $objProperties
}


Function GetPrimarySmtpAddress
{
	<#
		.SYNOPSIS
			Gets the primary SMTP address of an object.

		.DESCRIPTION
			Gets the primary SMTP address of an object.

		.PARAMETER ProxyAddresses
			Specifies the proxyAddresses attribute to parse in order to determine
			the primary SMTP address.

		.EXAMPLE
			PS> GetPrimarySmtpAddress -ProxyAddresses $ProxyAddresses

		.INPUTS
			System.String[]

		.OUTPUTS
			System.String

		.NOTES

	#>

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$ProxyAddresses
	)

	foreach ($proxyAddress In $ProxyAddresses) {
		If ([string]::Compare([string]$proxyAddress.substring(0,5),"SMTP:",$False) -eq 0)
		{
			$Result = $([string]$proxyAddress.substring(5))
		}
	}
	Return $Result
}


Function GetSecondarySMTPAddresses
{
	<#
		.SYNOPSIS
			Gets the secondary SMTP addresses of an object.

		.DESCRIPTION
			Gets the secondary SMTP addresses of an object.

		.PARAMETER ProxyAddresses
			Specifies the proxyAddresses attribute to parse in order to determine
			the secondary SMTP addresses.

		.EXAMPLE
			PS> GetSecondarySMTPAddresses -ProxyAddresses $ProxyAddresses

		.INPUTS
			System.String[]

		.OUTPUTS
			System.String

		.NOTES

	#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$ProxyAddresses
	)

	foreach($proxyAddress In $ProxyAddresses) {
		If (([string]::Compare([string]$proxyAddress.substring(0,5),"smtp:",$False) -eq 0))
		{
			$Result += "{0};" -f $([string]$proxyAddress.substring(5))
		}
	}
	If ($Result) {$Result = "{0}" -f $Result.substring(0,$Result.length - 1)}

	Return $Result
}


Function GetActiveSyncDeviceStatistics
{
	<#
		.SYNOPSIS
			Calls the cmdlet named Get-ActivceSyncDeviceStatistics for the
			identified by the primary smtp address and returns the collection
			of properties.

		.DESCRIPTION
			Calls the cmdlet named Get-ActivceSyncDeviceStatistics for the
			identified by the primary smtp address and returns the collection
			of properties.

		.PARAMETER PrimarySmtpAddress
			Specifies the primary smtp address of the mailbox from which to
			collect activesync device statistics.

		.EXAMPLE
			PS> GetActiveSyncDeviceStatistics -PrimarySmtpAddress $primarySmtpAddress

		.INPUTS
			System.String

		.OUTPUTS
			

		.NOTES

	#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		[String]$PrimarySmtpAddress
	)

	$activeSyncDeviceStatistics = Get-ActiveSyncDeviceStatistics -Mailbox $PrimarySmtpAddress

	Return $activeSyncDeviceStatistics
}


Function GetActiveSyncDeviceStatisticsResultsProperty
{
	<#
		.SYNOPSIS
			Returns the value of a property in the activesync device
			statistics result object.

		.DESCRIPTION
			Returns the value of a property in the activesync device
			statistics result object.

		.PARAMETER ActiveSyncDeviceStatisticsResults
			Specifies an object representing the results returned by
			the cmdlet named Get-ActiveSyncDeviceStatistics.

		.PARAMETER PropertyToReturn
			Specifies the property name whose value should be returned.

		.EXAMPLE
			PS> GetActiveSyncDeviceStatisticsResultsProperty -ActiveSyncDeviceStatisticsResults $DeviceResults -PropertyToReturn "deviceid"

		.INPUTS
			System.Array

		.OUTPUTS
			System.String

		.NOTES

	#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$ActiveSyncDeviceStatisticsResults,
		
		[Parameter(Mandatory = $True)]
		[String]$PropertyToReturn
	)
	
	If ($ActiveSyncDeviceStatisticsResults.length -gt 1)
	{
		$count = 1
		$ActiveSyncDeviceStatisticsResults | ForEach-Object{
			$Result += "{0}{1}: {2}{3}" -f "{DEVICE", $count, $_.psobject.properties.item($PropertyToReturn).value, "}"
			$count++
		}
	}
	Else
	{
		$ActiveSyncDeviceStatisticsResults | ForEach-Object{
			$Result += "{0}{1}{2}" -f "{", $_.psobject.properties.item($PropertyToReturn).value, "}"
		}
	}
	
	Return $Result
}


Function GetAssignedLicenses
{
	<#
		.SYNOPSIS
			Returns the value of a property in the activesync device
			statistics result object.

		.DESCRIPTION
			Returns the value of a property in the activesync device
			statistics result object.

		.PARAMETER Licenses
			Specifies a licensing object representing the results returned by
			the cmdlet named Get-MsolUser.

		.EXAMPLE
			PS> GetAssignedLicenses -Licenses $licenses

		.INPUTS
			

		.OUTPUTS
			

		.NOTES

	#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $True)]
		$Licenses
	)

	$Licenses | ForEach-Object{
		$Result += "{0}{1}{2}" -f "{", $_.accountskuid, "}"
	}
	
	Return $Result
}


# -----------------------------------------------------------------------------
#
# Main Script Execution
#
# -----------------------------------------------------------------------------

$Error.Clear()
$ScriptStartTime = Get-Date

# verify that the MSOnline module is installed and import into current powershell session
If (!([System.IO.File]::Exists(("{0}\modules\msonline\Microsoft.Online.Administration.Automation.PSModule.dll" -f $pshome))))
{
	WriteConsoleMessage -Message ("Please download and install the Microsoft Online Services Module.") -MessageType "Error"
	Exit
}
$getModuleResults = Get-Module
If (!$getModuleResults) {Import-Module MSOnline -ErrorAction SilentlyContinue}
Else {$getModuleResults | ForEach-Object {If (!($_.Name -eq "MSOnline")){Import-Module MSOnline -ErrorAction SilentlyContinue}}}

# verify output directory exists for results file
WriteConsoleMessage -Message ("Verifying folder:  {0}" -f $OutputFile) -MessageType "Verbose"
If (!(TestFolderExists $OutputFile))
{
	WriteConsoleMessage -Message ("Directory not found:  {0}" -f $OutputFile) -MessageType "Error"
	Exit
}

# if a filename was not specified as part of $OutputFile, auto generate a name
# in the format of YYYYMMDDhhmmss.csv and append to the directory path
If (!([System.IO.Path]::HasExtension($OutputFile)))
{
	If ($OutputFile.substring($OutputFile.length - 1) -eq "\")
	{
		$OutputFile += "{0}.csv" -f (Get-Date -uformat %Y%m%d%H%M%S).ToString()
	}
	Else
	{
		$OutputFile += "\{0}.csv" -f (Get-Date -uformat %Y%m%d%H%M%S).ToString()
	}
}

ConnectProvisioningWebServiceAPI -Credential $Credential
ConnectExchangeOnline -Credential $Credential

# get all users from MSOnline
WriteConsoleMessage -Message "Creating collection of all users from Office 365.  Please wait..." -MessageType "Information"
$colUsers = Get-MsolUser -All

# iterate through each user in the collection, and retrieve additional information about each user
WriteConsoleMessage -Message "Processing collection of users.  Please wait..." -MessageType "Information"
$arrMsolUserData = @()
$count = 1
foreach ($user In $colUsers) {
	$upn = $user.UserPrincipalName
	$ActivityMessage = "Retrieving data. Please wait..."
	$StatusMessage = ("Processing {0} of {1}: {2}" -f $count, @($colUsers).count, $upn)
	$PercentComplete = ($count / @($colUsers).count * 100)
	Write-Progress -Activity $ActivityMessage -Status $StatusMessage -PercentComplete $PercentComplete
	
	WriteConsoleMessage -Message ("Processing: {0}" -f $upn) -MessageType "Verbose"
	
	$objProperties = New-Object PSObject
	
	WriteConsoleMessage -Message ("Calling Get-User for:  {0}" -f $upn) -MessageType "Verbose"
	$getUserResults = GetUser $upn
	Switch ($getUserResults.RecipientType)
	{
		"UserMailbox"
		{
			WriteConsoleMessage -Message ("Calling GetMailbox for:  {0}" -f $upn) -MessageType "Verbose"
			$getMailboxResults = GetMailbox $upn
			
			WriteConsoleMessage -Message ("Calling GetCASMailbox for:  {0}" -f $upn) -MessageType "Verbose"
			$getCASMailboxResults = GetCASMailbox $upn
			
			WriteConsoleMessage -Message ("Getting primary SMTP address for:  {0}" -f $upn) -MessageType "Verbose"
			$primarySmtpAddress = GetPrimarySmtpAddress $getMailboxResults.EmailAddresses
			
			WriteConsoleMessage -Message ("Getting secondary smtp addresses for:  {0}" -f $upn) -MessageType "Verbose"
			$secondarySmtpAddresses = GetSecondarySmtpAddresses $getMailboxResults.EmailAddresses
			
			WriteConsoleMessage -Message ("Calling GetMailboxStatistics for:  {0}" -f $upn) -MessageType "Verbose"
			$getMailboxStatisticsResults = GetMailboxStatistics $upn
			
			WriteConsoleMessage -Message ("Calling GetActiveSyncDeviceStatistics for:  {0}" -f $upn) -MessageType "Verbose"
			$getActiveSyncDeviceStatisticsResults = GetActiveSyncDeviceStatistics $primarySmtpAddress
		}
		"MailUser"
		{
			WriteConsoleMessage -Message ("Calling Get-MailUser for:  {0}" -f $upn) -MessageType "Verbose"
			$getMailUserResults = GetMailUser $upn
			
			WriteConsoleMessage -Message ("Getting primary SMTP address for:  {0}" -f $upn) -MessageType "Verbose"
			$primarySmtpAddress = GetPrimarySmtpAddress $getMailUserResults.EmailAddresses
			
			WriteConsoleMessage -Message ("Getting secondary smtp addresses for:  {0}" -f $upn) -MessageType "Verbose"
			$secondarySmtpAddresses = GetSecondarySmtpAddresses $getMailUserResults.EmailAddresses
		}
		"User"
		{
			# do nothing as user results were previously collected via the GetUser function
		}
	}
	
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "UserPrincipalName" -Value $upn
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "UpnSuffix" -Value $(GetUpnSuffix -UserPrincipalName $upn)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "RecipientType" -Value $getUserResults.RecipientType
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "PrimarySmtpAddress" -Value $primarySmtpAddress
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "AdditionalSmtpAddresses" -Value $secondarySmtpAddresses
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "DisplayName" -Value $($user.displayname)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "FirstName" -Value $($user.firstname)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "LastName" -Value $($user.lastname)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "IsLicensed" -Value $($user.islicensed)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "LicenseReconciliationNeeded" -Value $($user.licensereconciliationneeded)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "AssignedLicenses" -Value $(If ($user.islicensed -eq $True) {GetAssignedLicenses $user.licenses})
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "BlockCredential(IsLogonDisabled)" -Value $($user.blockcredential)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "WhenCreatedUTC" -Value $getUserResults.whencreatedutc
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "WhenChangedUTC" -Value $getUserResults.whenchangedutc
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "LastDirSyncTime" -Value $($user.lastdirsynctime)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "UsageLocation" -Value $($user.usagelocation)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "Company" -Value $getUserResults.company
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "Department" -Value $getUserResults.department
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "Manager" -Value $getUserResults.manager
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "Title" -Value $($user.title)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "StreetAddress" -Value $($user.streetaddress)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "City" -Value $($user.city)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "State" -Value $($user.state)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "ZipCode" -Value $($user.postalcode)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "Office" -Value $($user.office)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "TelephoneNumber" -Value $($user.phonenumber)
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "ItemCount" -Value $getMailboxStatisticsResults.itemcount
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "TotalItemSize" -Value $getMailboxStatisticsResults.totalitemsize
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "DeletedItemCount" -Value $getMailboxStatisticsResults.deleteditemcount
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "TotalDeletedItemSize" -Value $getMailboxStatisticsResults.totaldeleteditemsize
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MaxSendSize" -Value $getMailboxResults.maxsendsize
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MaxReceiveSize" -Value $getMailboxResults.maxreceivesize
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "DeliverToMailboxAndForward" -Value $getMailboxResults.deliverToMailboxAndForward
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "ForwardingAddress" -Value $getMailboxResults.forwardingaddress
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "ForwardingSmtpAddress" -Value $getMailboxResults.forwardingsmtpaddress
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "ExternalEmailAddress" -Value $getMailUserResults.externalemailaddress
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "HiddenFromAddressListsEnabled" -Value $getMailboxResults.hiddenfromaddresslistsenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "RetentionPolicy" -Value $getMailboxResults.retentionpolicy
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "RetentionHoldEnabled" -Value $getMailboxResults.retentionholdenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "StartDateForRetentionHold" -Value $getMailboxResults.startdateforretentionhold
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "EndDateForRetentionHold" -Value $getMailboxResults.enddateforretentionhold
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "RetainDeletedItemsFor" -Value $getMailboxResults.retaindeleteditemsfor
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "SingleItemRecoveryEnabled" -Value $getMailboxResults.singleitemrecoveryenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "LitigationHoldEnabled" -Value $getMailboxResults.litigationholdenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "LitigationHoldDate" -Value $getMailboxResults.litigationholddate
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "ManagedFolderMailboxPolicy" -Value $getMailboxResults.managedfoldermailboxpolicy
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "ActiveSyncEnabled" -Value $getCASMailboxResults.activesyncenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "OWAEnabled" -Value $getCASMailboxResults.owaenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "POPEnabled" -Value $getCASMailboxResults.popenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "IMAPEnabled" -Value $getCASMailboxResults.imapenabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MAPIEnabled" -Value $getCASMailboxResults.mapienabled
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MobileDeviceFriendlyName" -Value $(If ($getActiveSyncDeviceStatisticsResults -ne $Null) {GetActiveSyncDeviceStatisticsResultsProperty $getActiveSyncDeviceStatisticsResults "devicefriendlyname"})
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MobileDeviceID" -Value $(If ($getActiveSyncDeviceStatisticsResults -ne $Null) {GetActiveSyncDeviceStatisticsResultsProperty $getActiveSyncDeviceStatisticsResults "deviceid"})
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MobileDeviceModel" -Value $(If ($getActiveSyncDeviceStatisticsResults -ne $Null) {GetActiveSyncDeviceStatisticsResultsProperty $getActiveSyncDeviceStatisticsResults "devicemodel"})
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MobileDeviceOS" -Value $(If ($getActiveSyncDeviceStatisticsResults -ne $Null) {GetActiveSyncDeviceStatisticsResultsProperty $getActiveSyncDeviceStatisticsResults "deviceos"})
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MobileDeviceOSLanguage" -Value $(If ($getActiveSyncDeviceStatisticsResults -ne $Null) {GetActiveSyncDeviceStatisticsResultsProperty $getActiveSyncDeviceStatisticsResults "deviceoslanguage"})
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MobileDeviceLastSuccessSync" -Value $(If ($getActiveSyncDeviceStatisticsResults -ne $Null) {GetActiveSyncDeviceStatisticsResultsProperty $getActiveSyncDeviceStatisticsResults "lastsuccesssync"})
	Add-Member -InputObject $objProperties -MemberType NoteProperty -Name "MobileDevicePolicyApplied" -Value $(If ($getActiveSyncDeviceStatisticsResults -ne $Null) {GetActiveSyncDeviceStatisticsResultsProperty $getActiveSyncDeviceStatisticsResults "devicepolicyapplied"})

	$arrMsolUserData += $objProperties
	$count++
	
	If ($getMailboxResults -ne $Null) {Clear-Variable -Name getMailboxResults}	
	If ($getCASMailboxResults -ne $Null) {Clear-Variable -Name getMailboxResults}
	If ($primarySmtpAddress -ne $Null) {Clear-Variable -Name primarySmtpAddress}
	If ($secondarySmtpAddresses -ne $Null) {Clear-Variable -Name secondarySmtpAddresses}
	If ($getMailboxStatisticsResults -ne $Null) {Clear-Variable -Name getMailboxStatisticsResults}
	If ($getActiveSyncDeviceStatisticsResults -ne $Null) {Clear-Variable -Name getActiveSyncDeviceStatisticsResults}
	If ($getMailUserResults -ne $Null) {Clear-Variable -Name getMailUserResults}
}

If ($OutputFile) {
	WriteConsoleMessage -Message "Saving results to outputfile.  Please wait..." -MessageType "Information"
	$arrMsolUserData | Export-Csv -Path $OutputFile -NoTypeInformation
}

# script is complete
$ScriptStopTime = Get-Date
$elapsedTime = GetElapsedTime -Start $ScriptStartTime -End $ScriptStopTime
WriteConsoleMessage -Message ("Script Start Time  :  {0}" -f ($ScriptStartTime)) -MessageType "Information"
WriteConsoleMessage -Message ("Script Stop Time   :  {0}" -f ($ScriptStopTime)) -MessageType "Information"
WriteConsoleMessage -Message ("Elapsed Time       :  {0:N0}.{1:N0}:{2:N0}:{3:N1}  (Days.Hours:Minutes:Seconds)" -f $elapsedTime.Days, $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds) -MessageType "Information"
WriteConsoleMessage -Message ("Output File        :  {0}" -f $OutputFile) -MessageType "Information"

# -----------------------------------------------------------------------------
#
# End of Script.
#
# -----------------------------------------------------------------------------