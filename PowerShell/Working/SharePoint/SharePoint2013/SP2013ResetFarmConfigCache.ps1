## SharePoint Server 2013: PowerShell Script To Reset The Config Cache On All Servers In A Farm ##
## Resource: http://woutersdemos.codeplex.com/releases

Add-PSSnapin Microsoft.SharePoint.PowerShell
$Servers = Get-SPServer | ? {$_.Role -ne "Invalid"} | Select -ExpandProperty Address
Write-Host "This script will reset the SharePoint config cache on all farm servers:"
$Servers | Foreach-Object { Write-Host $_ }
Write-Host "Press enter to start."
Read-Host
Invoke-Command -ComputerName $Servers -ScriptBlock {
try { 
Write-Host "$env:COMPUTERNAME - Stopping timer service"
Stop-Service SPTimerV4 
$ConfigDbId = [Guid](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Shared Tools\Web Server Extensions\15.0\Secure\ConfigDB' -Name Id).Id #Path to the '15 hive' ConfigDB in the registry
$CacheFolder = Join-Path -Path ([Environment]::GetFolderPath("CommonApplicationData")) -ChildPath "Microsoft\SharePoint\Config\$ConfigDbId"
Write-Host "$env:COMPUTERNAME - Clearing cache folder $CacheFolder"
Get-ChildItem "$CacheFolder\*" -Filter *.xml | Remove-Item
Write-Host "$env:COMPUTERNAME - Resetting cache ini file"
$CacheIni = Get-Item "$CacheFolder\Cache.ini"
Set-Content -Path $CacheIni -Value "1" 
}
finally{
Write-Host "$env:COMPUTERNAME - Starting timer service"
Start-Service SPTimerV4
}
}
