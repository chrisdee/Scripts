# ====================================================================================================================================
# NAME: SP2010_Site_Collection_Backup_With_Notification.ps1
# AUTHOR: Mukesh Parmar
# DATE: 07 December 2010
# COMMENT: A Powerful Script to take backup of the a particular Site Collection SharePoint 2010 Farm with email notification.
# Website: http://thecommunicator.co.cc
# ====================================================================================================================================
Add-PsSnapin Microsoft.SharePoint.Powershell –ErrorAction SilentlyContinue
try
 {
  $today = (Get-Date -Format dd-MM-yyyy)
 # Location of the Backup Folder
  [IO.Directory]::CreateDirectory("E:\Backup\DailySiteCollectionBackUp\$today")
 # Address of the Site Collection to backup
  $Site = "Site collection Address"
 # This will actually initiate the backup process. 
  Backup-SPSite -Identity $Site -PathE:\Backup\DailySiteCollectionBackUp\$today
 # Edit the From Address as per your environment.
  $emailFrom = "SPADMIN@Sharepoint.com"
 # Edit the mail address to which the Notification should be sent.
  $emailTo = "Admin@SharePoint.Com"
 # Subject for the notification email. The "+“$today part will add the date in the subject.
  $subject = "The Site Collection "+"$Site  was backed up Successful on "+"$today"
 # Body or the notification email. The + “$today” part will add the date in the subject.
  $body = "The Site Collection "+"$Site was backed up Successful on "+"$today"
 # IP address of your SMTP server. Make sure relay Is enabled for the SharePoint server on your SMTP server
  $smtpServer = "192.168.0.0"
  $smtp = new-object Net.Mail.SmtpClient($smtpServer)
  $smtp.Send($emailFrom, $emailTo, $subject, $body)
 }
Catch
 {
  $ErrorMessage = $_.Exception.Message
 # Configure the below parameters as per the above.
  $emailFrom = "SPADMIN@Sharepoint.com"
  $emailTo = "Admin@SharePoint.Com"
  $subject = "The Site Collection "+"$Site backup failed on "+"$today"
  $body = "The Site Collection "+"$Site backup failed on "+"$today and the reason for failure was $ErrorMessage."
  $smtpServer = "192.168.0.0"
  $smtp = new-object Net.Mail.SmtpClient($smtpServer)
  $smtp.Send($emailFrom, $emailTo, $subject, $body)
 }