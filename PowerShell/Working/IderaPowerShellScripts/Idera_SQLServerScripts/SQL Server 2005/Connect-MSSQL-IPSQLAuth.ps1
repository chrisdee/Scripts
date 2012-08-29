## =====================================================================
## Title       : Connect-MSSQL-IPSQLAuth
## Description : Connect to $ServerName using SQL Server authentication.
##               This connection is not encrypted. 
##               User ID and Password are transmitted in plain text.
## Author      : Idera
## Date        : 6/27/2008
## Input       : -ipAddress < xxx.xxx.xxx.xxx | xxx.xxx.xxx.xxx\instance >
##               -verbose 
##               -debug	
## Output      : Database names and owners
## Usage			: PS> .\Connect-MSSQL-IPSQLAuth -ipAddress 127.0.0.1 -verbose -debug
## Notes 		: 
##	Tag			: MSSQL, connect, IP, SQL Authentication
## Change Log  :
## =====================================================================
 
param
(
  	[string]$ipAddress = "127.0.0.1",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Connect-MSSQL-IPSQLAuth $ipAddress
}

function Connect-MSSQL-IPSQLAuth($ipAddress)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}
	
	# Load SMO assemblies
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlEnum")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
	
	# Instantiate a server object
	$smoServer = New-Object -typename Microsoft.SqlServer.Management.Smo.Server `
		-argumentlist "$ipAddress"
	
	# The connection will use SQL Authentication, so set LoginSecure to FALSE
	$smoServer.ConnectionContext.set_LoginSecure($FALSE)
	
	# Pop a credentials box to get User Name and Password
	$LoginCredentials = Get-Credential
	
	# If the user does not specify a domain, UserName will begin with a slash.
	# Remove leading slash from UserName
	$Login = $LoginCredentials.UserName -replace("\\","")
	
	# Set properties of ConnectionContext
	$smoServer.ConnectionContext.set_EncryptConnection($FALSE)
	$smoServer.ConnectionContext.set_Login($Login)
	$smoServer.ConnectionContext.set_SecurePassword($LoginCredentials.Password)
	
	# The connection is established the first time you access the server's properties.
	cls
	Write-Host Your connection string contains these values:
	Write-Host
	Write-Host $smoServer.ConnectionContext.ConnectionString.Split(";")
	Write-Host
	
	# List info about databases on the instance.
	Write-Host "Databases on $ipAddress "
	Write-Host
	foreach ($Database in $smoServer.Databases) 
	{
		write-host "Database Name : " $Database.Name
		write-host "Owner         : "	$Database.Owner
		write-host
	}
}

main
