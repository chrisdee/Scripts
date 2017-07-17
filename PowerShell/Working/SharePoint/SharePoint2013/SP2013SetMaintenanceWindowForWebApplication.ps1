## SharePoint Server: PowerShell Script to Set Maintenance Window Notifications at Content Database Level for a Web Application ##


## Resource: http://www.sharepointdiary.com/2013/12/sharepoint-2013-maintenance-windows.html#ixzz4k9v5EcHz

Add-PSSnapin Microsoft.sharepoint.powershell -ErrorAction SilentlyContinue
 
$WebAppURL = "https://YourWebApp.YourDomain.com" #Change this to match your environment
 
#Get all content databases of the web application
$ContentDbs = Get-SPContentDatabase -WebApplication $WebAppURL
 
#Create maintenance Window Object
$MaintenanceWindow = New-Object Microsoft.SharePoint.Administration.SPMaintenanceWindow
$MaintenanceWindow.MaintenanceEndDate    = "06/19/2017 12:00:00 PM"
$MaintenanceWindow.MaintenanceStartDate  = "06/19/2017 8:00:00 AM"
$MaintenanceWindow.NotificationEndDate   = "06/19/2017 12:00:00 PM"
$MaintenanceWindow.NotificationStartDate = "06/16/2017 2:30:00 PM"
$MaintenanceWindow.MaintenanceType       = "MaintenancePlanned"  #Another Option: MaintenanceWarning
$MaintenanceWindow.Duration              = "00:04:00:00" #in "DD:HH:MM:SS" format
$MaintenanceWindow.MaintenanceLink       = "https://www.yourwebsite.com" #Provide this property if you want to display a web link with more information
 
#Add Maintenance window for each content database of the web application
$ContentDbs | ForEach-Object  {
 #Clear any existing maintenance window
 $_.MaintenanceWindows.Clear()
  
 #Add New Maintenance Window
 $_.MaintenanceWindows.add($MaintenanceWindow)
    $_.Update()
 }
