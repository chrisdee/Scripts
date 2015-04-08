## PowerShell: Functions to store Credentials as Encrypted Secure Strings for re-use in Credential Parameters ##

<#

Overview: Functions to Export Credentials to a secure string in an XML to be used for 'Get' commands where Credential parameters can be provided

Usage:

The first time the script is run if a credential file doesn't exist yet in the '$CredentialFile' variable path; the 'Export-Credential' function will open a window requesting the credentials to be stored as a Secure String
When you want to use the stored credentials; calling the 'Get-MyCredential' function should retrieve these credentials from the '$CredentialFile' variable path

# Checking the 'UserName' credentials stored in the '$CredentialFile'

Get-MyCredential -CredPath $CredentialFile

# Using credentials stored in the '$CredentialFile' in a script

$Credentials = Get-MyCredential -CredPath $CredentialFile

Invoke-Command -ComputerName YourMachineName -ScriptBlock {hostname} -Credential $Credentials

# Calling the 'Get-MyCredential' function via the Dot Source (dot-source) method from another script

. "C:\BoxBuild\EncryptedCredentialsFunctions.ps1"

$Credentials = Get-MyCredential -CredPath $CredentialFile

Invoke-Command -ComputerName YourMachineName -ScriptBlock {hostname} -Credential $Credentials

#>

### Start Variables ###
$CredentialFile = "C:\BoxBuild\EncryptedCredentials.xml" #Change this to match your environment
### End Variables ###

#=====================================================================
# Export-Credential
# Usage: Export-Credential $CredentialObject $FileToSaveTo
#=====================================================================
function Export-Credential($cred, $path) {
      $cred = $cred | Select-Object *
      $cred.password = $cred.Password | ConvertFrom-SecureString
      $cred | Export-Clixml $path
}

#=====================================================================
# Get-MyCredential
#=====================================================================
function Get-MyCredential
{
param(
$CredPath,
[switch]$Help
)
$HelpText = @"

    Get-MyCredential
    Usage:
    Get-MyCredential -CredPath `$CredPath

    If a credential is stored in $CredPath, it will be used.
    If no credential is found, Export-Credential will start and offer to
    Store a credential at the location specified.

"@
    if($Help -or (!($CredPath))){write-host $Helptext; Break}
    if (!(Test-Path -Path $CredPath -PathType Leaf)) {
        Export-Credential (Get-Credential) $CredPath
    }
    $cred = Import-Clixml $CredPath
    $cred.Password = $cred.Password | ConvertTo-SecureString
    $Credential = New-Object System.Management.Automation.PsCredential($cred.UserName, $cred.Password)
    Return $Credential
}

Get-MyCredential -CredPath $CredentialFile

