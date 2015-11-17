## ADFS Server: Useful Powershell Commandlets To Run On Your ADFS Server ##

Add-PSSnapin "microsoft.adfs.powershell" -ErrorAction SilentlyContinue

# Get ADFS Configuration Properties

Get-ADFSProperties

# Get ADFS Relying Party Trust

Get-ADFSRelyingPartyTrust

Get-ADFSRelyingPartyTrust | select Name, Identifier

# Enable or Disable Auto Certificate Rollover

Set-ADFSProperties -AutoCertificateRollover $true
Set-ADFSProperties -AutoCertificateRollover $false

# Set ADFS Self-Signed Certificates Duration

Set-AdfsProperties -CertificateDuration 730 #Specify number of days

# Update ADFS Self-Signed Certificates

Update-AdfsCertificate -Urgent

# Get Relying Party Trust Properties

$RelyingPartyTrust = "YourRelyingPartyTrustName"
Get-ADFSRelyingPartyTrust -Name $RelyingPartyTrust

# Update Relying Party Trust Name

$RelyingPartyTrust = "YourRelyingPartyTrustName"
Set-ADFSRelyingPartyTrust -TargetName $RelyingPartyTrust -Name "YourNewRelyingPartyTrustName"

# Update Relying Party Trust Signing Certificate Revocation Check from 'CheckChainExcludeRoot' (default) to 'None'

$RelyingPartyTrust = "YourRelyingPartyTrustName"
Set-ADFSRelyingPartyTrust -TargetName $RelyingPartyTrust -SigningCertificateRevocationCheck "None"

# Update Relying Party Trust Signature Algorithm from 'SHA-256' (default) to 'SHA-1'

$RelyingPartyTrust = "YourRelyingPartyTrustName"
Set-ADFSRelyingPartyTrust -TargetName $RelyingPartyTrust -SignatureAlgorithm "http://www.w3.org/2000/09/xmldsig#rsa-sha1"