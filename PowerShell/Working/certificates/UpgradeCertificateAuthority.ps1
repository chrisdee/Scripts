## PowerShell Script to Upgrade a Windows Server Certificate Authority (CA) from CSP to KSP and from SHA-1 to SHA-256 ##

<#

Synopsis: PowerShell Script that backs up a Certification Authority (CA) and migrates the CA from CSP (Microsoft Strong Cryptographic Provider) to KSP (Microsoft Software Key Storage Provider), and from SHA-1 to SHA-256

Overview: PowerShell script that takes a backup of a Certification Authority (CA) database files and Cert Authority 'Root' CA certificate', along with the CA configuration settings registry key, and then migrates the CA from CSP to KSP, and from SHA-1 to SHA-256

Note: If your CA is already set to KSP (Microsoft Software Key Storage Provider) and you want to change the 'CNGHashAlgorithm' to 'SHA256'; you should only neeed to run the command below. New certs created moving forward will use the 'SHA256' Hash Algorithm

certutil -setreg ca\csp\CNGHashAlgorithm SHA256

Resources:

https://blogs.technet.microsoft.com/heyscriptingguy/2016/02/15/migrate-windows-ca-from-csp-to-ksp-and-from-sha-1-to-sha-256-part-1/

http://www.workingsysadmin.com/quick-script-share-upgrade-windows-certificate-authority-from-csp-to-ksp-and-from-sha-1-to-sha-256/

#>

#requires -Version 2
#requires -RunAsAdministrator
$OldEAP = $ErrorActionPreference
$ErrorActionPreference = 'stop'
 
Function Add-LogEntry
{
    [CmdletBinding()] 
    Param( 
        [Parameter(Position = 0, 
                Mandatory = $True, 
        ValueFromPipeline = $True)] 
        [string]$LogLocation, 
        [Parameter(Position = 1, 
                Mandatory = $True, 
        ValueFromPipeline = $True)] 
        [string]$LogMessage 
    )
    $LogThis = "$(Get-Date -Format 'MM/dd/yyyy hh:mm:ss'): $LogMessage"
    $LogThis | Out-File -FilePath $LogLocation -Append
    write-output $LogThis
}
 
Write-Output -InputObject @"
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: This script will migrate CA keys from CSP to KSP and set up SHA256 for cert signing.
:: 
:: It will only work on Windows Server 2012 or 2012 R2 where the CA is configured with CSP.
:: (It won't work on Server 2008 R2)
::
:: Use CTRL+C to kill
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: 
 
"@
 
#region Stage 1 - Set Variables
$Password = Read-Host -Prompt 'Set password for key backup (not stored in script as securestring)'
 
$Drivename = Read-Host -Prompt 'Set drive letter including colon [C:]'
if ([string]::IsNullOrWhiteSpace($Drivename)) 
{
    $Drivename = 'C:' 
}
 
$Foldername = Read-Host -Prompt "Set folder name [CA-KSPMigration_$($env:computername)]"
if ([string]::IsNullOrWhiteSpace($Foldername)) 
{
    $Foldername = "CA-KSPMigration_$($env:computername)" 
}
 
if (Test-Path -Path "$Drivename\$Foldername") 
{
    Remove-Item -Path "$Drivename\$Foldername" -Recurse -Force 
}
New-Item -ItemType Directory -Path "$Drivename\$Foldername"
 
$CAName = cmd.exe /c 'certutil.exe -cainfo name'
$CAName = $CAName[0].split(' ')[-1]
 
$Logpath = Read-Host -Prompt "Set log path [$($Drivename)\$($Foldername)\log.txt]"
if ([string]::IsNullOrWhiteSpace($Logpath)) 
{
    $Logpath = "$($Drivename)\$($Foldername)\log.txt" 
}
 
Add-LogEntry $Logpath 'Variables configured'
Add-LogEntry $Logpath "Password: $($Password)"
Add-LogEntry $Logpath "Drivename: $($Drivename)"
Add-LogEntry $Logpath "Foldername: $($Foldername)"
Add-LogEntry $Logpath "CAName: $($CAName)"
Add-LogEntry $Logpath "Logpath: $($Logpath)"
#endregion
 
#region Stage 2 - Backup Existing CA
try
{
    Add-LogEntry $Logpath 'Performing full CA backup'
 
    cmd.exe /c "certutil -p $($Password) -backup $("$Drivename\$Foldername")"
    Add-LogEntry $Logpath 'Saved CA database and cert'
 
    cmd.exe /c "reg export hklm\system\currentcontrolset\services\certsvc\configuration $("$Drivename\$Foldername")\CA_Registry_Settings.reg /y"
    Add-LogEntry $Logpath 'Saved reg keys'
 
    Copy-Item -Path 'C:\Windows\System32\certsrv\certenroll\*.crl' -Destination "$Drivename\$Foldername"
    Add-LogEntry $Logpath 'Copied CRL files'
 
    cmd.exe /c 'certutil -catemplates' | Out-File -FilePath "$Drivename\$Foldername\Published_templates.txt"
    Add-LogEntry $Logpath 'Got list of published cert templates'
    
    Add-LogEntry $Logpath 'Finished full CA backup'
}
catch [Exception]
{
    Add-LogEntry $Logpath "*** Activity failed - Exception Message: $($_.Exception.Message)"
    Exit-PSHostProcess
}
#endregion
 
#region Stage 3 - Delete existing certs and keys
try
{
    Stop-Service -Name 'certsvc'
    Add-LogEntry $Logpath 'CA service stopped'
    
    $CertSerial = cmd.exe /c "certutil -store My $("$CAName")" | Where-Object -FilterScript {
        $_ -match 'hash' 
    }
    $CertSerial | Out-File -FilePath "$Drivename\$Foldername\CA_Certificates.txt"
    Add-LogEntry $Logpath 'Got CA cert serials'
    
    $CertProvider = cmd.exe /c "certutil -store My $("$CAName")" | Where-Object -FilterScript {
        $_ -match 'provider' 
    }
    $CertProvider | Out-File -FilePath "$Drivename\$Foldername\CSP.txt"
    Add-LogEntry $Logpath 'Got CA CSPs'
    
    $CertSerial | ForEach-Object -Process {
        cmd.exe /c "certutil -delstore My `"$($_.Split(':')[-1].trim(' '))`"" 
    }
    Add-LogEntry $Logpath 'Deleted CA certificates'
    
    $CertProvider | ForEach-Object -Process {
        cmd.exe /c "certutil -CSP `"$($_.Split('=')[-1].trim(' '))`" -delkey $("$CAName")" 
    }
    Add-LogEntry $Logpath 'Deleted CA private keys'
}
catch [Exception]
{
    Add-LogEntry $Logpath "*** Activity failed - Exception Message: $($_.Exception.Message)"
    Exit-PSHostProcess
}
#endregion
 
#region Stage 4 - Import keys in KSP and restore to CA
try
{
    cmd.exe /c "certutil -p $Password -csp `"Microsoft Software Key Storage Provider`" -importpfx `"$("$Drivename\$Foldername\$CAName.p12")`""
    Add-LogEntry $Logpath 'Imported CA cert and keys into KSP'
    
    cmd.exe /c "certutil -exportpfx -p $Password My $("$CAName") `"$("$Drivename\$Foldername\NewCAKeys.p12")`""
    Add-LogEntry $Logpath 'Exported keys so they can be installed on the CA'
    
    cmd.exe /c "certutil -p $Password -restorekey `"$("$Drivename\$Foldername\NewCAKeys.p12")`""
    Add-LogEntry $Logpath 'Restored keys into CA'
}
catch [Exception]
{
    Add-LogEntry $Logpath "*** Activity failed - Exception Message: $($_.Exception.Message)"
    Exit-PSHostProcess
}
#endregion
 
#region Stage 5 - Create and import required registry settings
try
{
    $CSPreg = @"
    Windows Registry Editor Version 5.00
    [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$CAName\CSP]
    "CNGHashAlgorithm"="SHA256"
    "CNGPublicKeyAlgorithm"="RSA"
    "HashAlgorithm"=dword:ffffffff
    "MachineKeyset"=dword:00000001
    "Provider"="Microsoft Software Key Storage Provider"
    "ProviderType"=dword:00000000
"@
    $CSPreg | Out-File -FilePath "$Drivename\$Foldername\csp.reg"
    Add-LogEntry $Logpath 'Created csp.reg'
    
    $Encryptionreg = @"
    Windows Registry Editor Version 5.00
    [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$CAName\EncryptionCSP]
    "CNGEncryptionAlgorithm"="3DES"
    "CNGPublicKeyAlgorithm"="RSA"
    "EncryptionAlgorithm"=dword:6603
    "MachineKeyset"=dword:00000001
    "Provider"="Microsoft Software Key Storage Provider"
    "ProviderType"=dword:00000000
    "SymmetricKeySize"=dword:000000a8
"@
    $Encryptionreg | Out-File -FilePath "$Drivename\$Foldername\encryption.reg"
    Add-LogEntry $Logpath 'Created encryption.reg'
}
catch [Exception]
{
    Add-LogEntry $Logpath "*** Activity failed - Exception Message: $($_.Exception.Message)"
    Exit-PSHostProcess
}
 
$ErrorActionPreference = 'SilentlyContinue'
 
cmd.exe /c "reg import $("$Drivename\$Foldername\encryption.reg")"
Add-LogEntry $Logpath 'Imported encryption.reg'
 
cmd.exe /c "reg import $("$Drivename\$Foldername\csp.reg")"
Add-LogEntry $Logpath 'Imported csp.reg'
 
Start-Service -Name 'certsvc'
Add-LogEntry $Logpath 'Started certsvc'
 
 
#endregion
 
$ErrorActionPreference = $OldEAP