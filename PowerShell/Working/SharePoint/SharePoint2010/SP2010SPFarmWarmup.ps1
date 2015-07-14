## SharePoint Server: PowerShell Script that Warms up a SharePoint Farm through opening IE Web Requests for Central Admin, Web Applications, and Site Collections ##

<#  
.SYNOPSIS  
    Warm up SharePoint IIS memory cache by viewing pages from Internet Explorer
	
.DESCRIPTION  
    Loads the full page so resources like CSS, JS, and images are included.  Please modify lines 80-105
	to suit your portal content design (popular URLs, custom pages, etc.)

.PARAMETER install
	Typing "SPBestWarmUp.ps1 -install" will create a local Task Scheduler job under credentials of the
	current user.  Job runs every 60 minutes on the hour to help automatically populate cache after
	nightly IIS recycle.

.USAGE
	
	./SPBestWarmUp.ps1 #Runs without the scheduled task or after the scheduled task has been provisioned
	
	./SPBestWarmUp.ps1 -install #Runs with the -install switch to create the scheduled task
	
.NOTES  
    File Name     : SPBestWarmUp.ps1
    Author        : Jeff Jones - @spjeff
    Version       : 1.6
	Last Modified : 11-21-2014
.LINKS
	http://spbestwarmup.codeplex.com
	http://gallery.technet.microsoft.com/scriptcenter/SPBestWarmUp-Warmup-e7c77527

.ENVIRONMENTS
	SharePoint Server 2010 / 2013 Farms

#>

param (
	[switch]$install
)

Function Installer() {
	# Add to Task Scheduler
	Write-Host "  Installing to Task Scheduler..." -ForegroundColor Green
	$user = $ENV:USERDOMAIN+"\"+$ENV:USERNAME
	Write-Host "  Current User: $user"
	
	# Attempt to detect password from IIS Pool (if current user is local admin and farm account)
	$appPools = Get-WmiObject -Namespace "root\MicrosoftIISV2" -Class "IIsApplicationPoolSetting" | Select WAMUserName, WAMUserPass
	foreach ($pool in $appPools) {			
		if ($pool.WAMUserName -like $user) {
			$pass = $pool.WAMUserPass
			if ($pass) {
				break
			}
		}
	}
	
	# Manual input if auto detect failed
	if (!$pass) {
		$pass = Read-Host "Enter password for $user "
	}
	
	# Create Task
	$cmd = """PowerShell.exe -ExecutionPolicy Bypass '$global:path'"""
	schtasks /create /tn "SPBestWarmUp" /ru $user /rp $pass /rl highest /sc daily /st 01:00 /ri 60 /du 24:00 /tr $cmd
	Write-Host "  [OK]" -ForegroundColor Green
	Write-Host
}

Function WarmUp() {
	
	# Get URL list
	Add-PSSnapIn Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
	$was = Get-SPWebApplication -IncludeCentralAdministration
	$was |? {$_.IsAdministrationWebApplication -eq $true} |% {$caTitle = Get-SPWeb $_.Url | Select Title}
	
	# Warm up SharePoint web applications
	Write-Host "Opening Web Applications..."
	$global:ie = New-Object -Com "InternetExplorer.Application"
	$global:ie.Navigate("about:blank")
	$global:ie.Visible = $true
	$global:ieproc = (Get-Process -Name iexplore)|? {$_.MainWindowHandle -eq $global:ie.HWND}
	
	foreach ($wa in $was) {
		$url = $wa.Url
		IENavigateTo $url
		IENavigateTo $url"_layouts/viewlsts.aspx"
		IENavigateTo $url"_vti_bin/UserProfileService.asmx"
		IENavigateTo $url"_vti_bin/sts/spsecuritytokenservice.svc"
	}
	
	# Warm up Service Applications
	Get-SPServiceApplication |% {$_.EndPoints |% {$_.ListenUris |% {IENavigateTo $_.AbsoluteUri}}}
	
	# Warm up custom URLs
	Write-Host "Opening Custom URLs..."
	IENavigateTo "http://localhost:32843/Topology/topology.svc"
	
	# Add your own URLs below.  Looks at Central Admin Site Title for full lifecycle support in a single script file.
	switch -Wildcard ($caTitle) {
		"*PROD*" {
			#IENavigateTo "http://portal/popularPage.aspx"
			#IENavigateTo "http://portal/popularPage2.aspx"
			#IENavigateTo "http://portal/popularPage3.aspx
		}
		"*TEST*" {
			#IENavigateTo "http://portal/popularPage.aspx"
			#IENavigateTo "http://portal/popularPage2.aspx"
			#IENavigateTo "http://portal/popularPage3.aspx
		}
		"*DEV*" {
			#IENavigateTo "http://portal/popularPage.aspx"
			#IENavigateTo "http://portal/popularPage2.aspx"
			#IENavigateTo "http://portal/popularPage3.aspx
		}
		default {
			#IENavigateTo "http://portal/popularPage.aspx"
			#IENavigateTo "http://portal/popularPage2.aspx"
			#IENavigateTo "http://portal/popularPage3.aspx
		}
	}
	
	# Warm up Host Name Site Collections (HNSC)
	Write-Host "Opening Host Name Site Collections (HNSC)..."
	$hnsc = Get-SPSite -Limit All |? {$_.HostHeaderIsSiteName -eq $true} | Select Url
	foreach ($sc in $hnsc) {
		IENavigateTo $sc.Url
	}
	
	# Close IE window
	if ($global:ie) {
		Write-Host "Closing IE"
		$global:ie.Quit()
	}
	$global:ieproc | Stop-Process -Force -ErrorAction SilentlyContinue
	
	# Clean Temporary Files
	Remove-item "$env:systemroot\system32\config\systemprofile\appdata\local\microsoft\Windows\temporary internet files\content.ie5\*.*" -Recurse -ErrorAction SilentlyContinue
	Remove-item "$env:systemroot\syswow64\config\systemprofile\appdata\local\microsoft\Windows\temporary internet files\content.ie5\*.*" -Recurse -ErrorAction SilentlyContinue
}

Function IENavigateTo([string] $url, [int] $delayTime = 500) {
	# Navigate to a given URL
	if ($url) {
		if ($url.ToUpper().StartsWith("HTTP")) {
			Write-Host "  Navigating to $url"
			try {
				$global:ie.Navigate($url)
			} catch {
				try {
					$pid = $global:ieproc.id
				} catch {}
				Write-Host "  IE not responding.  Closing process ID $pid"
				$global:ie.Quit()
				$global:ieproc | Stop-Process -Force -ErrorAction SilentlyContinue
				$global:ie = New-Object -Com "InternetExplorer.Application"
				$global:ie.Navigate("about:blank")
				$global:ie.Visible = $true
				$global:ieproc = (Get-Process -Name iexplore)|? {$_.MainWindowHandle -eq $global:ie.HWND}
			}
			IEWaitForPage $delayTime
		}
	}
}

Function IEWaitForPage([int] $delayTime = 500) {
	# Wait for current page to finish loading
	$loaded = $false
	$loop = 0
	$maxLoop = 20
	while ($loaded -eq $false) {
		$loop++
		if ($loop -gt $maxLoop) {
			$loaded = $true
		}
		[System.Threading.Thread]::Sleep($delayTime) 
		# If the browser is not busy, the page is loaded
		if (-not $global:ie.Busy)
		{
			$loaded = $true
		}
	}
}

#Main
Start-Transcript
Write-Host "SPBestWarmUp v1.6  (last updated 11-21-2014)`n"

#Check Permission Level
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    break
} else {
    #Warm up
    $global:path = $MyInvocation.MyCommand.Path
    $tasks = schtasks /query /fo csv | ConvertFrom-Csv
    $spb = $tasks |? {$_.TaskName -eq "\SPBestWarmUp"}
    if (!$spb -and !$install) {
	    Write-Host "Tip: to install on Task Scheduler run the command ""SPBestWarmUp.ps1 -install""" -ForegroundColor Yellow
    }
    if ($install) {
	    Installer
    }
    WarmUp
}
Stop-Transcript