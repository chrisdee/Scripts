## =====================================================================
## Title       : Get-MSSQL-Port-UsingDMO
## Description : Retrieve SQL Server port configured for use
## Author      : Idera
## Date        : 9/1/2008
## Input       : -serverInstance <server\instance> 
## 				  -verbose 
## 				  -debug	
## Output      : SQL Server port #
## Usage			: PS> .\Get-MSSQL-Port-UsingDMO -serverInstance MyServer -verbose -debug
## Notes			: Adapted from Jakob Bindslet script
## Tag			: SQL Server, DMO, Port, Configuration
## Change log  :
## =====================================================================
 
param
(
  	[string]$serverInstance,
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Get-MSSQL-Port-UsingDMO $serverInstance
}

function Get-MSSQL-Port-UsingDMO($serverInstance)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}

	# TIP: using PowerShell to instantiate a COM object
	$server = New-Object -comobject "SQLDMO.SQLServer"
	
	# Securely login to server instance and retrieve TCPPORT setting
	$server.loginsecure = $TRUE
	$server.connect($serverInstance)
	$server.registry.tcpport
	$server.close() 
}

main