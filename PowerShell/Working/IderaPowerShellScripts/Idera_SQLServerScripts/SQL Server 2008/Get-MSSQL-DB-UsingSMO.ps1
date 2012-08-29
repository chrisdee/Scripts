## =====================================================================
## Title       : Get-MSSQL-DB-UsingSMO
## Description : Show all databases using SMO for a given server instance
## Author      : Idera
## Date        : 1/28/2008
## Input       : -serverInstance <server\instance>
## 				  -verbose 
## 				  -debug	
## Output      : Database IDs and Names
## Usage			: PS> .\Get-MSSQL-DB-UsingSMO -serverInstance MyServer -verbose -debug
## Notes			: Adapted from Jakob Bindslet script
## Tag			: SQL Server, SMO, List databases
## Change log  : Revised SMO Assemblies
## =====================================================================
 
param
(
  	[string]$serverInstance = "(local)",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Get-MSSQL-DB-UsingSMO $serverInstance
}

function Get-MSSQL-DB-UsingSMO($ServerInstance)
{
	#Load SMO assemblies
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Management.Common" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoExtended " );
	 
	$smoServer = new-object( 'Microsoft.SqlServer.Management.Smo.Server' ) ($serverInstance)
    
	foreach ($database in $smoServer.databases) 
	{
		$dbID = $database.ID
		$dbName = $database.Name
		Write-Output "$dbID : $dbName"
	}
}

main

