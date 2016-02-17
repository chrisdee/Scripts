## ADFS: Add MSOnline Federation to ADFS ##

## Run the example commands below within the Windows Azure Active Directory PowerShell Module installed on your Primary ADFS server

## Versions: ADFS 2.0 / 3.0

## Resources:

#http://blogs.technet.com/b/canitpro/archive/2015/09/11/step-by-step-setting-up-ad-fs-and-enabling-single-sign-on-to-office-365.aspx

#https://www.helloitsliam.com/2015/01/23/sharepoint-2013-and-adfs-with-multiple-domains/

#Add the ADFS PowerShell Module for ADFS 2.0
Add-PSSnapin "microsoft.adfs.powershell" -ErrorAction SilentlyContinue

#Import the ADFS PowerShell Module for ADFS 3.0+
Import-Module ADFS

#Import the Windows Azure MSOnline PowerShell Modules
Import-Module MSOnline
Import-Module MSOnlineExtended 

$cred =Get-Credential

Connect-MsolService –Credential $cred

Set-MsolADFSContext –Computer adfs_servername.domain_name.com   #internal FQDN of the Primary ADFS server
 
Convert-MsolDomainToFederated –DomainName domain_name.com
 
Get-MsolFederationProperty –DomainName domain_name.com