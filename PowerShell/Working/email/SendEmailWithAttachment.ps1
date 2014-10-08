## PowerShell: Script to send an Email with an Attachment, along with HTML Content ##

## Usage: Edit the variables to match your requirements, and comment out any parameters you don't want to use

### Start Variables ###
$fromaddress = "YourFromAddress@YourDomain.com" 
$toaddress = "YourToAddress@YourDomain.com" 
$bccaddress = "YourBCCAddress@YourDomain.com" 
$CCaddress = "YourCCAddress@YourDomain.com" 
$Subject = "Your Subject Details" 
$body = get-content .\content.htm #Include a path to your HTML body file or provide your $body content within ""
$attachment = "C:\BoxBuild\Emails\YourFile.csv" #Include the path to your file you want to attach
$smtpserver = "Email.YourDomain.com"
### End Variables ###

## Send the email
$message = new-object System.Net.Mail.MailMessage 
$message.From = $fromaddress 
$message.To.Add($toaddress) 
$message.CC.Add($CCaddress) 
$message.Bcc.Add($bccaddress) 
$message.IsBodyHtml = $True 
$message.Subject = $Subject 
$attach = new-object Net.Mail.Attachment($attachment) 
$message.Attachments.Add($attach) 
$message.body = $body 
$smtp = new-object Net.Mail.SmtpClient($smtpserver) 
$smtp.Send($message) 