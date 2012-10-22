## SharePoint Server 2013: PowerShell Script To Download SP2013 Prerequisites ##
## Resources: http://www.dontpapanic.com/blog/?p=241; http://dontpapanic.com/download/DownloadAllSP2013PreReqs.txt

Import-Module BitsTransfer
## Prompt for the destination path
$DestPath = Read-Host -Prompt "- Enter the destination path for downloaded files"
## Check that the path entered is valid
If (Test-Path "$DestPath" -Verbose)
{
	## If destination path is valid, create folder if it doesn't already exist
	$DestFolder = "$DestPath\PrerequisiteInstallerFiles"
	New-Item -ItemType Directory $DestFolder -ErrorAction SilentlyContinue
}
Else
{
	Write-Warning " - Destination path appears to be invalid."
	## Pause
	Write-Host " - Please check the path, and try running the script again."
	Write-Host "- Press any key to exit..."
	$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	break
}
## We use the hard-coded URL below, so that we can extract the filename (and use it to get destination filename $DestFileName)
## Note: These URLs are subject to change at Microsoft's discretion - check the permalink next to each if you have trouble downloading.
$UrlList = ("http://download.microsoft.com/download/D/0/F/D0F564A3-6734-470B-9772-AC38B3B6D8C2/dotNetFx45_Full_x86_x64.exe", # Microsoft .NET Framework 4.5
            "http://download.microsoft.com/download/5/2/B/52B59966-3009-4F39-A99E-3732717BBE2A/Windows6.1-KB2506143-x64.msu", # Windows Management Framework 3.0 (CTP2)
	    "http://download.microsoft.com/download/9/1/3/9138773A-505D-43E2-AC08-9A77E1E0490B/1033/x64/sqlncli.msi", #Microsoft SQL Server 2008 r2 Native Client
	    "http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu", #Windows Identity Foundation (KB974405)
	    "http://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi", # Microsoft Sync Framework Runtime v1.0 SP1 (x64) 
	    "http://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe", #Windows Server AppFabric
            "http://download.microsoft.com/download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/r2/MicrosoftIdentityExtensions-64.msi", # Windows Identity Extensions
            "http://download.microsoft.com/download/9/1/D/91DA8796-BE1D-46AF-8489-663AB7811517/setup_msipc_x64.msi", # Microsoft Information Protection and Control Client
            "http://download.microsoft.com/download/8/F/9/8F93DBBD-896B-4760-AC81-646F61363A6D/WcfDataServices.exe", # Microsoft WCF Data Services 5.0
            "http://download.microsoft.com/download/7/B/5/7B51D8D1-20FD-4BF0-87C7-4714F5A1C313/AppFabric1.1-RTM-KB2671763-x64-ENU.exe" # CU Package 1 for Microsoft AppFabric 1.1 for Windows Server (KB2671763)
			)
ForEach ($Url in $UrlList)
{
	## Get the file name based on the portion of the URL after the last slash
	$DestFileName = $Url.Split('/')[-1]
	Try
	{
		## Check if destination file already exists
		If (!(Test-Path "$DestFolder\$DestFileName"))
		{
			## Begin download
			Start-BitsTransfer -Source $Url -Destination $DestFolder\$DestFileName -DisplayName "Downloading `'$DestFileName`' to $DestFolder" -Priority High -Description "From $Url..." -ErrorVariable err
			If ($err) {Throw ""}
		}
		Else
		{
			Write-Host " - File $DestFileName already exists, skipping..."
		}
	}
	Catch
	{
		Write-Warning " - An error occurred downloading `'$DestFileName`'"
		break
	}
}
## View the downloaded files in Windows Explorer
Invoke-Item $DestFolder
## Pause
Write-Host "- Downloads completed, press any key to exit..."
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")