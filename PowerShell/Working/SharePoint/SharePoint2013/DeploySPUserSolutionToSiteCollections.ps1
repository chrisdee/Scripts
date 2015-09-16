## SharePoint Server: PowerShell Script to Deploy and Install a Sand Box Solution (SPUserSolution) to All Site Collections in a Web Application ##

## Overview: Script that Adds (Add-SPUserSolution) and Installs (Install-SPUserSolution) Sand Box Solutions (SPUserSolution) to all Site Collections in a Web Application

## Usage: Edit the Variables to match your requirements and run the script

### Start Variables ###
$WebApplication = "https://insidewebapp.theglobalfund.org"
$SolutionIdentity = "Wsp365.GoogleAnalytics.wsp"
$ReportPath = "C:\BoxBuild\Scripts\Deployments\GoogleAnalytics\SPSitesReport.csv"
$SolutionPath = "C:\BoxBuild\Scripts\Deployments\GoogleAnalytics\Wsp365.GoogleAnalytics.wsp"
$LogPath = "C:\BoxBuild\Scripts\Deployments\GoogleAnalytics\Deploy_Sand_Box_Solutions_Log.txt"
### End Variables ###

Start-Transcript -path $LogPath

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

## Get all the Site Collections with CSV Output

Get-SPWebApplication $WebApplication | Get-SPSite -Limit All | Select URL | Export-CSV $ReportPath -NoTypeInformation

## Add and Install the Sand Box Solution to all site collections (SPUserSolution) from CSV file

$CsvFile = Import-Csv $ReportPath

ForEach ($line in $CsvFile)

{ 

Add-SPUserSolution -LiteralPath $SolutionPath -Site $line.URL | Out-Default

Install-SPUserSolution -Identity $SolutionIdentity -Site $line.URL | Out-Default

}

Stop-Transcript