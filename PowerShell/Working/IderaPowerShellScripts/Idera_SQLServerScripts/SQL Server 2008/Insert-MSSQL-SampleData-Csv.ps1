## =====================================================================
## Title       : Insert-MSSQL-SampleData-Csv
## Description : Inserts data from a csv file into a table
## Author      : Idera
## Date        : 1/29/2009
## Input       : -serverInstance <server\instance>
## 				  -dbName <database name>
## 				  -schemaName <schema name>
## 				  -tblName <table name>
## 				  -tempDir <output path>
## 				  -csvFile <CSV filename>
## 				  -verbose 
## 				  -debug	
## Output      : Insert data into a table from a CSV file
## Usage			: PS> .\Insert-MSSQL-SampleData-Csv -serverInstance MyServer -dbName SMOTestDB
## 							-schemaName SMOSchema -tblName SMOTable -tempDir C:\TEMP\
## 							-csvFile SampleData.csv -verbose -debug
## Notes			: Make sure the SampleData.csv is put in the path specified by $tempDir
## Tag			: SQL Server, SMO, Insert Data
## Change log  : Revised SMO Assemblies
## =====================================================================
 
param
(
  	[string]$serverInstance = "(local)",
	[string]$dbName = "SMOTestDB",
	[string]$schemaName = "SMOSchema",
	[string]$tblName = "SMOTable",
	[string]$tempDir = "C:\TEMP\",
	[string]$csvFile = "SampleData.csv",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	Insert-MSSQL-SampleData-Csv $serverInstance $dbName $schemaName $tblName $tempDir $csvFile
}

function Insert-MSSQL-SampleData-Csv($serverInstance,$dbName,$schemaName,$tblName,$tempDir,$csvFile)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}

	# Validate path to temp directory
	if (-not (Test-Path -path $tempDir)) 
	{
		Write-Host "Unable to validate path to temp directory: $TempDir"
		break
	}
	
	# Load-SMO assemblies
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Management.Common" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoExtended " );
	
	# Instantiate a server object for the default instance
	$namedInstance = New-Object ('Microsoft.SqlServer.Management.Smo.Server') ($serverInstance)
	
	# Disable connection pooling
	$namedInstance.ConnectionContext.Set_NonPooledConnection($TRUE)
	
	# Specify the name of the database.
	$namedInstance.ConnectionContext.Set_DatabaseName($dbName)
	
	Write-Debug "Open a connection to server: $serverInstance"
		
	#  Need to explicitly connect because connection pooling is disabled
	$namedInstance.ConnectionContext.Connect()
	
	# Import the data from a csv file
	# TIP: using PowerShell Import-Csv to import from a CSV file

	$csvDataFile = $tempDir + $csvFile
	Write-Debug "Import data from $csvDataFile"
	$csvData = Import-Csv -path $csvDataFile
	
	# For each returned line, construct an Insert statement and execute it
	foreach ($line in $csvData) 
	{
		$field1 = $line.Field1
	
		#Prepend a single quote to any single quote embedded in the
		$field2 = $line.Field2 -replace ("'","''")
		$field3 = $line.Field3 -replace ("'","''")
	
		$query = "INSERT INTO $SchemaName.$TblName VALUES($field1, '$field2', '$field3')"
	
		$namedInstance.ConnectionContext.ExecuteNonQuery($query) | Out-NULL
	}
	
	# Explicitly disconnect because connection pooling is disabled
	$namedInstance.ConnectionContext.Disconnect()
}

main