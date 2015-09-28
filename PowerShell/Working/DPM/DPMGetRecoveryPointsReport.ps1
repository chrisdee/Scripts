 ## DPM Server: Get Newest and Oldest Recovery Points and Write this to Email / HTML Report ##
 
 <#
 
 Overview: This script finds the newest and oldest recovery points from your dpm server/s and writes them to an html table for email / html reports
 
 Usage: Edit the Variables below to match your environment and run the script
 
 Resource: https://gallery.technet.microsoft.com/scriptcenter/DPM-2012-R2-Find-Recovery-2e01c6df
 
 #>
 
 ##################
 # Start Variables
 ##################
 
 # Put all your dpm server names in the array.
 $dpmservers = @("dpm01","dpm02")
 
 # The date is used to find recovery points that are too old, and to generate a file name.
 $date = get-date
 # Format data for e-mail title and txt file
 $Formatdate = get-date -uformat '%d-%m-%Y_%H-%M-%S'
 $filename = "C:\script\DPM\reports\DPMRecoveryPoints_"+ $Formatdate + ".htm"
 
 
 # Name of DPM  that is running script
 $hname = "dpm01"
 
 # Backup location
 $backuplocation = "C:\script\DPM\reports\" 
 new-item $backuplocation  -type directory -force
 $backuplog="$backuplocation"+(get-date -f MM-dd-yyyy)+"-backup-$hname.log" 
  
  
 # Email Variables

 # SMTP server
 $smtp = "mail01.contoso.com"
 #  E-mail to
 $to = "DPMAdmin@contoso.com"
 # E-mail FROM
 $from = "dpm01@contoso.com"
 # E-mail title
 $subject = "Report from $hname DPM RecoveryPoint for last 24 hours - $Formatdate"
 # Encoding e-mail message
 $encoding = [System.Text.Encoding]::UTF8
 
 ################
 # End Variables
 ################
 
 # Import Data Protection Module. 
  Import-Module DataProtectionManager
 
 
Function InitializeDatasourceProperties ($datasources)
 {
 $Eventcount = 0
 For($i = 0;$i -lt $datasources.count;$i++)
 {
 [void](Register-ObjectEvent $datasources[$i] -EventName DataSourceChangedEvent -SourceIdentifier "DPMExtractEvent$i" -Action{$Eventcount++})
 }
 $datasources | select LatestRecoveryPoint > $null
 $begin = get-date
 While (((Get-Date).subtract($begin).seconds -lt 10) -and ($Eventcount -lt $datasources.count) ) {sleep -Milliseconds 250}
 Unregister-Event -SourceIdentifier DPMExtractEvent* -Confirm:$false
 }
 
#Writes name and recovery point info for current iteration of $ds into HTML table. Newest recovery points not in the last 24 hours are red.
 #If there are no recovery points(1/1/0001), the table reads "Never" in red.
 Function WriteTableRowToFile($ThisDatasource, $dpmserver)
 {
 $rpLatest = $ThisDatasource.LatestRecoveryPoint
 $rpOldest = $ThisDatasource.OldestRecoveryPoint
 
"<tr><td>" | Out-File $filename -Append -Confirm:$false
 $ThisDatasource.ProductionServerName | Out-File $filename -Append -Confirm:$false
 "</td><td>" | Out-File $filename -Append -Confirm:$false
 $ThisDatasource.Name | Out-File $filename -Append -Confirm:$false
 If($rpLatest -lt $date.AddHours(-24)){
 If($rpLatest.ToUniversalTime() -eq "1/1/0001"){
 "</td><td><b><font style=`"color: #FF0000;`">Never</font></b>" | Out-File $filename -Append -Confirm:$false
 }
 Else{
 "</td><td><b><font style=`"color: #FF0000;`">" | Out-File $filename -Append -Confirm:$false
 $rpLatest.ToUniversalTime() | Out-File $filename -Append -Confirm:$false
 "</font></b>" | Out-File $filename -Append -Confirm:$false
 }
 }
 If($rpLatest -ge $date.AddHours(-24)){
 "</td><td>" | Out-File $filename -Append -Confirm:$false
 $rpLatest.ToUniversalTime() | Out-File $filename -Append -Confirm:$false
 "</td>" | Out-File $filename -Append -Confirm:$false
 }
 
If($rpOldest.ToUniversalTime() -eq "1/1/0001"){
 "<td><b><font style=`"color: #FF0000;`">Never</font></b></td><td>" | Out-File $filename -Append -Confirm:$false
 }
 Else{
 "<td>" | Out-File $filename -Append -Confirm:$false
 $rpOldest.ToUniversalTime()| Out-File $filename -Append -Confirm:$false
 "</td><td>" | Out-File $filename -Append -Confirm:$false
 }
 ($rpLatest - $rpOldest).Days | Out-File $filename -Append -Confirm:$false
 "</td><td>" | Out-File $filename -Append -Confirm:$false
 
$dpmServer | out-file $filename -append -confirm:$false
 "</td></tr>" | Out-File $filename -Append -Confirm:$false
 }
 
##Main#
 
## HTML table created
 "<html><caption><font style=`"color: #FF0000;`"><b>Red</b></font> = not backed up in the last 24 hours, or has <font style=`"color: #FF0000;`">
 <b>Never</b></font> been backed up</caption><table border =`"1`" style=`"text-align:center`" cellpadding=`"5`"><th style=`"color:#6698FF`">
 <big>DPM Backups</big></th><body><tr><th>Protection Member</th><th>Datasource</th><th>Newest Backup</th><th>Oldest Backup</th><th># of Days</th>
 <th>DPM Server</th></tr>" | Out-File $filename -Confirm:$false
 
Write-Host "Generating Protection Group Report" 
 #Disconnect-DPMserver = clear cache, this makes sure that selecting LatestRecoveryPoint in the InitializeDataSourceProperties is an event,
 #thus confirming that all the recovery points are retrieved before the script moves any further
 Disconnect-DPMserver
 #Find all datasources within each protection group
 Write-Host "Locating Datasources" 
 foreach ($dpmserver in $dpmservers){
 $dsarray = @(Get-ProtectionGroup -DPMServer $dpmserver | foreach {Get-Datasource $_}) | Sort-Object ProtectionGroup, ProductionServerName
 Write-Host " Complete" -ForegroundColor Green 
 Write-Host "Finding Recovery Points"
 InitializeDatasourceProperties $dsarray
 Write-Host " Complete" -ForegroundColor Green
 Write-Host "Writing to File"
 For($i = 0;$i -lt $dsarray.count;$i++)
 {
 WriteTableRowToFile $dsarray[$i] $dpmserver
 }
 Disconnect-DPMserver
 }
 Write-Host " Complete" -ForegroundColor Green 
 Write-Host "The report has been saved to"$filename 
 "</body></html>" | Out-File $filename -Append -Confirm:$false
 

# Send Mail Message with HTMLReport as body 
Send-MailMessage -SmtpServer $smtp -To $to -From $from -Subject $subject -Body (Get-Content $filename | Out-String) -BodyAsHtml -Encoding $encoding