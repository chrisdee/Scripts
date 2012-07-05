## PowerShell: Simple SMTP Email Check Script ##
## Requires PowerShell 2.0 and higher for the Send-MailMessage Commandlet ##

############# Start Variables ################
$SMTPServerName = "smtp.servername.com"
$MailServerPort = "25"
$SenderServerName = "ServerName"
$MailFrom = "SMTPTest@YourDomain.com"
$MailTo = "YourUser@YourDomain.com"
$Subject = "Subject:Telnet SMTP Mail Test"
$MailBody = "This is a Telnet SMTP Mail Test."
############# End Variables ################

Send-MailMessage –From $MailFrom –To $MailTo –Subject $Subject –Body $MailBody -SmtpServer $SMTPServerName