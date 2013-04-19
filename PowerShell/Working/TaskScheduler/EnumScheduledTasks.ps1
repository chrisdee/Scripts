## PowerShell: Script to produce a Report on All Scheduled Tasks on a Machine ##

## Usage: Edit the '$reportPath' variable to suit your environment location and run the script

## Resource: http://learningpcs.blogspot.ch/2011/10/powershell-working-with-scheduled-tasks.html

$reportpath = "C:\ztemp\ScheduledTasksReport.csv" #Change this path to suit your environment

# Provide header from file format to handle Import-Csv cmdlet.
$headers = "HostName","TaskName","Next Run Time","Status","Logon Mode","Last Run Time","Last Result","Author","Task To Run","Start In","Comment","Scheduled Task State","Idle Time","Power Management","Run As User","Delete Task If Not Rescheduled","Stop Task If Runs X Hours and X Mins","Schedule","Schedule Type","Start Time","Start Date","End Date","Days","Months","Repeat: Every","Repeat: Until: Time","Repeat: Until: Duration","Repeat: Stop If Still Running"

# Get schtasks.exe file path for Start-Process cmdlet.
$schTasksPath = (ls ([Environment]::GetFolderPath("System")) schtasks.exe).FullName

# Create temp file to dump output of schtasks.
$temppath = [System.IO.Path]::GetTempFileName()

# Run schtasks with /query /v options outputting data to $temppath.
Start-Process -FilePath $schTasksPath -ArgumentList "/query /v /fo csv" -RedirectStandardOutput $temppath -NoNewWindow -Wait;

# Collect csv data from file into $csvData object. 
$scheduledtasks = Import-Csv -Path $temppath -Header $headers | Export-Csv -NoTypeInformation -Path $reportPath

Write-Host -ForegroundColor Yellow "Scheduled Tasks report complete - report location: $reportpath"