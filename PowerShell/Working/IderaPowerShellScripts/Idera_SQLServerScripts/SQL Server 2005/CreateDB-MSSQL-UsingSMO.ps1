## =====================================================================
## Title       : CreateDB-MSSQL-UsingSMO
## Description : Create and empty database, drop if existing
## Author      : Idera
## Date        : 6/27/2008
## Input       : -server <server\instance>
##               -dbName <database name>
##               -verbose 
##               -debug	
## Output      : Formatted table with database name and creation date
## Usage			: PS> .\CreateDB-MSSQL-UsingSMO -server MyServer -dbName SMOTestDB -verbose -debug
## Notes			: Adapted from Allen White script
## Tag			: SQL Server, SMO, Create database
## Change Log  :
##   5/11/2011   Added this line -> $database.LogFiles.Add($dblfile) before Create
## =====================================================================
 
param
(
  	[string]$server = "(local)",
	[string]$dbName = "SMOTestDB",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	CreateDB-MSSQL-UsingSMO $server $dbName 
}

function CreateDB-MSSQL-UsingSMO($server, $dbName)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}
	
	# Load-SMO assemblies
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlEnum")
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") 
	[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") 
	
	# Get a server object for the server instance
	Write-Debug "Creating SMO Server object for $server"
	$NamedInstance = New-Object -typeName Microsoft.SqlServer.Management.Smo.Server `
		-argumentList $server
	
	cls
	
	# Connect to the server with Windows Authentication and drop database if exist
	# TIP: using PowerShell "not equal" operator
	if ($NamedInstance.Databases[$dbName] -ne $null) 
	{
		Write-Debug "The test database already exists on $DefaultServer"
		Write-Debug "Deleting it now..."
		$NamedInstance.Databases[$dbName].drop()
	}
	
	# Instantiate a database object
	Write-Debug "Createing SMO server, database and filegroup objects..."
	$namedInstance = new-object -typename Microsoft.SqlServer.Management.Smo.Server `
		-argumentlist $server
	$database = new-object -typename Microsoft.SqlServer.Management.Smo.Database `
		-argumentlist $namedInstance, $dbName
	$filegroup = new-object -typename Microsoft.SqlServer.Management.Smo.FileGroup `
		-argumentlist $database, "PRIMARY"

	# Add the PRIMARY filegroup to the database
	$database.FileGroups.Add($filegroup)
	
	# Instantiate the data file object and add it to the PRIMARY filegroup
	$dbfile = $dbName + "_Data"
	$dbdfile = new-object ('Microsoft.SqlServer.Management.Smo.DataFile') ($filegroup, $dbfile)
	$filegroup.Files.Add($dbdfile)
	
	Write-Debug "Set properties of the data and log file"
	
	#Set the properties of the data file
	$masterDBPath = $namedInstance.Information.MasterDBPath
	$dbdfile.FileName = $masterDBPath + "\" + $dbfile + ".mdf"
	$dbdfile.Size = [double](25.0 * 1024.0)
	$dbdfile.GrowthType = "Percent"
	$dbdfile.Growth = 25.0
	$dbdfile.MaxSize = [double](100.0 * 1024.0)
	
	#Instantiate the log file object and set its properties
	$masterDBLogPath = $namedInstance.Information.MasterDBLogPath
	$logfile = $dbName + "_Log"
	$dblfile = new-object ('Microsoft.SqlServer.Management.Smo.LogFile') ($database, $logfile)
	$dblfile.FileName = $masterDBLogPath + "\" + $logfile + ".ldf"
	$dblfile.Size = [double](10.0 * 1024.0)
	$dblfile.GrowthType = "Percent"
	$dblfile.Growth = 25.0
	$database.LogFiles.Add($dblfile)

	# Create the new database on the server
	$Database.Create()
	
	# List the database on the server that was just added to confirm that it was added
	# TIP: using PowerShell to pipe an object list to a Where-Object filtering on a variable
	#      and then building a formated table with properties as output to the console
	$NamedInstance.Databases | Where-Object {$_.name -eq "$dbName"} | Format-Table -property name, createdate
}

main

