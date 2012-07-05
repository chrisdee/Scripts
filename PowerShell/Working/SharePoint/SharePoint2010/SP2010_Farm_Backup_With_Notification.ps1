# ==============================================================================================
# NAME: SP2010_Farm_Backup_With_Notification.ps1
# AUTHOR: Mukesh Parmar
# DATE: 07 December 2010
# COMMENT: A Powerful Script to take backup of the entire SharePoint 2010 Farm with email notification.
# Website: http://thecommunicator.co.cc
# ==============================================================================================
Add-PsSnapin Microsoft.SharePoint.Powershell –ErrorAction SilentlyContinue
try
 {
  $today = (Get-Date -Format dd-MM-yyyy)
 #Location of the Backup Folder
  [IO.Directory]::CreateDirectory("E:\Backup\DailyFarmBackUp\$today")
 # This will actually initiate the SPFarm backup.
  Backup-SPFarm -Directory E:\Backup\DailyFarmBackup\$today -BackupMethod full
 # Edit the From Address as per your environment.
  $emailFrom = "SPADMIN@Sharepoint.com"
 # Edit the mail address to which the Notification should be sent.
  $emailTo = "Admin@SharePoint.Com"
 # Subject for the notification email. The + “$today” part will add the date in the subject.
  $subject = "The SharePoint Farm Backup was Successful for "+"$today"
 # Body or the notification email. The + “$today” part will add the date in the subject.
  $body = "The SharePoint Farm Backup was Successful for "+"$today"
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
  $subject = "The SharePoint Farm Backup Job failed on "+"$today"
  $body = "The SharePoint Farm Backup Job failed on "+"$today and the reason for failure was $ErrorMessage."
  $smtpServer = "192.168.0.0"
  $smtp = new-object Net.Mail.SmtpClient($smtpServer)
  $smtp.Send($emailFrom, $emailTo, $subject, $body)
 }