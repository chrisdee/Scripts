## SQL Server: PowerShell Script to Connect to a SQL Instance to Get Database and Log Files Location, Size, and Autogrowth Details ##

<#

Overview: PowerShell script that connects to a remote SQL instance and reports on Database and Log Files Location, Size, along with Database Autogrowth Details 

Requirements: The client machine the script runs from requires the SQL Server Management Tools to be installed (http://msdn.microsoft.com/en-us/library/bb500441.aspx; http://www.microsoft.com/en-us/download/details.aspx?id=29062)

Environments: Tested with Sharepoint Server 2010 / 2013 Farms, but should work with any SQL Instance as long as the Client machine has the SQL Server Management Tools installed

Usage: Check the following variables, if applicable, and run the script: '$Conn.ServerInstance'; '$Conn.LoginSecure'; '$Conn.Login'; '$Conn.Password'; '$db.name -like' 

Resource: http://jespermchristensen.wordpress.com/2013/03/06/checking-sql-database-db-and-log-file-sizes-and-growth-with-powershell-from-your-windows-78

#>

CLS
Set-StrictMode -Version 2
[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended")
$Conn = new-object Microsoft.SqlServer.Management.Common.ServerConnection
$Conn.applicationName = "PowerShell GetSQLDBInfo (using SMO)"

#Set the parameters for the environment
$Conn.ServerInstance="SQLServer\Instance"   #Provide your SQL Instance here
$Conn.LoginSecure = $true                   #Set to true connect using Windows Authentication
#$Conn.Login = "sa"                          #Do not apply if you use Windows Authentication
#$Conn.Password = "SAPassword"               #Do not apply if you use Windows Authentication

#Connect to the SQL Server and get the databases
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $conn
$dbs = $srv.Databases

#Process all found databases
foreach ($db in $dbs)
 {

 #Process databases if the starts with the database pattern
 if ($db.name -like "*") { #You can add a filter here if you only want to target specific databases e.g. "DEV_*"
  write-host $db.Name

  #Process all database files used by the database 
  foreach ($dbfile in $db.FileGroups.files) {
   $dbfilesize=[math]::floor($dbfile.Size/1024)           #Convert to MB
   if ($dbfile.growthtype -eq "KB") {$dbfilegrowth=[math]::floor($dbfile.growth/1024)} else {$dbfilegrowth=$dbfile.growth}                    #Convert to MB if the type is KB and not Percent
    write-host $dbfile.filename, "Size:"$dbfilesize"MB", "Growth:"$dbfilegrowth, $dbfile.growthtype
   }

  #Process all log files used by the database 
  foreach ($dblogfile in $db.logfiles) {
   $dblogfilesize = [math]::floor($dblogfile.size/1024)   #Convert to MB
   if ($dblogfile.growthtype -eq "KB") {$dblogfilegrowth=[math]::floor($dblogfile.growth/1024)} else {$dblogfilegrowth=$dblogfile.growth}     #Convert to MB if the type is KB and not Percent
    write-host $dblogfile.filename, "Size:"$dblogfilesize"MB", "Growth:"$dblogfilegrowth, $dblogfile.growthtype
   }
   write-host "-"
  }
 }
 #Disconnect from the SQL Server database
 $srv.ConnectionContext.Disconnect()