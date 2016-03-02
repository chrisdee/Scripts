## Exchange Online: PowerShell Script to Get Mail Box Statistics / Sizes for All MS Exchange Online Mail Boxes Or those listed in a Text Input File (o365)  ##

################################################################################################################################################################
# Parameters: Script accepts 3 parameters from the command line
#
# Office365Username - Mandatory - Administrator login ID for the tenant we are querying
# Office365Password - Mandatory - Administrator login password for the tenant we are querying
# InputFile - Optional - Path and File name of file full of UserPrincipalNames we want the Mailbox Size for.  Seperated by New Line, no header.
#
# Reports on: Number of Mail Box Items, and Mail Box Size (MB)
#
# Usage Example:
#
# .\ExchangeOnlineGetMailBoxStatistics.ps1 -Office365Username "admin@xxxxxx.onmicrosoft.com" -Office365Password "Password123" -InputFile "c:\Files\InputFile.txt"
#
# NOTE: If you do not pass an input file to the script, it will return the sizes of ALL mailboxes in the tenant.  Not advisable for tenants with large
# user count (< 3,000) 
#
# Author: 				Alan Byrne
# Version: 				1.0
# Last Modified Date: 	19/08/2012
# Last Modified By: 	Alan Byrne
################################################################################################################################################################

#Accept input parameters
Param(
	[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Office365Username,
	[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
    [string] $Office365Password,	
	[Parameter(Position=2, Mandatory=$false, ValueFromPipeline=$true)]
    [string] $InputFile
)

#Constant Variables
$OutputFile = "MailboxSizes.csv"   #The CSV Output file that is created, change this to match your environment


#Main
Function Main {

	#Remove all existing Powershell sessions
	Get-PSSession | Remove-PSSession
	
	#Call ConnectTo-ExchangeOnline function with correct credentials
	ConnectTo-ExchangeOnline -Office365AdminUsername $Office365Username -Office365AdminPassword $Office365Password			
	
	#Prepare Output file with headers
	Out-File -FilePath $OutputFile -InputObject "UserPrincipalName,NumberOfItems,MailboxSize" -Encoding UTF8
	
	#Check if we have been passed an input file path
	if ($InputFile -ne "")
	{
		#We have an input file, read it into memory
		$objUsers = import-csv -Header "UserPrincipalName" $InputFile
	}
	else
	{
		#No input file found, gather all mailboxes from Office 365
		$objUsers = get-mailbox -ResultSize Unlimited | select UserPrincipalName
	}
	
	#Iterate through all users	
	Foreach ($objUser in $objUsers)
	{	
		#Connect to the users mailbox
		$objUserMailbox = get-mailboxstatistics -Identity $($objUser.UserPrincipalName) | Select ItemCount,TotalItemSize
		
		#Prepare UserPrincipalName variable
		$strUserPrincipalName = $objUser.UserPrincipalName
		
		#Get the size and item count
		$ItemSizeString = $objUserMailbox.TotalItemSize.ToString()

		$strMailboxSize = "{0:N2}" -f ($ItemSizeString.SubString(($ItemSizeString.IndexOf("(") + 1),($itemSizeString.IndexOf(" bytes") - ($ItemSizeString.IndexOf("(") + 1))).Replace(",","")/1024/1024)

		$strItemCount = $objUserMailbox.ItemCount
		
		
		#Output result to screen for debuging (Uncomment to use)
		#write-host "$strUserPrincipalName : $strLastLogonTime"
		
		#Prepare the user details in CSV format for writing to file
		$strUserDetails = "$strUserPrincipalName,$strItemCount,$strMailboxSize"
		
		#Append the data to file
		Out-File -FilePath $OutputFile -InputObject $strUserDetails -Encoding UTF8 -append
	}
	
	#Clean up session
	Get-PSSession | Remove-PSSession
}

###############################################################################
#
# Function ConnectTo-ExchangeOnline
#
# PURPOSE
#    Connects to Exchange Online Remote PowerShell using the tenant credentials
#
# INPUT
#    Tenant Admin username and password.
#
# RETURN
#    None.
#
###############################################################################
function ConnectTo-ExchangeOnline
{   
	Param( 
		[Parameter(
		Mandatory=$true,
		Position=0)]
		[String]$Office365AdminUsername,
		[Parameter(
		Mandatory=$true,
		Position=1)]
		[String]$Office365AdminPassword

    )
		
	#Encrypt password for transmission to Office365
	$SecureOffice365Password = ConvertTo-SecureString -AsPlainText $Office365AdminPassword -Force    
	
	#Build credentials object
	$Office365Credentials  = New-Object System.Management.Automation.PSCredential $Office365AdminUsername, $SecureOffice365Password
	
	#Create remote Powershell session
	$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Office365credentials -Authentication Basic –AllowRedirection    	

	#Import the session
    Import-PSSession $Session -AllowClobber | Out-Null
}


# Start script
. Main