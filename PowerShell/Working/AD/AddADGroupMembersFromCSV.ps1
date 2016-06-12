## Active Directory: PowerShell Script to Add and Remove Users from AD Security Groups based on CSV File ##

<#

Overview: PowerShell Script to Add and Remove Users from AD Security Groups based on CSV File Input

Usage: 

Create a CSV file with columns like the example below. 1st column for your 'adusers' SAM account names, and additional columns for the Security Groups
Add an 'x' value in each Security Group column you want the SAM account name to be a member of
Users will be removed from Security Groups they are already members of if no 'x' value is provided

adusers Test Group    Test Group 1    Test Group 2    Test Group 3
------- ------------- --------------- --------------- ---------------
User1    x             x               x                              
User2                  x               x               x 

Resource: http://mikefrobbins.com/2016/02/25/use-powershell-to-add-active-directory-users-to-specific-groups-based-on-a-csv-file

#>

Import-Module ActiveDirectory

$FilePath = "C:\tmp\UserGroups.csv"

Import-Csv -Path $FilePath | Format-Table

$Header = ((Get-Content -Path $FilePath -TotalCount 1) -split ',').Trim()
$Users = Import-Csv -Path $FilePath
foreach ($Group in $Header[1..($Header.Count -1)]) {
    Add-ADGroupMember -Identity $Group -Members ($Users | Where-Object $Group -eq 'X' | Select-Object -ExpandProperty $Header[0])
    Remove-ADGroupMember -Identity $Group -Members ($Users | Where-Object $Group -ne 'X' | Select-Object -ExpandProperty $Header[0]) -Confirm:$false
}