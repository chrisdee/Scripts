## SharePoint Server: PowerShell Script To Crawl Errors and Exceptions In Trace Logs With HTML Email Functionality ##
## Environments: MOSS 2007 and SharePoint Server 2010 / 2013 Environments - can be modified for any type of Logs
## Usage: Edit variables and add any additional -Pattern items for $criticalItems. Script checks most recent log file
## Resource: http://blog.henryong.com/2011/11/29/sharepoint-diagnostic-log-monitor-email-alert-powershell-script

############# Start Variables ################
$logDirectory = "D:\Logs\Diagnostic Logs\*.log"
$emailFrom = "FromEmailAddress"
$emailTo = @("Email1","Email2")
$subject = "SharePoint Diagnostics Critical Alert"
$smtpserver = "EmailServer"
############# End Variables ##################
$latestLogFile = get-childitem $logDirectory | sort LastWriteTime -desc | select -first 1
$criticalItems = Select-String $latestLogFile.FullName -Pattern "Critical" #Add additional Items here e.g. , "Exception"
if($criticalItems -ne $null)
{  
     $body = ""  
     foreach($criticalItem in $criticalItems)  
     {   
         $body += "<b>Error:</b> " + $criticalItem.Line + "<br><br>"   
         $body += "<b>Line Number:</b> " + $criticalItem.LineNumber + "<br><br>"   
         $body += "<b>File Path:</b> " + $criticalItem.Path + "<br><br>"   
         $body += "===================================<br><br>"  
     }    

     Send-MailMessage -To $emailTo -Subject $subject -Body $body -SmtpServer $smtpserver -From $emailFrom -BodyAsHtml
}