###################################################################################################################################
#
# Name: SP2010CreateServiceAccountsFromCSV.ps1
# Author: Chris Dee
# Version: 1.0
# Date: 28/09/2011
# Comment: PowerShell 2.0 script to bulk create AD accounts from a csv file
# Usage: Fill in the 'Template' CSV file and edit the following 2 variables to suit your environment: '$TargetOU'; '$ImportFile'
# Resources: http://www.open-a-socket.com/index.php/2010/12/29/bulk-create-sample-ad-users-from-csv-file-using-powershell/
#			 http://sites.wizdim.com/andersrask/powershell/creating-your-sharepoint-service-accounts-using-powershell-on-r2/
#			 http://dotnetmafia.sys-con.com/node/1457593/mobile
#
####################################################################################################################################

# Function to test the existence of an AD object
function Test-XADObject() {
   [CmdletBinding(ConfirmImpact="Low")]
   Param (
      [Parameter(Mandatory=$true,
                 Position=0,
                 ValueFromPipeline=$true,
                 HelpMessage="Identity of the AD object to verify if exists or not."
                )]
      [Object] $Identity
   )
   trap [Exception] {
      return $false
   }
   $auxObject = Get-ADObject -Identity $Identity
   return $true
}

# Import the Active Directory Powershell Module (Requires a server or work station with the ActiveDirectory module installed)
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

# Specify the target OU for new users (You can use the distinguishedName DN attribute to obtain this)
$TargetOU = "CN=Managed Service Accounts,DC=devdom,DC=com"

# Find the current domain info
$domdns = (Get-ADDomain).dnsroot # for UPN generation

# Specify the folder and CSV file to use
$ImportFile = "C:\Boxbuild\Scripts\PowerShell\Working\SharePoint\SharePoint2010\SP2010CreateServiceAccounts\SP2010CreateServiceAccountsFromCSVTemplate.csv" #Change this directory to suit your environment

# Check if the target OU is valid
$ValidOU = Test-XADObject $TargetOU
If (!$ValidOU)

{
 Write-Host "Error: Specified OU for new accounts does not appear to exist - exiting..."
 exit
} 

#Set the same password for all accounts - Use this option if you want the same password for each account
#$password = read-host "Enter password" -assecurestring

# Parse the import file and action each line - Select, Add, and Edit variables to match your CSV file
$users = Import-CSV $ImportFile
foreach ($user in $users)
{
$SamAccountName = $user.samaccountname
$DisplayName = $user.displayname
$GivenName = $user.givenname
$Description = $user.description
$UserPrincipalName = "$SamAccountName" + "@" +"$domdns"
#Use passwords from within the CSV file - Use this option if you want individual passwords for each account
$password = ConvertTo-SecureString $user.password -AsPlainText –Force
#Now provision your accounts (Reference: http://technet.microsoft.com/en-us/library/ee617253.aspx)
New-ADUser –Name $DisplayName –SamAccountName $SamAccountName –DisplayName $DisplayName `
-givenname $GivenName -description $Description -userprincipalname $UserPrincipalName `
-Path $TargetOU –Enabled $true -AccountPassword $password `
–ChangePasswordAtLogon $false -CannotChangePassword $true -PasswordNeverExpires $true #-WhatIf
}

Write-Host "Accounts should have been created, please check the $TargetOU container to make sure"