## PowerShell: SQL Server System Info Inventory Report ##
# Overview: Runs queries against your SQL Servers and produces multiple file reports
# Resource: http://www.sqlservercentral.com/scripts/87936
# Usage: Edit the '$servers' and '$directoryname' variables to suit your environment

function get-serverinfo {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
# Create an ADO.Net connection to the instance
$cn = new-object system.data.SqlClient.SqlConnection(
"Data Source=$inst;Integrated Security=SSPI;Initial Catalog=master");
# Create an SMO connection to the instance
$s = new-object ('Microsoft.SqlServer.Management.Smo.Server') $server
# Set ShowAdvancedOptions ON for the query
$s.Configuration.ShowAdvancedOptions.ConfigValue = 1
$s.Configuration.Alter()
# Create a DataSet for our configuration information
$ds = new-object "System.Data.DataSet" "dsConfigData"
# Build our query to get configuration, session and lock info, and execute it
$q = "exec sp_configure;
"
$q = $q + "exec sp_who;
"
$q = $q + "exec sp_lock;
"
$da = new-object "System.Data.SqlClient.SqlDataAdapter" ($q, $cn)
$da.Fill($ds)
# Build datatables for the config data, load them from the query results, and write them to CSV files
$dtConfig = new-object "System.Data.DataTable" "dtConfigData"
$dtWho = new-object "System.Data.DataTable" "dtWhoData"
$dtLock = new-object "System.Data.DataTable" "dtLockData"
$dtConfig = $ds.Tables[0]
$dtWho = $ds.Tables[1]
$dtLock = $ds.Tables[2]
$outnm = $directoryname + "_GEN_Configure.csv"
$dtConfig | select name, minimum, maximum, config_value, run_value | export-csv -path $outnm -noType
$outnm = $directoryname + "_GEN_Who.csv"
$dtWho | select spid, ecid, status, loginame, hostname, blk, dbname, cmd, request_id | export-csv -path $outnm -noType
$outnm = $directoryname + "_GEN_Lock.csv"
$dtLock | select spid, dbid, ObjId, IndId, Type,Resource, Mode, Status | export-csv -path $outnm –noType
# Set ShowAdvancedOptions OFF now that we're done with Config
$s.Configuration.ShowAdvancedOptions.ConfigValue = 0
$s.Configuration.Alter()
# Write the login name and default database for Logins to a CSV file
$outnm = $directoryname + "_GEN_Logins.csv"
$s.Logins | select Name, DefaultDatabase | export-csv -path $outnm –noType
# Write information about the databases to a CSV file
$outnm = $directoryname + "_GEN_Databases.csv"
$dbs = $s.Databases
$dbs | select Name, Collation, CompatibilityLevel, AutoShrink,RecoveryModel, Size, 
SpaceAvailable | export-csv -path $outnm –noType
foreach ($db in $dbs) {
# Write the information about the physical files used by the database to CSV files for each database
 $dbname = $db.Name
 if ($db.IsSystemObject) {
 $dbtype = "_SDB"
 } else {
 $dbtype = "_UDB"
     # Write the user information to a CSV file
 $users = $db.Users
 $outnm = $directoryname + $dbtype + "_" + 
 $dbname + "_Users.csv"
 $users | select $dbname, Name, Login, LoginType, UserType, CreateDate | 
 export-csv -path $outnm -noType
     #start of issue
     $fgs = $db.FileGroups
 foreach ($fg in $fgs) {
 $files = $fg.Files
 $outnm = $directoryname + $dbtype + "_" + $dbname + "_DataFiles.csv"
 $files | select $db.Name, Name, FileName, Size,
UsedSpace | export-csv -path $outnm -noType
$logs = $db.LogFiles
$outnm = $directoryname + $dbtype + "_" + $dbname + "_LogFiles.csv"
$logs | select $db.Name, Name, FileName, Size, UsedSpace |
export-csv -path $outnm -noType
}
}
}
}
function getwmiinfo ($svr) {
 gwmi -query "select * from
 Win32_ComputerSystem" -computername $svr | select Name,
 Model, Manufacturer, Description, DNSHostName,
 Domain, DomainRole, PartOfDomain, NumberOfProcessors,
 SystemType, TotalPhysicalMemory, UserName, 
 Workgroup | export-csv -path .\$svr\BOX_ComputerSystem.csv -noType
 gwmi -query "select * from
 Win32_OperatingSystem" -computername $svr | select Name,
 Version, FreePhysicalMemory, OSLanguage, OSProductSuite,
 OSType, ServicePackMajorVersion, ServicePackMinorVersion |
 export-csv -path .\$svr\BOX_OperatingSystem.csv -noType
 gwmi -query "select * from
 Win32_PhysicalMemory" -computername $svr | select Name,
 Capacity, DeviceLocator, Tag | 
 export-csv -path .\$svr\BOX_PhysicalMemory.csv -noType
 gwmi -query "select * from Win32_LogicalDisk
 where DriveType=3" -computername $svr | select Name, FreeSpace,
 Size | export-csv -path .\$svr\BOX_LogicalDisk.csv –noType
}
function get-databasescripts {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.Databases | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "Databases.sql") 
}
function get-backupdevices {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.BackupDevices | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "BackupDevices.sql") 
}
function get-triggers {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.Triggers | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "Triggers.sql") 
}
function get-endpointscripts {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.EndPoints | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "EndPoints.sql") 
}
function get-errorlogs {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.ReadErrorLog() | export-csv -path $($directoryname + "Box_errorlogs.csv") -noType
$srv.ReadErrorLog(1) | export-csv -path $($directoryname + "Box_errorlogs1.csv") -noType
$srv.ReadErrorLog(2) | export-csv -path $($directoryname + "Box_errorlogs2.csv") -noType
}
function get-sqlagentscript {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.JobServer | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "sqlagentscript.sql") 
}
function get-jobscripts {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.JobServer.Jobs | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "jobs.sql") 
}
function get-linkscripts {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.LinkedServers | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "linkedservers.sql") 
}
function get-userlogins {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.Logins | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "logins.sql") 
}
function get-roles {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.Roles | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "roles.sql") 
}
function get-alerts {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.JobServer.Alerts | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "alerts.sql") 
}
function get-operators {
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $sqlserver
$srv.JobServer.Operators | foreach {$_.Script()+ "GO"} | Out-File $($directoryname + $serverfilename + "operators.sql") 
}
$servers = get-content "C:\ztemp\Servers.txt" #Change the path to your 'servers' file to suit your environment
foreach ($server in $servers){
if (!(Test-Path -path .\$server)) {
 New-Item .\$server\ -type directory
 }
$directoryname = "C:\ztemp\Test\" + $server #Change the path to the 'report directory' to suit your environment
$sqlserver = $server
$serverfilename = $server
get-serverinfo
getwmiinfo $server
get-databasescripts
get-errorlogs
get-triggers
get-backupdevices
get-endpointscripts
get-sqlagentscript
get-jobscripts
get-linkscripts
get-userlogins
get-operators
get-alerts
}

