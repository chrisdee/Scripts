## SharePoint Server: PowerShell Script To Test SharePoint Send Mail Functionality ##

<#

Overview: PowerShell Script that uses the Object Model to test sending email using the same 'SPUtility.SendMail' configured in the Incoming/Outgoing Central Admin E-Mail Settings

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the variables below and run the script

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

##### Begin Variables #####
$spsite = "https://devinside.npe.theglobalfund.org" #Provide your SharePoint site details here
$email = "yourname@youremail.com" #Add your recipient email address here
$subject = "SharePoint SendMail Test" #Change your subject here
$body = "Email sent via SharePoint site $spsite" #Change your body text here
##### End Variables #####

$site = New-Object Microsoft.SharePoint.SPSite "$spsite"
$web = $site.OpenWeb()
[Microsoft.SharePoint.Utilities.SPUtility]::SendEmail($web,0,0,$email,$subject,$body)
