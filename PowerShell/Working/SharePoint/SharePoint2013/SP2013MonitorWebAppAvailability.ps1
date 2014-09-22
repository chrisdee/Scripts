## SharePoint Server: PowerShell Script To Monitor SharePoint Web App Availability With Exception HTML Email Functionality ##
## Environments: MOSS 2007 and SharePoint Server 2010 / 2013 Environments - can be modified for any other .NET Web Apps
## Usage: Edit variables to suit your environment. Script tries to download page content and sends email alert for errors
## Resource: http://blog.henryong.com/2011/11/30/sharepoint-web-pagevalid-site-monitoring-with-email-alerts-powershell-script

############# Start Variables ################
$urls = @("https://url1", "https://url2")
$emailFrom = "SharePoint.Automation@email.com"
$emailTo = @("email1","email2")
$subject = "SharePoint Down!"
$smtpserver = "SMTPServer"
$server = "ALW01"
# When used in a load-balanced environment where
# each server has host entries to itself, this can help you
# identify which server is having issues.
############# End Variables ##################

[System.Reflection.Assembly]::LoadWithPartialName("System.Net")
$wc = New-Object System.Net.WebClient
$wc.UseDefaultCredentials = $true
$body = ""

foreach($url in $urls)
{  
    try  
    {   
        $page = $wc.DownloadString($url);   
        if($page.Contains("An unexpected error has occurred.") -or $page.Contains("Cannot connect to the configuration database"))   
        {    
            $body += "<b>URL:</b> " + $url + "<br><br>"    
            $body += "<b>Server:</b> " + $server + "<br><br>"    
            $body += "<b>Exception:</b> " + "Getting a nasty error. Please help me." + "<br><br>"    
            $body += "===================================<br><br>"    
        }  
    }  

    catch [Exception]  
    {   
        $body += "<b>URL:</b> " + $url + "<br><br>"   
        $body += "<b>Server:</b> " + $server + "<br><br>"   
        $body += "<b>Exception:</b> " + $_.Exception + "<br><br>"   
        $body += "===================================<br><br>"   
    }
}

if($body -ne "")
{  
    Send-MailMessage -To $emailTo -Subject $subject -Body $body -SmtpServer $smtpserver -From $emailFrom -BodyAsHtml
}