<# PowerShell: Script To Connect To MS Online (o365) And Get A CSV Report On User Licenses Assigned To Accounts

Overview: The script below takes credentials for a MS Online office 365 account and stores these in specified text files
for reuse (password one is encrypted). These credentials are then used to connect to the MS Online portal, and then queries
and reports on each user account that has licenses associated against them. The user accounts and license details are exported
to a CSV file.

Usage: Make sure that the environment you run this script from has met the 'Key requirements' specified below. Edit the following
variables, if needed, to suit your requirements: '$UserNameFileLocation'; '$PasswordFileLocation'; '$LogFile'. Save and run your
script.

Important: If you want to rerun the script using the same credentials (e.g. for a scheduled task); run it once and then
comment out the two 'Read-Host' prompt lines for the 'username' and 'password' below.

Key requirements for this script:

- The 'Microsoft Online Services Sign-In Assistant' is installed
- The 'Microsoft Online Services Module for Windows PowerShell' is installed
- The MS Online account used is a member of the 'Global administrators' role group (password should be set to not expire)

Sample command to set a MS Online account password not to expire:

Set-MsolUser –UserPrincipalName UserName@YourDomain.onmicrosoft.com -PasswordNeverExpires $True

Script Resource: http://gallery.technet.microsoft.com/scriptcenter/Export-a-Licence-b200ca2a#content

#>

# Section that takes input for the MS Online admin account and stores these credentials in text files for reuse
$UserNameFileLocation = "o365user.txt" #Change the path here to suit your environment
$PasswordFileLocation = "o365password.txt" #Change the path here to suit your environment
Read-Host "Please enter your o365 admin account username" | Out-File $UserNameFileLocation
Read-Host "Please enter your o365 admin account password" -AsSecureString | ConvertFrom-SecureString | Out-File $PasswordFileLocation
$o365Account = Get-Content $UserNameFileLocation
$o365AccountPassword = Get-Content $PasswordFileLocation | ConvertTo-SecureString
$o365AccountCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $o365Account,$o365AccountPassword

# Define Hashtables for lookup
$Sku = @{
	"DESKLESSPACK" = "Office 365 (Plan K1)"
	"DESKLESSWOFFPACK" = "Office 365 (Plan K2)"
	"LITEPACK" = "Office 365 (Plan P1)"
	"EXCHANGESTANDARD" = "Office 365 Exchange Online Only"
	"STANDARDPACK" = "Office 365 (Plan E1)"
	"STANDARDWOFFPACK" = "Office 365 (Plan E2)"
	"ENTERPRISEPACK" = "Office 365 (Plan E3)"
	"ENTERPRISEPACKLRG" = "Office 365 (Plan E3)"
	"ENTERPRISEWITHSCAL" = "Office 365 (Plan E4)"
	"STANDARDPACK_STUDENT" = "Office 365 (Plan A1) for Students"
	"STANDARDWOFFPACKPACK_STUDENT" = "Office 365 (Plan A2) for Students"
	"ENTERPRISEPACK_STUDENT" = "Office 365 (Plan A3) for Students"
	"ENTERPRISEWITHSCAL_STUDENT" = "Office 365 (Plan A4) for Students"
	"STANDARDPACK_FACULTY" = "Office 365 (Plan A1) for Faculty"
	"STANDARDWOFFPACKPACK_FACULTY" = "Office 365 (Plan A2) for Faculty"
	"ENTERPRISEPACK_FACULTY" = "Office 365 (Plan A3) for Faculty"
	"ENTERPRISEWITHSCAL_FACULTY" = "Office 365 (Plan A4) for Faculty"
	"ENTERPRISEPACK_B_PILOT" = "Office 365 (Enterprise Preview)"
	"STANDARD_B_PILOT" = "Office 365 (Small Business Preview)"
	}
		
# The Output will be written to this file in the current working directory
$LogFile = "Office_365_Licenses.csv" #Change this file name here to suit your environment

# Connect to Microsoft Online
Import-Module MSOnline
Connect-MsolService -Credential $o365AccountCredentials

write-host "Connecting to Office 365..."

# Get a list of all licences that exist within the tenant
$licensetype = Get-MsolAccountSku | Where {$_.ConsumedUnits -ge 1}

# Loop through all licence types found in the tenant
foreach ($license in $licensetype) 
{	
	# Build and write the Header for the CSV file
	$headerstring = "DisplayName,UserPrincipalName,AccountSku"
	
	foreach ($row in $($license.ServiceStatus)) 
	{
		
		# Build header string
		switch -wildcard ($($row.ServicePlan.servicename))
		{
			"EXC*" { $thisLicence = "Exchange Online" }
			"MCO*" { $thisLicence = "Lync Online" }
			"LYN*" { $thisLicence = "Lync Online" }
			"OFF*" { $thisLicence = "Office Profesional Plus" }
			"SHA*" { $thisLicence = "Sharepoint Online" }
			"*WAC*" { $thisLicence = "Office Web Apps" }
			"WAC*" { $thisLicence = "Office Web Apps" }
			default { $thisLicence = $row.ServicePlan.servicename }
		}
		
		$headerstring = ($headerstring + "," + $thisLicence)
	}
	
	Out-File -FilePath $LogFile -InputObject $headerstring -Encoding UTF8
	
	write-host ("Gathering users with the following subscription: " + $license.accountskuid)

	# Gather users for this particular AccountSku
	$users = Get-MsolUser -all | where {$_.isLicensed -eq "True" -and $_.licenses[0].accountskuid.tostring() -eq $license.accountskuid}

	# Loop through all users and write them to the CSV file
	foreach ($user in $users) {
		
		write-host ("Processing " + $user.displayname)

		$datastring = ($user.displayname + "," + $user.userprincipalname + "," + $Sku.Item($user.licenses[0].AccountSku.SkuPartNumber))
		
		foreach ($row in $($user.licenses[0].servicestatus)) {
			
			# Build data string
			$datastring = ($datastring + "," + $($row.provisioningstatus))
			}
		
		Out-File -FilePath $LogFile -InputObject $datastring -Encoding UTF8
		
	}
}			

write-host ("Script Completed.  Results available in " + $LogFile)