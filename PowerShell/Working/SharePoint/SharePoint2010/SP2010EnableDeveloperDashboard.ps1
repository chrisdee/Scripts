## SharePoint Server 2010: PowerShell Script To Toggle The Developer Dashboard On All Web Apps In A Farm ##
## Overview: Same results as the following command: STSADM -o setproperty -pn developer-dashboard -pv OnDemand 

Add-PSSnapin "Microsoft.SharePoint.Powershell" -ErrorAction SilentlyContinue

$DevDashboardSettings = [Microsoft.SharePoint.Administration.SPWebService]::ContentService.DeveloperDashboardSettings;
$DevDashboardSettings.DisplayLevel = 'OnDemand'; #Change this value to either: 'OnDemand'; 'On'; 'Off'
$DevDashboardSettings.RequiredPermissions = 'EmptyMask';
$DevDashboardSettings.TraceEnabled = $true;
$DevDashboardsettings.Update()