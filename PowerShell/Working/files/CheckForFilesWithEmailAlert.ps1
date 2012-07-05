## PowerShell Script to Check for File/s and Sends an Email if these don't exist ##
## Useful for checking for backup files etc.

function SendMail($filename)
{
$emailFrom = "Email@myco.com"
$emailTo = "EmailGroup@myco.com"
$subject = "Missing file - $filename does not exist"
$body = "Missing file - $filename does not exist"
$smtpServer = "mail1"
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom, $emailTo, $subject, $body)
}
 
function Check4File($filename)
{
$bck = get-childitem $filename | where {((get-date) - $_.LastWriteTime).minutes -lt 9}
if (!$bck) { 
SendMail($filename)
}
}

## Usage Examples ##

Check4File "C:\Temp\MyFile.txt"
#Check4File "C:\Temp\*.txt"
#Check4File "C:\Temp\MySQLBackup.sqb"