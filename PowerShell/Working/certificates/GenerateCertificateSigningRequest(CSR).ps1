## PowerShell Script to generate a Certificate Signing Request (CSR) using the SHA256 (SHA-256) signature algorithm and a 2048 bit key size (RSA) via the Cert Request Utility (certreq) ##

<#

.SYNOPSIS
This powershell script can be used to generate a Certificate Signing Request (CSR) using the SHA256 signature algorithm and a 2048 bit key size (RSA). Subject Alternative Names are supported.

.DESCRIPTION
Tested platforms:
- Windows Server 2008R2 with PowerShell 2.0
- Windows 8.1 with PowerShell 4.0
- Windows 10 with PowerShell 5.0

Created By:
Reinout Segers

Resource: https://pscsr256.codeplex.com

Changelog
v1.1
- Added support for Windows Server 2008R2 and PowerShell 2.0
v1.0
- initial version
#>

####################
# Prerequisite check
####################
if (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Administrator priviliges are required. Please restart this script with elevated rights." -ForegroundColor Red
    Pause
    Throw "Administrator priviliges are required. Please restart this script with elevated rights."
}


#######################
# Setting the variables
#######################
$UID = [guid]::NewGuid()
$files = @{}
$files['settings'] = "$($env:TEMP)\$($UID)-settings.inf";
$files['csr'] = "$($env:TEMP)\$($UID)-csr.req"


$request = @{}
$request['SAN'] = @{}

Write-Host "Provide the Subject details required for the Certificate Signing Request" -ForegroundColor Yellow
$request['CN'] = Read-Host "Common Name (CN)"
$request['O'] = Read-Host "Organisation (O)"
$request['OU'] = Read-Host "Organisational Unit (OU)"
$request['L'] = Read-Host "Locality / City (L)"
$request['S'] = Read-Host "State (S)"
$request['C'] = Read-Host "Country Code (C)"

###########################
# Subject Alternative Names
###########################
$i = 0
Do {
$i++
    $request['SAN'][$i] = read-host "Subject Alternative Name $i (e.g. alt.company.com / leave empty for none)"
    if ($request['SAN'][$i] -eq "") {
    
    }
    
} until ($request['SAN'][$i] -eq "")

# Remove the last in the array (which is empty)
$request['SAN'].Remove($request['SAN'].Count)

#########################
# Create the settings.inf
#########################
$settingsInf = "
[Version] 
Signature=`"`$Windows NT`$ 
[NewRequest] 
KeyLength =  2048
Exportable = TRUE 
MachineKeySet = TRUE 
SMIME = FALSE
RequestType =  PKCS10 
ProviderName = `"Microsoft RSA SChannel Cryptographic Provider`" 
ProviderType =  12
HashAlgorithm = sha256
;Variables
Subject = `"CN={{CN}},OU={{OU}},O={{O}},L={{L}},S={{S}},C={{C}}`"
[Extensions]
{{SAN}}


;Certreq info
;http://technet.microsoft.com/en-us/library/dn296456.aspx
;CSR Decoder
;https://certlogik.com/decoder/
;https://ssltools.websecurity.symantec.com/checker/views/csrCheck.jsp
"

$request['SAN_string'] = & {
	if ($request['SAN'].Count -gt 0) {
		$san = "2.5.29.17 = `"{text}`"
"
		Foreach ($sanItem In $request['SAN'].Values) {
			$san += "_continue_ = `"dns="+$sanItem+"&`"
"
		}
		return $san
	}
}

$settingsInf = $settingsInf.Replace("{{CN}}",$request['CN']).Replace("{{O}}",$request['O']).Replace("{{OU}}",$request['OU']).Replace("{{L}}",$request['L']).Replace("{{S}}",$request['S']).Replace("{{C}}",$request['C']).Replace("{{SAN}}",$request['SAN_string'])

# Save settings to file in temp
$settingsInf > $files['settings']

# Done, we can start with the CSR
Clear-Host

#################################
# CSR TIME
#################################

# Display summary
Write-Host "Certificate information
Common name: $($request['CN'])
Organisation: $($request['O'])
Organisational unit: $($request['OU'])
City: $($request['L'])
State: $($request['S'])
Country: $($request['C'])

Subject alternative name(s): $($request['SAN'].Values -join ", ")

Signature algorithm: SHA256
Key algorithm: RSA
Key size: 2048

" -ForegroundColor Yellow

certreq -new $files['settings'] $files['csr'] > $null

# Output the CSR
$CSR = Get-Content $files['csr']
Write-Output $CSR
Write-Host "
"

# Set the Clipboard (Optional)
Write-Host "Copy CSR to clipboard? (y|n): " -ForegroundColor Yellow -NoNewline
if ((Read-Host) -ieq "y") {
	$csr | clip
	Write-Host "Check your ctrl+v
"
}


########################
# Remove temporary files
########################
$files.Values | ForEach-Object {
    Remove-Item $_ -ErrorAction SilentlyContinue
}