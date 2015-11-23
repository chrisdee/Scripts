## ADFS: PowerShell Script That Uses The ADFS PowerShell Snapin To Update The Token Signing SelfSSL Certificates ##

## Resources: http://community.office365.com/en-us/wikis/sso/2062.aspx; http://technet.microsoft.com/en-us/library/ee892330.aspx

## Perform the following steps while logged on to the primary AD FS 2.0 server

#Open a PowerShell command window and execute the command:

Add-PSSnapin “microsoft.adfs.powershell”

#To double check the current signing certificates in AD FS 2.0, execute the following command:

Get-ADFSCertificate –CertificateType token-signing #Just using 'Get-ADFSCertificate' shows the Service-Communications; Token-Decrypting; and Token-Signing certs

#Look at the command output and in particular at the “[Not After]” dates of any certificates listed. 

#To generate a new certificate, execute the following command to renew and update the certificates on the AD FS server.

Update-ADFSCertificate #Updates the Token-signing and Token-decrypting certs

Update-ADFSCertificate -CertificateType Token-Signing #Updates only the Token-signing cert

Update-AdfsCertificate -CertificateType Token-Decrypting #Updates only the Token-decrypting cert

Update-ADFSCertificate -CertificateType Token-Signing -Urgent #Updates the Token-signing cert and sets it as the 'Primary' cert

Update-ADFSCertificate -CertificateType Token-Decrypting -Urgent #Updates the Token-decrypting cert and sets it as the 'Primary' cert

#Verify the update by re-executing the following command:

Get-ADFSCertificate –CertificateType token-signing

#Two certificates should be listed now, one of which has a “[Not After]” date of about one year in the future and for which the “IsPrimary” value is “False”.
