## SharePoint Server: PowerShell Script To Register Certificates For High Trust Provider Hosted Apps On A SharePoint Farm ##

<#

Overview: PowerShell Script to configure a SharePoint Farm to use Certificates and configure trust for Provider Hosted Apps

A high-trust app is a provider-hosted app for SharePoint that uses the digital certificates to establish trust between the remote web application and SharePoint. 
"High-trust" is not the same as "full trust". A high-trust app must still request app permissions.
The app is considered "high-trust" because it is trusted to use any user identity that the app needs, because the app is responsible for creating the user portion of the access token that it passes to SharePoint.

Environments: SP2013 Farms

Usage: Change the following variables to match your requirements '$publicCertPath'; '$issuerId'; '$spurl'; '$serviceConfig.AllowOAuthOverHttp' and run the script

Tip: Use the following PowerShell Commandlets to enumerate and manage your SharePoint Farm Security Token Service and Trusted Root Authority

Get-SPSecurityTokenServiceConfig (http://technet.microsoft.com/en-us/library/ff607642.aspx)
Get-SPTrustedRootAuthority (http://technet.microsoft.com/en-us/library/ff607623.aspx)
Remove-SPTrustedRootAuthority (http://technet.microsoft.com/en-us/library/ff607741.aspx)
Get-SPTrustedSecurityTokenIssuer (http://technet.microsoft.com/en-us/library/jj219760.aspx)
Remove-SPTrustedSecurityTokenIssuer (http://technet.microsoft.com/en-us/library/jj219755.aspx)

Important: Always leave the default 'local' SPTrustedRootAuthority in place on a Farm (Microsoft.SharePoint.Administration.SPTrustedRootAuthority)

Resources: http://msdn.microsoft.com/en-us/library/fp179901.aspx; http://www.sharepointpals.com/post/Step-by-Step-approach-to-create-a-Provider-Hosted-Application-in-SharePoint-2013

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$publicCertPath = "C:\BoxBuild\Certs\spproviderhostedapps.YourDomain.com.cer" #Change this path to match your environment. CER certificate type should be 'Base-64 encoded X.509'

#$issuerId = [System.Guid]::NewGuid().ToString()
$issuerId = ([Guid]"8390d39c-117f-44da-8dd6-a11efca05516").ToString() #IssuerId GUID requires lower case alpha characters

$spurl ="http://intranet.YourDomain.com" #Change this Web Application URL to match your environment

$spweb = Get-SPWeb $spurl

$sc = Get-SPServiceContext $spweb.site

$realm = Get-SPAuthenticationRealm -ServiceContext $sc
$realm

$certificate = Get-PfxCertificate $publicCertPath

$fullIssuerIdentifier = $issuerId + '@' + $realm

New-SPTrustedSecurityTokenIssuer -Name $issuerId -Certificate $certificate -RegisteredIssuerName $fullIssuerIdentifier –IsTrustBroker

iisreset

write-host "Full Issuer ID: " -nonewline
write-host $fullIssuerIdentifier -ForegroundColor Red
write-host "Issuer ID for web.config: " -nonewline
write-host $issuerId -ForegroundColor Red

#Enable / Disable OAuth HTTP Authentication Depending on your environment

$serviceConfig = Get-SPSecurityTokenServiceConfig
$serviceConfig.AllowOAuthOverHttp = $true #Change this value to '$false' if you don't want to allow OAuth over HTTP - Good idea for Production environments
$serviceConfig.Update()

New-SPTrustedRootAuthority -Name "$($certificate.Subject)_$($certificate.Thumbprint)" -Certificate $certificate