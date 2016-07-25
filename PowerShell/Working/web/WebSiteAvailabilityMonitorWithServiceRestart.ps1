## PowerShell: Script that checks a Content String on a Web Site and Restarts a Specified Service if Not Matched ##

## Overview: PowerShell: Script that checks a Content String on a Web Site and Restarts a Specified Service if Not Matched. Includes HTML email functionality

## Usage: Edit the variables below and test in your environment prior to setting up to run as a scheduled task

#Initialising
$webClient = new-object System.Net.WebClient
$webClient.Headers.Add("user-agent", "PowerShell Script")

### Start Variables ###
$dateTime = Get-Date -format 'f'
$hostName = Get-Content env:computername
$output = "" #Define output variable
$serviceName = "W3SVC" #Short windows service name (check via services.msc)
$smtpServerName = "smtp.yourserver.com" #SMTP Server name
$fromEmailAddress = "webmonitor@yourdomain.com" #Email address for mail to come from/reply address
$toEmailAddress = "touser@yourdomain.com" #Email address for mail to come from/reply address
$emailSubject = "$serviceName Service Restarted at $dateTime on $hostName"
$emailBody = "<b>$serviceName</b> Service Restarted at <b>$dateTime</b> on <b>$hostName</b>"
$stringToCheckFor = "Microsoft Internet Information Services 8" #String to check for. Note that this will be searched for with wildcards on either side
$startTime = get-date
$output = $webClient.DownloadString("http://localhost/") #Modify this url to be the url you want to test
$endTime = get-date
### End Variables ###

### Main workload ###
#The below checks for the string specified in "$stringToCheckFor" from your website, and if not found forcefully restarts the defined service
if ($output -And $output -like "*$stringToCheckFor*") {
    "Site Up`t`t" + $startTime.DateTime + "`t`t" + ($endTime - $startTime).TotalSeconds + " seconds"
} else {
    "Fail`t`t" + $startTime.DateTime + "`t`t" + ($endTime - $startTime).TotalSeconds + " seconds"
    stop-service $serviceName -force
    "Stop Service Command Sent"
    $svc = Get-Service $serviceName
    $svc.WaitForStatus('Stopped','00:01:00') #Waits for service to enter stopped state or 1 mins has passed, whichever is first
    get-service $serviceName | where-object {$_.Status -eq "Stopped"} | restart-service #Belt and braces but only restarts the service if it's stopped.
    $svc.WaitForStatus('Running','00:01:00') #Waits for service to enter Running state or 1 minute to pass, whichever is first
    Send-MailMessage -To $toEmailAddress  -Subject $emailSubject -From $fromEmailAddress -Body $emailBody -SmtpServer $smtpServerName -BodyAsHtml #Sends an email alert that the service was restarted
}