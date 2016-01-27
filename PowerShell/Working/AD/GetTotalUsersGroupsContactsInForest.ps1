## Active Directory: PowerShell Script to Search Domains in a Forest to Calculate the Users, Groups, and Contacts (with CSV Output) ##

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
#    GetTotalUsersGroupsContactsInForest.ps1
#
# AUTHOR(s):
#    Thomas Ashworth - http://blogs.technet.com/b/thomas_ashworth
#
#------------------------------------------------------------------------------

<#
	.SYNOPSIS
		Search Active Directory and calculate the total number of users, groups,
		and contacts for each domain in the forest.

	.DESCRIPTION
		Search Active Directory and calculate the total number of users, groups,
		and contacts for each domain in the forest. Object type totals are written
		to the PowerShell console and saved to a CSV file.

	.PARAMETER ForestName
		Specifies the DNS name of the Active Directory forest.  If a forest name
		is not specified, the current user context of the PowerShell session is
		used.

	.PARAMETER OutputFile
		Specifies the path and filename of the output file.  The arguement can be
		the full path including the file name, or only the path to the folder in
		which to save the file.  If a file name is not specified as part of the
		path (or, if not specified at all), then the script will auto generate a
		file name using a default value of year, month, day, hours, minutes, and
		seconds.
		
		Default value:  YYYYMMDDhhmmss_TotalUsersGroupsContacts.csv
	
	.PARAMETER Credential
		Specifies the username and password required to perform the operation.
		
	.EXAMPLE
		PS> .\Get-TotalUsersGroupsContactsInForest.ps1

	.EXAMPLE
		PS> .\Get-TotalUsersGroupsContactsInForest.ps1 -OutputFile "C:\Folder\Sub Folder\File name.csv"

	.EXAMPLE
		PS> .\Get-TotalUsersGroupsContactsInForest.ps1 -ForestName "example.contoso.com" -Credential (Get-Credential) -OutputFile "C:\Folder\Sub Folder\File name.csv"

	.INPUTS
		System.Management.Automation.PsCredential

	.OUTPUTS
		None

	.NOTES

		
#>

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $False)]
	[ValidateNotNullOrEmpty()]
	[String]$ForestName,
	
	[Parameter(Mandatory = $False)]
	[ValidateNotNullOrEmpty()]
	[String]$OutputFile = "$((Get-Date -uformat %Y%m%d%H%M%S).ToString())_TotalUsersGroupsContacts.csv",
	
	[Parameter(Mandatory = $False)]
	[ValidateNotNullOrEmpty()]
	[System.Management.Automation.PsCredential]$Credential = $Host.UI.PromptForCredential("Enter Credential",
		"Enter the username and password of an account with at least read access to each domain in the forest.",
		"",
		"userCreds")
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
		background and foreground colors so that the message is easily identified
		within the console at a glance.

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
		System.String

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
		[ValidateNotNullOrEmpty()]
		[DateTime]$Start,
		
		[Parameter(Mandatory = $True, Position = 1)]
		[ValidateNotNullOrEmpty()]
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


Function GetADForest
{
	<#
		.SYNOPSIS
			Returns an object representing an Active Directory forest.

		.DESCRIPTION
			Returns an object representing an Active Directory forest.  If 
			a forest name is not specified, the current	user context is used.

		.PARAMETER ForestName
			Specifies the DNS name of the Active Directory forest.

		.PARAMETER Credential
			Specifies the username and password required to perform the operation.

		.EXAMPLE
			PS> GetADForest

		.EXAMPLE
			PS> GetADForest -ForestName "example.contoso.com"

		.EXAMPLE
			PS> GetADForest -Credential $cred

		.EXAMPLE
			PS> GetADForest -ForestName "example.contoso.com" -Credential $cred

		.INPUTS
			System.String
			System.Management.Automation.PsCredential
	
		.OUTPUTS
			System.DirectoryService.ActiveDirectory.Forest

		.NOTES

	#>
	
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $False, Position = 0)]
		[string]$ForestName,
		
		[Parameter(Mandatory = $False)]
		[System.Management.Automation.PsCredential]$Credential
	)
	
	If (!$ForestName) {$ForestName = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Name.ToString()}
	If ($Credential) {$directoryContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ForestName, $Credential.UserName.ToString(), $Credential.GetNetworkCredential().Password.ToString())}
	Else {$directoryContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ForestName)}
	$objForest = ([System.DirectoryServices.ActiveDirectory.Forest]::GetForest($directoryContext))
	Return $objForest
}


Function GetADDomain
{
	<#
		.SYNOPSIS
			Returns an object representing an Active Directory domain.  If 
			a domain name is not specified, the current	user context is used.

		.DESCRIPTION
			Returns an object representing an Active Directory domain.  If 
			a domain name is not specified, the current	user context is used.

		.PARAMETER DomainName
			Specifies the DNS name of the Active Directory domain.

		.PARAMETER Credential
			Specifies the username and password required to perform the operation.

		.EXAMPLE
			PS> GetADDomain
		
		.EXAMPLE
			PS> GetADDomain -DomainName "example.contoso.com"

		.EXAMPLE
			PS> GetADDomain -Credential $cred

		.EXAMPLE
			PS> GetADDomain -DomainName "example.contoso.com" -Credential $cred

		.INPUTS
			System.String
			System.Management.Automation.PsCredential
	
		.OUTPUTS
			System.DirectoryService.ActiveDirectory.Domain

		.NOTES

	#>
	
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $False)]
		[string]$DomainName,
		
		[Parameter(Mandatory = $False)]
		[System.Management.Automation.PsCredential]$Credential
	)
	
	If (!$DomainName) {$DomainName = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name.ToString()}
	If ($Credential) {$directoryContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain", $DomainName, $Credential.UserName.ToString(), $Credential.GetNetworkCredential().Password.ToString())}
	Else {$directoryContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain", $DomainName)}
	$objDomain = ([System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($directoryContext))
	
	Return $objDomain
}


Function GetADObject
{
	<#
		.SYNOPSIS
			Returns an object that represents an Active Directory object.

		.DESCRIPTION
			Returns an object that represents an Active Directory object.

		.PARAMETER DomainController
			Specifies the DNS name of the Active Directory domain controller to
			query for the search.

		.PARAMETER SearchRoot
			Specifies the distinguished name of the directory service location
			from which the search will begin.

		.PARAMETER SearchScope
			Specifies the scope for a directory search.
			
			Default value: subtree.

			base      :   Limits the search to only the base object.
			onelevel  :   Search is restricted to the immediate children
			              of a base object, but excludes the base object itself.
			subtree   :   Includes all of the objects beneath the base
			              object, excluding the base object itself.

		.PARAMETER Filter
			Specifies an LDAP filter to use for the search.
			Example: (&(objectcategory=person)(objectclass=user)(proxyaddresses=smtp:*))

		.PARAMETER PropertiesToLoad
			Specifies a collection of Active Directory properties to retrieve
			about the object. Separate multiple values with commas.

		.PARAMETER Credential
			Specifies the username and password required to perform the operation.

		.EXAMPLE
			PS> GetADObject -DomainController "servername.example.contoso.com" -SearchRoot "ou=organizational unit,dc=example,dc=contoso,dc=com" -SearchScope "subtree" -Filter "(&(objectcategory=person)(objectclass=user))" -PropertiesToLoad "cn, distinguishedname, userprincipalname" -Credential (Get-Credential)

		.INPUTS
			System.String
			System.Management.Automation.PsCredential
	
		.OUTPUTS
			System.DirectoryServices.DirectorySearcher

		.NOTES

	#>
	

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $False, Position = 0, ParameterSetName = "DomainController")]
		[string]$DomainController,
		
		[Parameter(Mandatory = $False)]
		[string]$SearchRoot,
		
		[Parameter(Mandatory = $False)]
		[string]$SearchScope,
		
		[Parameter(Mandatory = $False)]
		[string]$Filter,
		
		[Parameter(Mandatory = $False)]
		$PropertiesToLoad,
		
		[Parameter(Mandatory = $False)]
		[System.Management.Automation.PsCredential]$Credential
	)

	$DirectoryEntryUserName = [string]$Credential.UserName
    $DirectoryEntryPassword = [string]$Credential.GetNetworkCredential().Password
	$AuthenticationType = [System.DirectoryServices.AuthenticationTypes]::Signing -bor [System.DirectoryServices.AuthenticationTypes]::Sealing -bor [System.DirectoryServices.AuthenticationTypes]::Secure
    
	$SearchRoot = "LDAP://{0}/{1}" -f ($DomainController, $SearchRoot)

	$objDirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry($SearchRoot, `
		$DirectoryEntryUserName, `
		$DirectoryEntryPassword, `
		$AuthenticationType)

	$objDirectorySearcher = New-Object System.DirectoryServices.DirectorySearcher
	$objDirectorySearcher.SearchRoot = $objDirectoryEntry
	$objDirectorySearcher.SearchScope = $SearchScope
	$objDirectorySearcher.PageSize = 1000
	$objDirectorySearcher.ReferralChasing = "All"
	$objDirectorySearcher.CacheResults = $False
	$colPropertiesToLoad | ForEach-Object -Process {[Void]$objDirectorySearcher.PropertiesToLoad.Add($_)}
	$objDirectorySearcher.Filter = $Filter
	$colADObject = $objDirectorySearcher.FindAll()
    
    Return $colADObject
}


#-------------------------------------------------------------------------------
#
# Main Script Execution
#
#-------------------------------------------------------------------------------

$ScriptStartTime = Get-Date

# verify output directory exists for results file
WriteConsoleMessage -Message ("Verifying directory path to output file:  {0}" -f $OutputFile) -MessageType "Verbose"
If (!(TestFolderExists $OutputFile))
{
	WriteConsoleMessage -Message ("Directory not found:  {0}" -f $OutputFile) -MessageType "Error"
	Exit
}

# if only a path was specified (i.e. file name not included at the end of the
# directory path), then auto generate a file name in the format of YYYYMMDDhhmmss.csv
# and append to the directory path
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

# search active directory
WriteConsoleMessage -Message "Identifying all domains in forest.  Please wait..." -MessageType "Information"
If ($ForestName)
{
	If ($Credential) {$objForest = GetADForest -ForestName $ForestName -Credential $Credential}
	Else {$objForest = GetADForest -ForestName $ForestName}
}
Else 
{
	If ($Credential) {$objForest = GetADForest -Credential $Credential}
	Else {$objForest = GetADForest}
}

WriteConsoleMessage -Message "Searching for users, groups, and contacts (in this order) within each identified domain.  Please wait..." -MessageType "Information"
$arrADObjectCounts = @()
$count = 1
foreach($domain in $objForest.domains){
	$GetDsgDomain = GetADDomain -DomainName $domain -Credential $Credential
	$DomainName =  $GetDsgDomain.Name
	$DomainController = $GetDsgDomain.FindDomainController().name
	$SearchRoot = $GetDsgDomain.GetDirectoryEntry().distinguishedname
	$SearchScope = "subtree"
	$colPropertiesToLoad = "cn"
	
	$ActivityMessage = "Searching through each domain...  Please wait..."
	$StatusMessage = ("Searching domain: {0}" -f $DomainName)
	$PercentComplete = ($count / @($objForest.domains).count * 100)
	Write-Progress -Activity $ActivityMessage -Status $StatusMessage -PercentComplete $PercentComplete
	
	$objADObjectCounts = New-Object PSObject

	$StatusMessage = ("Searching for all user objects in: {0}" -f $DomainName)
	Write-Progress -Activity $ActivityMessage -Status $StatusMessage -PercentComplete $PercentComplete
	WriteConsoleMessage -Message ("Searching for all user objects in: {0}" -f $DomainName) -MessageType "Verbose"
	$Filter = "(&(objectCategory=Person)(objectClass=User))"
	$colADObject = GetADObject -DomainController $DomainController -SearchRoot $SearchRoot -SearchScope $SearchScope -Filter $Filter -PropertiesToLoad $colPropertiesToLoad -Credential $Credential
	$userCount = @($colADObject).count
	
	$StatusMessage = ("Searching for all group objects in: {0}" -f $DomainName)
	Write-Progress -Activity $ActivityMessage -Status $StatusMessage -PercentComplete $PercentComplete
	WriteConsoleMessage -Message ("Searching for all group objects in: {0}" -f $DomainName) -MessageType "Verbose"
	$Filter = "(&(objectCategory=Group)(objectClass=Group))"
	$colADObject = GetADObject -DomainController $DomainController -SearchRoot $SearchRoot -SearchScope $SearchScope -Filter $Filter -PropertiesToLoad $colPropertiesToLoad -Credential $Credential
	$groupCount = @($colADObject).count
	
	$StatusMessage = ("Searching for all contact objects in: {0}" -f $DomainName)
	Write-Progress -Activity $ActivityMessage -Status $StatusMessage -PercentComplete $PercentComplete
	WriteConsoleMessage -Message ("Searching for all contact objects in: {0}" -f $DomainName) -MessageType "Verbose"
	$Filter = "(&(objectCategory=Person)(objectClass=Contact))"
	$colADObject = GetADObject -DomainController $DomainController -SearchRoot $SearchRoot -SearchScope $SearchScope -Filter $Filter -PropertiesToLoad $colPropertiesToLoad -Credential $Credential
	$contactCount = @($colADObject).count

	Add-Member -InputObject $objADObjectCounts -MemberType NoteProperty -Name DomainName -Value $DomainName
	Add-Member -InputObject $objADObjectCounts -MemberType NoteProperty -Name DomainController -Value $DomainController
	Add-Member -InputObject $objADObjectCounts -MemberType NoteProperty -Name UserObjects -Value $userCount
	Add-Member -InputObject $objADObjectCounts -MemberType NoteProperty -Name GroupObjects -Value $groupCount
	Add-Member -InputObject $objADObjectCounts -MemberType NoteProperty -Name ContactObjects -Value $contactCount
	Add-Member -InputObject $objADObjectCounts -MemberType NoteProperty -Name DomainTotal -Value $($userCount + $groupCount + $contactCount)
	
	$arrADObjectCounts += $objADObjectCounts
	$count++
}

WriteConsoleMessage -Message ("Calculating total objects in forest: {0}" -f $objForest.RootDomain.Name) -MessageType "Verbose"
$objTotalObjects = New-Object PSObject
foreach($element in $arrADObjectCounts)
{
	Add-Member -InputObject $objTotalObjects -MemberType NoteProperty -Name TotalUsers -Value $($element | foreach{$TotalUsers += $element.userobjects};$TotalUsers) -Force
	Add-Member -InputObject $objTotalObjects -MemberType NoteProperty -Name TotalGroups -Value $($element | foreach{$TotalGroups += $element.groupobjects};$TotalGroups) -Force
	Add-Member -InputObject $objTotalObjects -MemberType NoteProperty -Name TotalContacts -Value $($element | foreach{$TotalContacts += $element.contactobjects};$TotalContacts) -Force
	Add-Member -InputObject $objTotalObjects -MemberType NoteProperty -Name TotalObjects -Value $($element | foreach{$TotalObjects += $element.domaintotal};$TotalObjects) -Force
}

If ($OutputFile) 
{
	WriteConsoleMessage -Message "Saving per domain results to CSV file.  Please wait..." -MessageType "Information"
	$arrADObjectCounts | Export-Csv -Path $OutputFile -NoTypeInformation
}

# script is complete
$ScriptStopTime = Get-Date
$elapsedTime = GetElapsedTime -Start $ScriptStartTime -End $ScriptStopTime
WriteConsoleMessage -Message ("Script Start Time  :  {0}" -f ($ScriptStartTime)) -MessageType "Information"
WriteConsoleMessage -Message ("Script Stop Time   :  {0}" -f ($ScriptStopTime)) -MessageType "Information"
WriteConsoleMessage -Message ("Elapsed Time       :  {0:N0}.{1:N0}:{2:N0}:{3:N1}  (Days.Hours:Minutes:Seconds)" -f $elapsedTime.Days, $elapsedTime.Hours, $elapsedTime.Minutes, $elapsedTime.Seconds) -MessageType "Information"
WriteConsoleMessage -Message ("Output File        :  {0}" -f $OutputFile) -MessageType "Information"

Format-List -InputObject $objTotalObjects

#-------------------------------------------------------------------------------
#
# End of Script.
#
#-------------------------------------------------------------------------------