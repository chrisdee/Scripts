## PowerShell Script to create and reconfigure your locations for your Diagnostic and Usage Analysis Logs ##

## Overview: PowerShell script to create and configure key parameters related to Trace Logs and Usage Analysis Processing within SharePoint Server 2010

## Note: The excellent AutoSPInstaller lets your configure most of these within the 'input' XML file - http://autospinstaller.codeplex.com

# Edit the parameters below to suit your environment

$DiagnosticLogsPath = "D:\SharePoint\DiagnosticLogs"
$DiagnosticLogsDays = "3"
$DiagnosticLogMaxDiskSpaceUsageEnabled = $True #Default should be '$True'
$DiagnosticLogDiskSpaceUsageGB = "20" #Default is 1000 GB
$DiagnosticLogCutInterval = "30" #Default is 30 minutes
$UsageAnalysisPath = "D:\SharePoint\UsageAnalysis"
$UsageAnalysisLogMaxSpaceGB = "5" #Default is 5 GB
$UsageAnalysisLogCutTime = "5" #Default is 5 minutes

Add-PSSnapin Microsoft.SharePoint.PowerShell

#Stop your SharePoint Services

net stop SPTraceV4
net stop SPTimerV4

# Tip: Use 'Get-SPDiagnosticConfig' to view additional parameters that can be set

md $DiagnosticLogsPath

Set-SPDiagnosticConfig -LogLocation $DiagnosticLogsPath -DaysToKeepLogs $DiagnosticLogsDays -LogMaxDiskSpaceUsageEnabled:$DiagnosticLogMaxDiskSpaceUsageEnabled -LogDiskSpaceUsageGB $DiagnosticLogDiskSpaceUsageGB -LogCutInterval $DiagnosticLogCutInterval


# Tip: Use 'Get-SPUsageService' to view additional parameters that can be set


md $UsageAnalysisPath

Set-SPUsageService -UsageLogLocation $UsageAnalysisPath -UsageLogMaxSpaceGB $UsageAnalysisLogMaxSpaceGB -UsageLogCutTime $UsageAnalysisLogCutTime


#Start your SharePoint Services

net start SPTraceV4
net start SPTimerV4

Write-Host Diagnostic Logs now at $DiagnosticLogsPath
Write-Host Usage Analysis Logs now at $UsageAnalysisPath

## Important - If using the 'AutoSPInstaller' solution:
# The EnterpriseSearchService Index location should have been set in your 'AutoSPInstallerInput' XML file
# IndexLocation=