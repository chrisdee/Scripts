## DNS: PowerShell Script to Update an IP Address for an 'A' Record on a Windows DNS Server ##

<#

Overview: PowerShell Script to Update an IP Address for an 'A' Record on a Windows DNS Server

Note:  Script works on DNS role servers, along with AD / DNS role servers

Usage: Provide your variables to match your requirements and run the script

#>

### Start Variables ###
$DNSName = "YourDNSName"
$DNSZoneName = "YourDomain.com"
$IPAddress = "10.0.0.1"
### End Variables ###

$oldobj = get-dnsserverresourcerecord -name $DNSName -zonename $DNSZoneName -rrtype "A"
$newobj = get-dnsserverresourcerecord -name $DNSName -zonename $DNSZoneName -rrtype "A"
$newobj.recorddata.ipv4address=[System.Net.IPAddress]::parse($IPAddress)
Set-dnsserverresourcerecord -newinputobject $newobj -oldinputobject $oldobj -zonename $DNSZoneName -passthru