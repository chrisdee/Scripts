## SharePoint Server: PowerShell Script to Check ULS logs and Merge the Correlation ID Events into One Log File ##

## Environments: SharePoint Server 2013 Farms
## Resource: http://habaneroconsulting.com/insights/An-Even-Better-Way-to-Get-the-Real-SharePoint-Error#.VG84ATTF98F

Add-PSSnapIn Microsoft.SharePoint.PowerShell

$CorrelationID = "d9e7c69c-f2a5-f061-86b8-afda705c908c" #Provide your Correlation ID GUID here
$LogFile = "C:\BoxBuild\SPError.log" #Change this log path to suit your environment
Merge-SPLogFile -Path "$LogFile" -Correlation "$CorrelationID"
