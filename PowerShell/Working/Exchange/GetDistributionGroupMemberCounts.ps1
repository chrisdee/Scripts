## Exchange Server: PowerShell Script to Get a Membership Count of Every Distribution Group ##

<#
.SYNOPSIS
GetDistributionGroupMemberCounts.ps1 - Get the member count of every distribution group

.DESCRIPTION 
This PowerShell script returns the member count of every distribution group
in the Exchange organization.

.OUTPUTS
Results are output to console and CSV.

.EXAMPLE
.\GetDistributionGroupMemberCounts.ps1
Creates the report of distribution group member counts with CSV file output to the location specified under the '-Path' parameter for 'Export-CSV'

.NOTES
Written by: Paul Cunningham

.LINK
https://practical365.com/exchange-server/get-distribution-group-member-counts-with-powershell/

Find me on:

* My Blog:	http://paulcunningham.me
* Twitter:	https://twitter.com/paulcunningham
* LinkedIn:	http://au.linkedin.com/in/cunninghamp/
* Github:	https://github.com/cunninghamp

For more Exchange Server tips, tricks and news
check out Exchange Server Pro.

* Website:	http://exchangeserverpro.com
* Twitter:	http://twitter.com/exchservpro

Change Log
V1.00, 8/9/2015 - Initial version
#>

#requires -version 2

[CmdletBinding()]
param ()


#...................................
# Variables
#...................................

$now = Get-Date											#Used for timestamps
$date = $now.ToShortDateString()						#Short date format for email message subject

$report = @()

$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path


#...................................
# Script
#...................................

#Add Exchange 2010 snapin if not already loaded in the PowerShell session
if (Test-Path $env:ExchangeInstallPath\bin\RemoteExchange.ps1)
{
	. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
	Connect-ExchangeServer -auto -AllowClobber
}
else
{
    Write-Warning "Exchange Server management tools are not installed on this computer."
    EXIT
}

#Set scope to entire forest
Set-ADServerSettings -ViewEntireForest:$true

#Get distribution groups
$distgroups = @(Get-DistributionGroup -ResultSize Unlimited)

#Process each distribution group
foreach ($dg in $distgroups)
{
    $count = @(Get-ADGroupMember -Recursive $dg.DistinguishedName).Count

    $reportObj = New-Object PSObject
    $reportObj | Add-Member NoteProperty -Name "Group Name" -Value $dg.Name
    $reportObj | Add-Member NoteProperty -Name "DN" -Value $dg.distinguishedName
    $reportObj | Add-Member NoteProperty -Name "Manager" -Value $dg.managedby.Name
    $reportObj | Add-Member NoteProperty -Name "Member Count" -Value $count

    Write-Host "$($dg.Name) has $($count) members"

    $report += $reportObj

}

$report | Export-CSV -Path $myDir\DistributionGroupMemberCounts.csv -NoTypeInformation -Encoding UTF8


#...................................
# Finished
#...................................