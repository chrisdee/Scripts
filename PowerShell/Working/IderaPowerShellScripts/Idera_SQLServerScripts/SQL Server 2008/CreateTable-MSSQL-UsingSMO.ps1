## =====================================================================
## Title       : CreateTable-MSSQL-UsingSMO
## Description : Create a new table using SMO
## Author      : Idera
## Date        : 1/28/2009
## Input       : -serverInstance <server\instance>
## 				  -dbName <database name>
## 				  -schemaName <schema name>
## 				  -tblName <table name>
## 				  -verbose 
## 				  -debug	
## Output      : Create a demo database and table
## Usage			: PS> .\CreateTable-MSSQL-UsingSMO -serverInstance MyServer -dbName SMOTestDB 
## 											-schemaName SMOSchema -tblName SMOTable -verbose -debug
## Notes			: Adapted from Allen White script
## Tag			: SMO, SQL Server, Table
## Change log  : Revised SMO Assemblies
## =====================================================================
 
param
(
  	[string]$serverInstance = "(local)",
	[string]$dbName = "SMOTestDB",
	[string]$schemaName = "SMOSchema",
	[string]$tblName = "SMOTable",
	[switch]$verbose,
	[switch]$debug
)

function main()
{
	if ($verbose) {$VerbosePreference = "Continue"}
	if ($debug) {$DebugPreference = "Continue"}
	CreateTable-MSSQL-UsingSMO $serverInstance $dbName $schemaName $tblName
}

function CreateTable-MSSQL-UsingSMO($serverInstance, $dbName, $schemaName, $tblName)
{
	trap [Exception] 
	{
		write-error $("TRAPPED: " + $_.Exception.Message);
		continue;
	}
	
	# Load SMO assemblies
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Management.Common" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
	[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoExtended " );
	
	# Instantiate a server object for the default instance
	$namedInstance = New-Object ('Microsoft.SqlServer.Management.Smo.Server') ($serverInstance)
	
	# Disable connection pooling
	$namedInstance.ConnectionContext.Set_NonPooledConnection($TRUE)
	
	# Explicitly connect because connection pooling is disabled
	$namedInstance.ConnectionContext.Connect()

	cls
	
	# Connect to the server with Windows Authentication and drop database if exist
	if ($namedInstance.Databases[$dbName] -ne $null) 
	{
		Write-Debug "The test database already exists on $namedInstance"
		Write-Debug "Deleting it now..."
		$namedInstance.Databases[$dbName].drop()
	}

	# Instantiate a database object
	Write-Debug "Creating database: $dbName"
	$database = new-object("Microsoft.SqlServer.Management.Smo.Database") ($namedInstance, $dbName)
	
	# Create the new database on the server
	$database.Create()
	
	# Instantiate a schema object 
	Write-Debug "Creating schema: $SchemaName"
	$schema = new-object("Microsoft.SqlServer.Management.Smo.Schema") ($database, $schemaName)
	
	# Create the new schema on the server
	$schema.Create()
	
	# Instantiate a table object
	Write-Debug "Creating table: $TblName"
	$table = new-object("Microsoft.SqlServer.Management.Smo.Table") ($Database, $TblName)
	
	# Add Field1 column 
	$colField1 = New-Object("Microsoft.SqlServer.Management.Smo.Column") ($table, "Field1")
	# TIP: setting an object type from a NetClassStaticMethod
	$colField1.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::Int
	$table.Columns.Add($colField1)
	
	# Add Field2 column
	$colField2 = New-Object("Microsoft.SqlServer.Management.Smo.Column") ($table, "Field2")
	$colField2.DataType =  [Microsoft.SqlServer.Management.Smo.Datatype]::NVarchar(25)
	$table.Columns.Add($colField2)
	
	# Add Field3 column
	$colField3 = New-Object("Microsoft.SqlServer.Management.Smo.Column") ($table, "Field3")
	$colField3.DataType = [Microsoft.SqlServer.Management.Smo.Datatype]::NVarchar(50)
	$Table.Columns.Add($colField3)
	
	# Set the schema property of the table. 
	$table.Schema = $schemaName
	
	# Create the table on the server
	$table.Create()
	
	Write-Host "Table: $dbName.$schemaName.$tblName created"
	
	# Explicitly disconnect because connection pooling is disabled
	Write-Debug "Disconnecting..."
	$namedInstance.ConnectionContext.Disconnect()
}

main






