## SharePoint Server: List all Installed SharePoint Products on a Machine with PowerShell ##

#Currently looking for SharePoint Server 2013 '90150000'
$listApps=Get-WmiObject -Class Win32_Product | Where {$_.IdentifyingNumber -like “*90150000-*”}
$listApps | Sort -Property Name | ft -Autosize
