## =====================================================================
## Title       : Start-SQLServerService
## Description : Start SQL Server service for default instance
## Author      : Idera
## Date        : 6/27/2008
## Input       : -service <sqlserver service (MSSQLServer, MSSQL$Instance)
## 				  -verbose 
## 				  -debug	
## Output      : 
## Usage			: PS> .\Start-SQLServerService -service MSSQLServer -verbose -debug
## Notes			:
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
	Start-SQLServerService $service
}

function Start-SQLServerService()
{
	Start-Service $service
	Write-Host "$service service started"
}

main