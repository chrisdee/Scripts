## Exchange Online: PowerShell Script to Disable the Creation of Office 365 Groups in Outlook Web Access ##

<#

Overview: PowerShell script to Get the current setting for Office 365 Groups set in the Outlook Web App mailbox policy, and then disables this to prevent the creation of Office 365 Groups

Usage: Only if different to the default o365 tenant policy; change the name/identity of the Outlook Web App mailbox policy variable under '$OwaMailboxPolicyName', and run the script

Note: If you want to Re-enable the creation of Office 365 Groups, just change the value after '-GroupCreationEnabled' to '$true'

Resources:

https://support.office.com/en-us/article/Use-PowerShell-to-manage-Office-365-Groups-Admin-help-aeb669aa-1770-4537-9de2-a82ac11b0540?ui=en-US&rs=en-US&ad=US

https://technet.microsoft.com/en-us/library/dd351097(v=exchg.150).aspx

#>

$OwaMailboxPolicyName = "OwaMailboxPolicy-Default" #Change this Policy to match your tenant if required

#$LiveCred = Get-Credential

$ExchangeCredential= Get-Credential

$Session=New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic –AllowRedirection

Import-PSSession $Session

## Get the current 'GroupCreationEnabled' property for the Outlook Web App mailbox policy
Get-OwaMailboxPolicy -Identity $OwaMailboxPolicyName | Select GroupCreationEnabled 

## Set the current 'GroupCreationEnabled' property for the Outlook Web App mailbox policy to 'False'
Set-OwaMailboxPolicy -Identity $OwaMailboxPolicyName -GroupCreationEnabled $false #Change this property to '$true' if you ever want to Re-enable this  

## Check the current 'GroupCreationEnabled' property for the Outlook Web App mailbox policy
Get-OwaMailboxPolicy -Identity $OwaMailboxPolicyName | Select GroupCreationEnabled 