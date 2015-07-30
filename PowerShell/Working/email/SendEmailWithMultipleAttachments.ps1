## PowerShell: Script to send an Email with Multiple Attachments from a File Path Folder ##

## Usage: Edit the variables below to match your requirements and run the script
## Note: Ensure you set the file path to the folder where you want the attachments to be extracted from under '$filepath'

#Connection Details
$username=""
$password=""
$smtpServer = "YourSMTPServer.com"
$msg = new-object Net.Mail.MailMessage

#Change port number for SSL to 587
$smtp = New-Object Net.Mail.SmtpClient($SmtpServer, 25) 

#Uncomment Next line for SSL  
#$smtp.EnableSsl = $true

$smtp.Credentials = New-Object System.Net.NetworkCredential( $username, $password )

#From Address
$msg.From = "yourfromemailaddress@yourdomain.com"
#To Address, Copy the below line for multiple recipients
$msg.To.Add("yourtoemailaddress@yourdomain.com")

#Message Body
$msg.Body="Please See Attached Files" #Change this to match your requirements

#Message Subject
$msg.Subject = "Email with Multiple Attachments" #Change this to match your requirements

#your file location
$filepath = "\\ShareName\FolderName" #Change this to match your requirements
$files=Get-ChildItem $filepath #You can modify the 'Get-ChildItem' parameters to refine what files you want to attach - Example: Get-ChildItem $filepath -Include *.txt

Foreach($file in $files)
{
Write-Host "Attaching File :- " $file
$attachment = New-Object System.Net.Mail.Attachment –ArgumentList $filepath\$file
$msg.Attachments.Add($attachment)

}
$smtp.Send($msg)
$attachment.Dispose();
$msg.Dispose();
