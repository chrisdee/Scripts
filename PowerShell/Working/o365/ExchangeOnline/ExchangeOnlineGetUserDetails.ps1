## Exchange Online: PowerShell Script to Get User Account Details ##

$ExchangeCredential= Get-Credential

$Session=New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic –AllowRedirection

Import-PSSession $Session

#Getting a Full List of the User details
Get-User -Identity "UserName" | fl #Provide your user name for the '-Identity' parameter

#Getting a Filtered List of the User details
#Get-User -Identity "UserName" | ft  identity, whenCreated, whenChanged #Provide your user name for the '-Identity' parameter, along with any additional properties

#Remove-PSSession $Session