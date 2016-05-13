## Internet Explorer: PowerShell Script to List Trusted Sites in IE Browser ##

## Overview: Script Gets all the Trusted Sites stored in Internet Explorer (IE) under 'Internet Options - Security - Trusted Sites'

$_List1 = @()
$_List2 = @()
$_List3 = @()

$_List1 = $(Get-item 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey' -ErrorAction SilentlyContinue).property  

$_List2 = $(Get-item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey' -ErrorAction SilentlyContinue).property | Out-GridView

$_List3 = $_List1 + $_List2 
$_List3 | Out-GridView