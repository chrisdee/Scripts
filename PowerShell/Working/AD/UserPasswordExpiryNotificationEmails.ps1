## Active Directory: PowerShell Script For Active Directory Password Expiration Notification Emails ##

<#

Overview: PowerShell script that uses the 'ActiveDirectory' PowerShell Module to query and report on user accounts in Active Directory
that are near expiry, or have expired. Has email functionality to send email reminders out to all the domain users, along with Admin Staff.

Resource: http://www.itouthouse.com/2012/06/active-directory-password-expiration.html

Usage: Find all the variables under the 'CONFIG:' labels in the script, and edit these to suit your requirements. Save the script
and run it on a machine that has the 'ActiveDirectory' PowerShell module installed on it.

#>

Import-Module ActiveDirectory

$maxdays=(Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.TotalDays
$summarybody="Name `t ExpireDate `t DaysToExpire `n"

(Get-ADUser -filter {(mail -like "*@domain.com") -and (Enabled -eq "True") -and (PasswordNeverExpires -eq "False")} -properties *) | Sort-Object pwdLastSet |
foreach-object {

    $lastset=Get-Date([System.DateTime]::FromFileTimeUtc($_.pwdLastSet))
    $expires=$lastset.AddDays($maxdays).ToShortDateString()
    $daystoexpire=[math]::round((New-TimeSpan -Start $(Get-Date) -End $expires).TotalDays)
    $samname=$_.samaccountname
    $firstname=$_.GivenName
    if (($daystoexpire -eq 14) -or ($daystoexpire -eq 7) -or ($daystoexpire -eq 3) -or ($daystoexpire -eq 1) -or ($daystoexpire -eq 0)) {
    #if ($daystoexpire -le 14) {
        $ThereAreExpiring=$true
         
         # CONFIG: Enter from email address. 
        $emailFrom = "helpdesk@domain.com"
        # CONFIG: Replace domain domain.com with your email domain. Do not change $samname. 
        $emailTo = "$samname@domain.com"
        if ($daystoexpire -eq 0) {
        # CONFIG: Enter text for subject and body of email notification for zero days remaining. 
            $subject = "$firstname, your password has expried!"
            $body = "$firstname,
Your password has expired and you must change it immediately. No further email notifications will be sent. 

Contact support at extension XXXX for assistance."
        }
        Else {
        # CONFIG: Enter text for subject and body of email notification for 14, 7, 3, and 1 days remaining.  
            $subject = "$firstname, your password expires in $daystoexpire day(s)!"
            $body = "$firstname,
Your password expires in $daystoexpire day(s).

If you are using a Windows computer, press Ctrl + Alt + Del the click Change password.

If you are using a Mac computer follow the instructions at http://sharepoint/Documentation to change your password. 
"
        }
        # CONFIG: Enter your smtp server here. 
        $smtpServer = "email.domain.com"
        $smtp = new-object Net.Mail.SmtpClient($smtpServer)
        $smtp.Send($emailFrom, $emailTo, $subject, $body)    
        
        $summarybody += "$samname `t $expires `t $daystoexpire `n"
    }
    elseif ($daystoexpire -lt 0) {
        $ThereAreExpiring=$true
        # Add a note to the report email, but don't notify user. 
        $summarybody += "$samname `t $expires `t $daystoexpire `n"
    }
}
if ($ThereAreExpiring) {
    # CONFIG: From address for report to Helpdesk/IT Admin staff. 
    $emailFrom = "helpdesk@domain.com"
    # CONFIG: Address to send report email to for Helpdesk/IT Admin staff. 
    $emailTo = "helpdesk@domain.com"
    # CONFIG: Subject for report email. 
    $subject = "Expiring passwords"
    $body = $summarybody
    # CONFIG: SMTP Server. 
    $smtpServer = "email.domain.com"
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $smtp.Send($emailFrom, $emailTo, $subject, $body)
    }