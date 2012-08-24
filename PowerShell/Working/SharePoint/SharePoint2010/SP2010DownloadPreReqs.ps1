## SharePoint Server 2010: PowerShell Script To Download SP2010 Prerequisites 
## Resource: http://autospinstaller.codeplex.com/releases/view/44442

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
$UrlList = ("http://download.microsoft.com/download/C/9/F/C9F6B386-824B-4F9E-BD5D-F95BB254EC61/Redist/amd64/Microsoft%20Sync%20Framework/Synchronization.msi", # http://go.microsoft.com/fwlink/?LinkID=141237&clcid=0x409 - Microsoft Sync Framework Runtime v1.0 (x64) 
			"http://download.microsoft.com/download/c/c/4/cc4dcac6-ea60-4868-a8e0-62a8510aa747/MSChart.exe", # "http://go.microsoft.com/fwlink/?LinkID=141512" - Microsoft Chart Controls for the Microsoft .NET Framework 3.5
			"http://download.microsoft.com/download/2/0/e/20e90413-712f-438c-988e-fdaa79a8ac3d/dotnetfx35.exe", # http://go.microsoft.com/fwlink/?LinkId=131037 - Microsoft .NET Framework 3.5 Service Pack 1
			"http://download.microsoft.com/download/2/8/6/28686477-3242-4E96-9009-30B16BED89AF/Windows6.0-KB968930-x64.msu", # "http://download.microsoft.com/download/2/8/6/28686477-3242-4E96-9009-30B16BED89AF/Windows6.0-KB968930-x64.msu" - Windows PowerShell 2.0	
			"http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.1-KB974405-x64.msu", # "http://go.microsoft.com/fwlink/?LinkID=166363" - Windows Identity Framework (Win2008 R2)
			"http://download.microsoft.com/download/6/8/1/681F5144-4092-489B-87E4-63F05E95079C/Windows6.0-KB976394-x64.msu", # http://go.microsoft.com/fwlink/?linkID=160770 - WCF fix for Win2008 SP2
			"http://download.microsoft.com/download/E/C/7/EC785FAB-DA49-4417-ACC3-A76D26440FC2/Windows6.1-KB976462-v2-x64.msu", # http://go.microsoft.com/fwlink/?LinkID=166231 - WCF fix for Win2008 R2
			"http://download.microsoft.com/download/D/7/2/D72FD747-69B6-40B7-875B-C2B40A6B2BDD/Windows6.0-KB974405-x64.msu", # "http://go.microsoft.com/fwlink/?LinkID=160381" - Windows Identity Framework (Win2008 SP2)
			"http://download.microsoft.com/download/3/5/5/35522a0d-9743-4b8c-a5b3-f10529178b8a/sqlncli.msi", # "http://go.microsoft.com/fwlink/?LinkId=123718&clcid=0x409" - SQL Server 2008 Native Client
			"http://download.microsoft.com/download/A/D/0/AD021EF1-9CBC-4D11-AB51-6A65019D4706/SQLSERVER2008_ASADOMD10.msi", # "http://go.microsoft.com/fwlink/?LinkID=160390&clcid=0x409" - Microsoft SQL Server 2008 Analysis Services ADOMD.NET
			"http://download.microsoft.com/download/1/7/1/171CCDD6-420D-4635-867E-6799E99AB93F/ADONETDataServices_v15_CTP2_RuntimeOnly.exe", # "http://go.microsoft.com/fwlink/?LinkId=158354" - ADO.NET Data Services v1.5 CTP2 (Win2008 SP2)
			"http://download.microsoft.com/download/B/8/6/B8617908-B777-4A86-A629-FFD1094990BD/iis7psprov_x64.msi", # http://go.microsoft.com/?linkid=9655704 - IIS management cmdlets
			#"http://download.microsoft.com/download/1/0/F/10F1C44B-6607-41ED-9E82-DF7003BFBC40/1033/x64/rsSharePoint.msi", # http://go.microsoft.com/fwlink/?LinkID=166379 - SQL 2008 R2 Reporting Services SharePoint 2010 Add-in
            "http://download.microsoft.com/download/1/0/F/10F1C44B-6607-41ED-9E82-DF7003BFBC40/rsSharePoint.msi", # http://www.microsoft.com/en-us/download/details.aspx?id=622 - SQL 2008 R2 Reporting Services SharePoint 2010 Add-in - 7/27/2012
			"http://download.microsoft.com/download/8/D/F/8DFE3CE7-6424-4801-90C3-85879DE2B3DE/Platform/x64/SpeechPlatformRuntime.msi", # http://go.microsoft.com/fwlink/?LinkID=166378 - Microsoft Server Speech Platform Runtime
			"http://download.microsoft.com/download/E/0/3/E033A120-73D0-4629-8AED-A1D728CB6E34/SR/MSSpeech_SR_en-US_TELE.msi" # http://go.microsoft.com/fwlink/?LinkID=166371 - Microsoft Server Speech Recognition Language - TELE(en-US)
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