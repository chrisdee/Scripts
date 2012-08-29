## Create-MSSQL-TestDb.ps1

## This script will:
## 1. Load SMO assemblies into the PowerShell process.
## 2. Create an SMO Server object for the default SQL Server instance.
##    The object will be called "$DefaultInstance".
## 3. Create a database object for a database named "SMOTestDb"
## 4. Use the object's Create() method to push the newly-created object
##    to the server.
## 5. Verify the creation of the new database by looking at 
##    the properties of the server object

$TestDB = "SMOTestDb"

## Load SMO assemblies. 
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Management.Common" );
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoExtended " );

## Create an SMO Server object for the default SQL Server instance.
## The object will be called "$DefaultServer".
$DefaultServer = New-Object -typename Microsoft.SqlServer.Management.Smo.Server

clear
## Check to see whether the test database already exists.
## If so, drop it.
if ($DefaultServer.Databases[$TestDB] -ne $null) {
     $DefaultServer.Databases[$TestDB].drop()
     Write-Host "The test database already exists on $DefaultServer."
     Write-Host "Deleting it now..."
     Write-Host
     Write-Host
     Write-Host
     }

## List the databases that exist in the instance by executing
## the get_databases method of the server object

Write-Host These are the Databases on the default server instance:
Write-Host
$DefaultServer.get_databases() | format-table name, createdate, owner

##  
## instantiate a database object
$DatabaseObj = new-object("Microsoft.SqlServer.Management.Smo.Database") `
     ($DefaultServer, "SMOTestDb")

## Create the database on the server
$DatabaseObj.create()

## Verify creation of the database by executing server method
## get_databases()
Write-Host These are the databases on the default server instance after you
Write-Host create SMOTestDb: 
Write-Host
$DefaultServer.get_databases() | format-table name, createdate, owner


 