## SharePoint Server 2010: PowerShell Script To Get Timer Job Histories With Output To A CSV File ##

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

############# Start Variables ################
$test = Get-SPWebApplication "http://YourSharePointWebApplication.com"
$myStartTime = "9/29/2011 12:30:00 AM"
$myStopTime = "2/03/2012 3:30:00 AM"
############# End Variables ##################

#GET ALL BETWEEN THAT TIME PERIOD
Write-Host "Fetching all jobs to JobHistoryOutput.csv for $myStartTime - $myStopTime..." -ForeGroundColor Red
$test.JobHistoryEntries | Where-Object {($_.StartTime -gt $myStartTime) -and ($_.StartTime -lt $myStopTime)} | Export-Csv JobHistoryOutput.csv –NoType
Write-Host "Done! Check JobHistoryOutput.csv for info." -ForeGroundColor Green

#GET ALL THAT FAILED BETWEEN THAT TIME PERIOD
Write-Host "Fetching all errors to JobHistoryOutputErrors.csv for $myStartTime - $myStopTime..." -ForeGroundColor Red
$test.JobHistoryEntries | Where-Object {($_.StartTime -gt $myStartTime) -and ($_.StartTime -lt $myStopTime) -and ($_.Status -ne 'Succeeded')} | Export-Csv JobHistoryOutputErrors.csv –NoType
Write-Host "Done! Check JobHistoryOutputErrors.csv for info." -ForeGroundColor Green