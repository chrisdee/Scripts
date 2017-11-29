## DNS: PowerShell Script to List All DNS Records in Each Zone on a Windows DNS Server ##

<#

Overview: PowerShell Script to list all DNS records in each zone on a Windows DNS server (includes sub-zones)

Note:  Script works on DNS role servers, along with AD / DNS role servers

Usage: Provide your DNS server under the '$DNSServer' variable and edit the '$Results' output properties to match your environment

Resource: http://sigkillit.com/2015/10/27/list-all-dns-records-with-powershell

#>

$DNSServer = "YourServerName" #Provide your DNS Server Name or IP address here
$Zones = @(Get-DnsServerZone -ComputerName $DNSServer)
ForEach ($Zone in $Zones) {
	Write-Host "`n$($Zone.ZoneName)" -ForegroundColor "Green"
	$Results = $Zone | Get-DnsServerResourceRecord -ComputerName $DNSServer
    echo $Results >  "C:\BoxBuild\DNS\$($Zone.ZoneName).txt"
	#echo $Results | Export-Csv "C:\BoxBuild\DNS\$($Zone.ZoneName).csv" -NoTypeInformation
}