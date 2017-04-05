## Exchange Online: PowerShell Script to Get a List of All Distribution Groups and Members in an Exchange Online (o365) Tenant into a CSV Report ##

<#

Overview: PowerShell Script to Get a List of All Distribution Groups and their Members in an Exchange Online (o365) Tenant, with CSV file output functionality

Resource: https://www.cogmotive.com/blog/powershell/list-all-users-and-their-distribution-group-membership-in-office-365

Usage: Edit the following variable and run the script like the usage example below: '$OutputFile'

Usage Example:

.\ExchangeOnlineGetDistributionGroupMembers.ps1 -Office365Username "admin@xxxxxx.onmicrosoft.com" -Office365Password "Password123"


#>

  
#Accept input parameters  
Param(  
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $Office365Username,  
    [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]  
    [string] $Office365Password  
)  
  
#Constant Variables  
$OutputFile = "DistributionGroupMembers.csv"   #The CSV Output file that is created, change for your purposes  
$arrDLMembers = @{}  
  
 
#Remove all existing Powershell sessions  
Get-PSSession | Remove-PSSession  
  
#Did they provide creds?  If not, ask them for it. 
if (([string]::IsNullOrEmpty($Office365Username) -eq $false) -and ([string]::IsNullOrEmpty($Office365Password) -eq $false)) 
{ 
    $SecureOffice365Password = ConvertTo-SecureString -AsPlainText $Office365Password -Force      
      
    #Build credentials object  
    $Office365Credentials  = New-Object System.Management.Automation.PSCredential $Office365Username, $SecureOffice365Password  
} 
else 
{ 
    #Build credentials object  
    $Office365Credentials  = Get-Credential 
} 
#Create remote Powershell session  
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Office365credentials -Authentication Basic –AllowRedirection          
 
#Import the session  
Import-PSSession $Session -AllowClobber | Out-Null           
  
#Prepare Output file with headers  
Out-File -FilePath $OutputFile -InputObject "Distribution Group DisplayName,Distribution Group Email,Member DisplayName,Member Email,Member Type,Member Count" -Encoding UTF8  
  
#Get all Distribution Groups from Office 365  
$objDistributionGroups = Get-DistributionGroup -ResultSize Unlimited  
  
#Iterate through all groups, one at a time      
Foreach ($objDistributionGroup in $objDistributionGroups)  
{      
     
    write-host "Processing $($objDistributionGroup.DisplayName)..."  
  
    #Get members of this group  
    $objDGMembers = Get-DistributionGroupMember -Identity $($objDistributionGroup.PrimarySmtpAddress)  
      
    write-host "Found $($objDGMembers.Count) members..."  
      
    #Iterate through each member  
    Foreach ($objMember in $objDGMembers)  
    {  
        Out-File -FilePath $OutputFile -InputObject "$($objDistributionGroup.DisplayName),$($objDistributionGroup.PrimarySMTPAddress),$($objMember.DisplayName),$($objMember.PrimarySMTPAddress),$($objMember.RecipientType),$($objDGMembers.Count)" -Encoding UTF8 -append  
        write-host "`t$($objDistributionGroup.DisplayName),$($objDistributionGroup.PrimarySMTPAddress),$($objMember.DisplayName),$($objMember.PrimarySMTPAddress),$($objMember.RecipientType),$($objDGMembers.Count)" 
    }  
}  
 
#Clean up session  
Get-PSSession | Remove-PSSession  