## SharePoint Server 2010: PowerShell Script to change Managed Account Passwords ##
## Resource: http://blog.rafelo.com/2010/04/changing-sharepoint-2010-managed.html ##
$ver = $host | select version
if ($ver.Version.Major -gt 1)  {$Host.Runspace.ThreadOptions = "ReuseThread"}
Add-PsSnapin Microsoft.SharePoint.PowerShell
Set-location $home

$inManagedAcct = Read-Host 'Service Account'

$managedAcct = Get-SPManagedAccount $inManagedAcct

$inPass = Read-Host 'Enter Password' -AsSecureString
$inPassConfirm = Read-Host 'Confirm Password' -AsSecureString

Set-SPManagedAccount -Identity $managedAcct -NewPassword $inPass -ConfirmPassword $inPassConfirm -SetNewPassword﻿