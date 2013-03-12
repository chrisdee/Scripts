## ADFS Server: Useful Powershell Commandlets To Run On Your ADFS Server ##

Add-PSSnapin “microsoft.adfs.powershell” -ErrorAction SilentlyContinue

# Get ADFS Configuration Properties

Get-ADFSProperties

# Enable or Disable Auto Certificate Rollover

Set-ADFSProperties -AutoCertificateRollover $true
Set-ADFSProperties -AutoCertificateRollover $false

# Set ADFS Self-Signed Certificates Duration

Set-AdfsProperties -CertificateDuration 730 #Specify number of days

# Update ADFS Self-Signed Certificates

Update-AdfsCertificate -Urgent
