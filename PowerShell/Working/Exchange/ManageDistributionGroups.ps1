## Exchange Server: PowerShell Script to Connect to an Exchange Server to View and Manage Distribution Lists ##

<#

Overview: This script allows users to do some simple distribution list management tasks via PowerShell. It is intended to be used by users with mailboxes that have been migrated to Office 365, but use distribution lists that are created on-premises and are synced via DirSync.

Usage: When prompted; provide the name of the Exchange Server (on-premises) you want to connect to manage DLs

Resource: https://gallery.technet.microsoft.com/Manage-DistributionLists-7a99268e

ManageDistributionLists
v1.7
1/2/2015
By Nathan O'Bryan
nathan@mcsmlab.com
http://www.mcsmlab.com

THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR 
RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

This script allows users to do some simple distribution list management
tasks via PowerShell.It is intended to be used by users with mailboxes
that have been migrated to Office 365, but use distribution lists that
are created on-premises and are synced via DirSync.
    
This script gives users menu driven options for managing distribution
lists.

This script runs inside regular a regular PowerShell 2.0 or greater session.

Users will require RBAC rights to distribution lists management cmdlets.

Change Log
1.5 - Added choice to preserve results from list of DLs or DL members on
screen in a notepad windows.
1.7 - General improvemets in PowerShell scripting. Added help and error handling.

#>

<#
.Synopsis
    This script allows users to do some simple distribution list management
    tasks via PowerShell.
.DESCRIPTION
    This script allows users to do some simple distribution list management
    tasks via PowerShell.It is intended to be used by users with mailboxes
    that have been migrated to Office 365, but use distribution lists that
    are created on-premises and are synced via DirSync.
    
    This script gives users menu driven options for managing distribution
    lists.
.EXAMPLE
    [1]  Display list of distribution groups
    [2]  Display members of a distribution group

    [3]  Add user to a distribution group
    [4]  Remove user from a distribution group

    [5]  Delete distribution group
    [6]  Create distribution group

    [7]  Exit
    Select an option [1-7]:
#>

[CmdletBinding()]
[string]$ExchangeServer
$Session
[boolean]$Loop
[VaildSet("1..7")][int]$Option
[VaildSet("Y", "N")][char]$Answer
[string]$DL
[string]$UserName

Clear-Host

$ExchangeServer = Read-Host "Type the FQDN of your Exchange server"

Write-Host "Connecting to $ExchangeServer"

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeServer/PowerShell/ -Authentication Kerberos

Import-PSSession $Session

Write-Host
Write-Host
Read-Host "Press Enter to continue..."

$Loop = $True
While ($Loop)
{
Clear-Host

Write-Host '[1]  Display list of distribution groups'
Write-Host '[2]  Display members of a distribution group'
Write-Host
Write-Host '[3]  Add user to a distribution group'
Write-Host '[4]  Remove user from a distribution group'
Write-Host
Write-Host '[5]  Delete distribution group'
Write-Host '[6]  Create distribution group'
Write-Host
Write-Host '[7]  Exit'

$Option = Read-Host "Select an option [1-7]"
Switch ($Option) 

{

1
{
Clear-Host

Write-Host '[1]  Display list of distribution groups'			  
Get-DistributionGroup  | Format-Table DisplayName, PrimarySmtpAddress -AutoSize

$Answer = Read-Host "Would you like a separate window opened listing your results? [Y/N]"

If ($Answer.ToUpper() -eq "Y")
{
Get-DistributionGroup $DL | Format-Table DisplayName, PrimarySmtpAddress -AutoSize | Out-File .\results.txt

Invoke-Item .\results.txt
}

Write-Host
Write-Host
Read-Host "Press Enter to continue..."
}

2
{
Clear-Host
 
Write-Host '[2]  Display members of a distribution group'

$DL = Read-Host "Type the distribution group name "

Get-DistributionGroupMember $DL | Format-Table Name, RecipientType -AutoSize

$Answer = Read-Host "Would you like a separate window opened listing your results? [Y/N]"

If ($Answer.ToUpper() -eq "Y")
{
Get-DistributionGroupMember $DL | Format-Table Name, RecipientType -AutoSize | Out-File .\results.txt

Invoke-Item .\results.txt
}

Write-Host
Write-Host
Read-Host "Press Enter to continue..."
}

3
{
Clear-Host

Write-Host '[3]  Add user to a distribution group'
$DL = Read-Host "Type the distribution group name "
$UserName = Read-Host "Type the user name "

Add-DistributionGroupMember -Identity $DL -Member $UserName

Write-Host
Write-Host
Read-Host "Press Enter to continue..."
}

4
{
CLear-Host

Write-Host '[4]  Remove user from a distribution group'
$DL = Read-Host "Type the distribution group name "
$UserName = Read-Host "Type the user name "

Remove-DistributionGroupMember -Identity $DL -Member $UserName

Write-Host
Write-Host
Read-Host "Press Enter to continue..."
}

5
{
Clear-Host

Write-Host '[5]  Delete distribution group'
$DL = Read-Host "Type the distribution group name "

Remove-DistributionGroup -Identity $DL

Write-Host
Write-Host
Read-Host "Press Enter to continue..."
}

6
{
Clear-Host

Write-Host '[6]  Create distribution group'
$DL  = Read-Host "Type the distribution group name " 

New-DistributionGroup -Name $DL

Write-Host
Write-Host
Read-Host "Press Enter to continue..."
}

7
{
Clear-Host

Write-Host "Your changes will show in Office 365 after the next DirSync is complete "
Write-Host "Pleae allow 3 hours "
Write-Host "Goodbye!"

Exit
}

}
}