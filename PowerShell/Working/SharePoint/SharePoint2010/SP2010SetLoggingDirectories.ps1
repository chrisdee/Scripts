## PowerShell Script to create and reconfigure your locations for your Diagnostic and Usage Analysis Logs ##

# Edit the parameters below to suit your environment

$DiagnosticLogs = "D:\SharePoint\DiagnosticLogs"
$DiagnosticLogsDays = "3"
$UsageAnalysis = "D:\SharePoint\UsageAnalysis"

Add-PSSnapin Microsoft.SharePoint.PowerShell

#Stop your SharePoint Services

net stop SPTraceV4
net stop SPTimerV4

# Get-SPDiagnosticConfig

md $DiagnosticLogs

Set-SPDiagnosticConfig -LogLocation $DiagnosticLogs -DaysToKeepLogs $DiagnosticLogsDays


# Get-SPUsageService


md $UsageAnalysis

Set-SPUsageService -UsageLogLocation $UsageAnalysis


#Start your SharePoint Services

net start SPTraceV4
net start SPTimerV4

Write-Host Diagnostic Logs now at $DiagnosticLogs
Write-Host Usage Analysis Logs now at $UsageAnalysis

## Important - If using the 'AutoSPInstaller' solution:
# The EnterpriseSearchService Index location should have been set in your 'AutoSPInstallerInput' XML file
# IndexLocation=