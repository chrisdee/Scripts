## =====================================================================
## Title       : Get-MSSQL-ServerRegisterations
## Description : Exports current groups and servers
## Author      : Idera
## Date        : 6/27/2008
## Input       : $file -verbose -debug	
## Output      : 
## Usage			
## 	Function	: Get-MSSQL-ServerRegisterations($file)
##    Script	: PS> .\GetRegisteredSQLServers -file 'C:\TEMP\SQLServerRegistrations.txt' -verbose -debug
## Notes			:
## Tag			:
 
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
	#$appl = New-Object -comobject "SQLDMO.Application"
	#$appl.ServerGroups | %{$group = $_.Name; $_.RegisteredServers | % {$group + " " + $_.Name}} >> $file
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.ConnectionInfo" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
	 
	$smoServers = new-object 'Microsoft.SqlServer.Management.Smo.Server' 
	$smoServers.Name

}

main