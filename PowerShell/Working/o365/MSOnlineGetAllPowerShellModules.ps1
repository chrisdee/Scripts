## MSOnline: PowerShell Script to Download All Office 365 Pre-requisites and PowerShell Modules (o365 / MSOnline) ##

#region License

<#
	{
		"info": {
			"Statement": "Code is poetry",
			"Author": "Joerg Hochwald",
			"Contact": "joerg.hochwald@outlook.com",
			"Link": "http://hochwald.net",
			"Support": "https://github.com/jhochwald/MyPowerShellStuff/issues"
		},
		"Copyright": "(c) 2012-2016 by Joerg Hochwald & Associates. All rights reserved."
	}

	Redistribution and use in source and binary forms, with or without modification,
	are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice, this list of
	   conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above copyright notice,
	   this list of conditions and the following disclaimer in the documentation and/or
	   other materials provided with the distribution.

	3. Neither the name of the copyright holder nor the names of its contributors may
	   be used to endorse or promote products derived from this software without
	   specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
	IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
	AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
	THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
	OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.

	By using the Software, you agree to the License, Terms and Conditions above!

	#################################################
	# modified by     : Joerg Hochwald
	# last modified   : 2016-03-19
	#################################################

Usage Example: Get-PreReqModules -Path "C:\BoxBuild\o365"

Resource: https://github.com/jhochwald/MyPowerShellStuff/blob/master/Modules/ToolBox/Public/Get-PreReqModules.ps1

#>


#endregion License

function global:Get-PreReqModules {
<#
	.SYNOPSIS
		Get all required Office 365 Modules and Software from Microsoft

	.DESCRIPTION
		Get all required Office 365 Modules and Software from Microsoft

		It Downloads:
		-> .NET Framework 4.5.2 Off-line Installer
		-> Microsoft Online Services Sign-In Assistant for IT Professionals RTW
		-> Microsoft Azure Active Directory PowerShell Module
		-> SharePoint Online Management Shell
		-> Skype for Business Online Windows PowerShell Module

	.PARAMETER Path
		Where to Download

	.NOTES
		Just a helper function based on an idea of En Pointe Technologies

		.NET Framework 4.5.2 Off-line Installer URL
		https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe

		Microsoft Online Services Sign-In Assistant for IT Professionals RTW URL
		https://download.microsoft.com/download/5/0/1/5017D39B-8E29-48C8-91A8-8D0E4968E6D4/en/msoidcli_64.msi

		Microsoft Azure Active Directory PowerShell Module URL
		https://bposast.vo.msecnd.net/MSOPMW/Current/amd64/AdministrationConfig-en.msi

		SharePoint Online Management Shell URL
		https://download.microsoft.com/download/0/2/E/02E7E5BA-2190-44A8-B407-BC73CA0D6B87/sharepointonlinemanagementshell_4915-1200_x64_en-us.msi

		Skype for Business Online Windows PowerShell Module URL
		https://download.microsoft.com/download/2/0/5/2050B39B-4DA5-48E0-B768-583533B42C3B/SkypeOnlinePowershell.exe

       .USAGE EXAMPLE
        Get-PreReqModules -Path "C:\BoxBuild\o365"

        .RESOURCE
        https://gist.github.com/jhochwald/345af16660cca3e3128e#file-get-prereqmodules-ps1
#>

	[CmdletBinding(ConfirmImpact = 'None',
				   SupportsShouldProcess = $true)]
	param
	(
		[Parameter(ValueFromPipeline = $true,
				   Position = 0,
				   HelpMessage = 'Where to Download')]
		[System.String]$Path = "c:\scripts\powershell\prereq"
	)

	BEGIN {
		# Is the download path already here?
		if (-not (Test-Path $Path)) {
			(New-Item -ItemType Directory $Path -Force -Confirm:$false) > $null 2>&1 3>&1
		} else {
			Write-Output "Download path already exists"
		}
	}

	PROCESS {
		<#
			Now download all the required software
		#>

		try {
			# Whare to download and give the Filename
			$dlPath = (Join-Path $Path -ChildPath "NDP452-KB2901907-x86-x64-AllOS-ENU.exe")

			# Is this file already downloaded?
			if (Test-Path $dlPath) {
				# It exists
				Write-Output "$dlPath exists..."
			} else {
				# Download it
				Write-Output "Processing: .NET Framework 4.5.2 Offline Installer"
				Invoke-WebRequest -Uri https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe -OutFile $dlPath
			}
		} catch {
			# Aw Snap!
			Write-Warning -Message "Unable to download: .NET Framework 4.5.2 Offline Installer"
		}

		try {
			$dlPath = (Join-Path $Path -ChildPath "msoidcli_64.msi")

			if (Test-Path $dlPath) {
				Write-Output "$dlPath exists..."
			} else {
				Write-Output "Processing: Microsoft Online Services Sign-In Assistant for IT Professionals RTW"
				Invoke-WebRequest -Uri https://download.microsoft.com/download/5/0/1/5017D39B-8E29-48C8-91A8-8D0E4968E6D4/en/msoidcli_64.msi -OutFile $dlPath
			}
		} catch {
			Write-Warning -Message "Unable to download: Microsoft Online Services Sign-In Assistant for IT Professionals RTW"
		}

		try {
			$dlPath = (Join-Path $Path -ChildPath "AdministrationConfig-en.msi")

			if (Test-Path $dlPath) {
				Write-Output "$dlPath exists..."
			} else {
				Write-Output "Processing: Microsoft Azure Active Directory PowerShell Module"
				Invoke-WebRequest -Uri https://bposast.vo.msecnd.net/MSOPMW/Current/amd64/AdministrationConfig-en.msi -OutFile $dlPath
			}
		} catch {
			Write-Warning -Message "Unable to download: Microsoft Azure Active Directory PowerShell Module"
		}

		try {
			$dlPath = (Join-Path $Path -ChildPath "sharepointonlinemanagementshell_4915-1200_x64_en-us.msi")

			if (Test-Path $dlPath) {
				Write-Output "$dlPath exists..."
			} else {
				Write-Output "Processing: Sharepoint Online Management Shell"
				Invoke-WebRequest -Uri https://download.microsoft.com/download/0/2/E/02E7E5BA-2190-44A8-B407-BC73CA0D6B87/sharepointonlinemanagementshell_4915-1200_x64_en-us.msi -OutFile $dlPath
			}
		} catch {
			Write-Warning -Message "Unable to download: Sharepoint Online Management Shell"
		}

		try {
			$dlPath = (Join-Path $Path -ChildPath "SkypeOnlinePowershell.exe")

			if (Test-Path $dlPath) {
				Write-Output "$dlPath exists..."
			} else {
				Write-Output "Processing: Skype for Business Online Windows PowerShell Module"
				Invoke-WebRequest -Uri https://download.microsoft.com/download/2/0/5/2050B39B-4DA5-48E0-B768-583533B42C3B/SkypeOnlinePowershell.exe -OutFile $dlPath
			}
		} catch {
			Write-Warning -Message "Unable to download: Skype for Business Online Windows PowerShell Module"
		}
	}

	END {
		Write-Output "Prerequesites downloaded to $Path"

		Invoke-Item $Path
	}
}
