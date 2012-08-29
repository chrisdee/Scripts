## =====================================================================
## Title       : Get-MSSQL-ServerRegisterations
## Description : Exports current groups and servers
## Author      : Idera
## Date        : 1/28/2009
## Input       : $file -verbose -debug	
## Output      : 
## Usage			
## 	Function	: Get-MSSQL-ServerRegisterations($file)
##    Script	: PS> .\GetRegisteredSQLServers -file 'C:\Temp\File.txt' -verbose -debug
## Notes			:
## Tag			:
## Change Log  : Revised SMO Assemblies
##======================================================================
 
param
(
  	[string]$file = "C:\TEMP\SQLServerRegistrations.txt",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Get-MSSQL-ServerRegisterations $file
}

function Get-MSSQL-ServerRegisterations($file)
{
	#Dumps current SQL Server Enterprise Manager Groups and servers to specific
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Management.Common" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoExtended " );
	 
	$smoServers = new-object 'Microsoft.SqlServer.Management.Smo.Server' 
	$smoServers.Name

}

main