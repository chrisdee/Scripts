## =====================================================================
## Title       : Stop-SQLServerService
## Description : Stop SQL Server service for default instance
## Author      : Idera
## Date        : 6/27/2008
## Input       : -service <sqlserver service (MSSQLServer, MSSQL$Instance)
## 				  -verbose 
## 				  -debug	
## Output      : 
## Usage			: PS> .\Stop-SQLServerService -service MSSQLServer -verbose -debug
## Notes			: service
## Tag			:
## Change log  :
## =====================================================================
 
param
(
	[string]$service = "MSSQLServer",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Stop-SQLServerService $service
}

function Stop-SQLServerService()
{
	Stop-Service $service -Force
	Write-Host "$service service stopped"
}

main