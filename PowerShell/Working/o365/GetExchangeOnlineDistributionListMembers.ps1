## MSOnline: PowerShell Script to Connect to Exchange Online and Get Distribution Lists Group Members (o365) ##

## Overview: Script that connects to Office 365 Exchange Online and retrieves Distribution Lists Group Members

## Usage: Change the '-Identity' parameter for the 'Get-DistributionGroup' to match a specific group or multiple groups with the wild card '*' asterix

## Resource: http://www.lazywinadmin.com/2015/08/powershello365-get-distribution-groups.html#more

Import-PSSession $(New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Authentication Basic -AllowRedirection -Credential $(Get-Credential))

(Get-DistributionGroup -Identity 'GroupName*').identity | ForEach-Object{
    $DistributionGroupName = $_
    Get-DistributionGroupMember -Identity $_ | ForEach-Object{
        [PSCustomObject]@{
            DistributionGroup = $DistributionGroupName
            MemberName = $_.Name
	    EmailAddress =$_.primarysmtpaddress
            #Other recipientproperties here
        }
    }
}
    