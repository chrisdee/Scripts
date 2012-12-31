/* SQL Server: Queries To Produce All Key Configuration Settings For SQL Instances */

-- Environments: SQL Server 2008 / 2012
-- Resource: http://www.sqlservercentral.com/scripts/Documentation/93701

SET NOCOUNT ON;
GO  
USE MASTER
GO
PRINT ' '
PRINT ' '
PRINT '*** SQL Server Information Required for any Disaster Recovery  - Version 6.5 *** '
PRINT '          Created by Rudy Panigas October 11, 2012'
PRINT ' '
PRINT '     Please read the remarks in this script for more details'
PRINT ' '
PRINT '   This script will produce an output that contains information that will help '
PRINT '   recover/rebuild the SQL server in a disaster situation.'
PRINT '   '
PRINT '   Here are the sections covered by this script'
PRINT '   '
PRINT '   1)    Physical Server Information - Number of CPUs, memory, etc.'
PRINT '   2)    Hard drive space available - in Megabytes'
PRINT '   3)    SQL Server Information - Server name, version of SQL server, Patch level, etc.'
PRINT '   4)    SQL Server Settings - SP_CONFIGURE'
PRINT '   5)    Database and Log file Physical Locations - All the information regarding the database(s) location'
PRINT '   6)    Database Details - All database information'
PRINT '   7)    List of SQL Jobs - What jobs execute'
PRINT '   8)    Last Backup Dates -  What and when the last backups was completed'
PRINT '   9)    Failed SQL Jobs - Jobs that have failed before. This is important as the new installation may have the same failures'
PRINT '   10)  Disabled Jobs - Jobs there but not set to execute'
PRINT '   11)  SQL Server Services Status - What services were installed and running'
PRINT '   12)  Link Server Details - What other servers is SQL Server linked to'
PRINT '   13)  Database Mail Details - See if it is installed and running'
PRINT '   14)  Database Mirroring Details - Databases mirrored status'
PRINT '   15)  Database Log Shipping Details'
PRINT '   16)  Cluster Details - Information on cluster configuration'
PRINT '   17)  Always On Replication Details. SQL 2012 and newer'
PRINT ' '
PRINT ' '
PRINT '   **NOTE: If SQL server has reports services installed (SSRS) then you will need to export the SSRS key. '
PRINT '   Below is a command to export the SSRS key. You can then use the GUI to import the key '
PRINT ' '
PRINT '   The command line utilities are installed when you choose Administration Tools during Setup. '
PRINT '   You can run them from any directory on your file system. '
PRINT '   Rskeymgmt.exe is located at <drive>:\Program Files\Microsoft SQL Server\...\Tools\Binn'
PRINT ' '
PRINT '   Here is an example to backup the SSRS key -e is to extract, -f is the location place the backup -P is a password used'
PRINT ' '
PRINT '    rskeymgmt.exe -e -f D:\SSRS-Backupkey\rskeybackup.rskey -Passwordhere '
PRINT ' '
PRINT '   Here is an example to restore the SSRS key -a is to apply, -f is the location place the backup -P is a password used'
PRINT ' '
PRINT '    rskeymgmt.exe -a -f D:\SSRS-Backupkey\rskeybackup.rskey -Passwordhere '
PRINT ' '  
PRINT '   Here are the arguments'
PRINT '   -e  Use this argument to back up the keys from the Keys table'
PRINT '   -a  Use this argument to apply the back up copy to the Keys table'
PRINT '   -r  Use this argument to remove the existing keys from the Keys table'
PRINT '   -d  Use this argument to delete all encrypted values from the report server database'
PRINT '   See Books On Line (BOL) for more details.'
PRINT ' '
PRINT 'This vital information is for the following: --> '+ @@servername+' <-- SQL Server'
PRINT 'Executed on: '  SELECT GETDATE();
PRINT ' '

SELECT 'SQL Server Documentation Collector for Disaster Recovery. Loading SQL Server Details into tables. Please wait....'

--> Physical Server Settings <--
 SELECT *	INTO #Physical_Server_Settings  
 FROM sys.dm_os_sys_info

-- > Hard Drive Space Available - in MEGABYTES <--
DECLARE @MBfree int

CREATE TABLE #HD_space
	(Drive varchar(2) NOT NULL,
	[MB free] int NOT NULL)

INSERT INTO #HD_space(Drive, [MB free])
EXEC master.sys.xp_fixeddrives
GO

--> SQL Server Information <--
SELECT
		CONVERT(char(100), SERVERPROPERTY('MachineName')) AS 'MACHINE NAME',
		CONVERT(char(50), SERVERPROPERTY('ServerName')) AS 'SQL SERVER NAME',

        (CASE WHEN CONVERT(char(50), SERVERPROPERTY('InstanceName')) IS NULL
                THEN 'Default Instance'
              ELSE CONVERT(char(50), SERVERPROPERTY('InstanceName'))
         END) AS 'INSTANCE NAME',

        CONVERT(char(30), SERVERPROPERTY('EDITION')) AS EDITION,
        CONVERT(char(30), SERVERPROPERTY('ProductVersion')) AS 'PRODUCT VERSION',
        CONVERT(char(30), SERVERPROPERTY('ProductLevel')) AS 'PRODUCT LEVL',

        (CASE WHEN CONVERT(char(30), SERVERPROPERTY('ISClustered')) = 1
                THEN 'Clustered'
              WHEN CONVERT(char(30), SERVERPROPERTY('ISClustered')) = 0
                THEN 'NOT Clustered'
              ELSE 'INVALID INPUT/ERROR'
         END) AS 'FAILOVER CLUSTERED',

        (CASE WHEN CONVERT(char(30), SERVERPROPERTY('ISIntegratedSecurityOnly')) = 1
                THEN 'Integrated Security '
              WHEN CONVERT(char(30), SERVERPROPERTY('ISIntegratedSecurityOnly')) = 0
                THEN 'SQL Server Security '
              ELSE 'INVALID INPUT/ERROR'
         END) AS 'SECURITY',

        (CASE WHEN CONVERT(char(30), SERVERPROPERTY('ISSingleUser')) = 1
                THEN 'Single User'
              WHEN CONVERT(char(30), SERVERPROPERTY('ISSingleUser')) = 0
                THEN 'Multi User'
              ELSE 'INVALID INPUT/ERROR'
         END) AS 'USER MODE',

        CONVERT(char(30), SERVERPROPERTY('COLLATION')) AS COLLATION
  INTO #SQL_Server_Information
GO

--> SQL Server Settings <--
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
    SELECT 
         [name]
		,[description]
		,[value] 
		,[minimum] 
		,[maximum] 
		,[value_in_use]
		INTO #SQL_Server_Settings
	FROM master.sys.configurations		
GO

EXEC sp_configure 'show advanced options', 0;
GO
RECONFIGURE;
GO		

--> Database and Log File Physical Locations <--

SELECT name, physical_name 
INTO #Database_and_log_physical_locataion
FROM sys.master_files
GO

--> Database(s) Details <--
SELECT 
	D.database_id
,	D.[name]	
,   S.physical_name
,	D.recovery_model_desc
,	D.[compatibility_level]
,	D.collation_name
,	D.create_date
,	D.user_access
,	D.user_access_desc
,	D.is_read_only
,	D.is_auto_close_on
,	D.is_auto_shrink_on
,	D.[state]
,	D.state_desc
,	D.is_in_standby
,	D.is_cleanly_shutdown
,	D.is_supplemental_logging_enabled
,	D.snapshot_isolation_state
,	D.snapshot_isolation_state_desc
,	D.is_read_committed_snapshot_on
,	D.page_verify_option
,	D.page_verify_option_desc
,	D.is_auto_create_stats_on
,	D.is_auto_update_stats_on
,	D.is_auto_update_stats_async_on
,	D.is_ansi_null_default_on
,	D.is_ansi_nulls_on	
,	D.is_ansi_padding_on
,	D.is_ansi_warnings_on
,	D.is_arithabort_on
,	D.is_concat_null_yields_null_on
,	D.is_numeric_roundabort_on
,	D.is_quoted_identifier_on
,	D.is_recursive_triggers_on
,	D.is_cursor_close_on_commit_on
,	D.is_local_cursor_default
,	D.is_fulltext_enabled
,	D.is_trustworthy_on
,	D.is_db_chaining_on
,	D.is_parameterization_forced
,	D.is_master_key_encrypted_by_server
,	D.is_published
,	D.is_subscribed
,	D.is_merge_published
,	D.is_distributor
,	D.is_sync_with_backup
,	D.service_broker_guid
,	D.is_broker_enabled
,	D.log_reuse_wait
,	D.log_reuse_wait_desc
,	is_date_correlation_on
,	D.source_database_id
,	D.owner_sid
INTO #Databases_Details
FROM SYS.DATABASES D
INNER JOIN sys.master_files S
ON D.name = S.name

--> Last Backup Dates <-- 
SELECT 	
	B.name as Database_Name
	, ISNULL(STR(ABS(DATEDIFF(day, GetDate()
	, MAX(Backup_finish_date))))
	, 'NEVER') as DaysSinceLastBackup
	, ISNULL(Convert(char(10)
	, MAX(backup_finish_date)
	, 101)
	, 'NEVER') as LastBackupDate
INTO #Last_Backup_Dates
FROM master.dbo.sysdatabases B 
LEFT OUTER JOIN msdb.dbo.backupset A 
ON A.database_name = B.name 
AND A.type = 'D' 
GROUP BY B.Name 
ORDER BY B.name
GO

--> List of SQL Jobs <--
SELECT 
	originating_server_id
,	[name]
,	[enabled]
,	[description]
,	start_step_id
,	category_id
,	owner_sid
,	notify_level_eventlog
,	notify_level_email
,	notify_level_netsend
,	notify_level_page
,	notify_email_operator_id
,	notify_netsend_operator_id
,	notify_page_operator_id
,	delete_level
,	date_created
,	date_modified
,	version_number
INTO #List_of_Jobs
FROM msdb.dbo.sysjobs;
GO 
 
--> Failed SQL Jobs <--
SELECT 
name 
INTO #Failed_SQL_Jobs
FROM msdb.dbo.sysjobs A
, msdb.dbo.sysjobservers B 
WHERE A.job_id = B.job_id 
AND B.last_run_outcome = 0 
GO


 --> Disabled Jobs <-- 
SELECT name 
INTO #Disabled_Jobs
FROM msdb.dbo.sysjobs 
WHERE enabled = 0 ORDER BY name
GO

--> SQL Server Services Status <--
CREATE TABLE #RegResult
(ResultValue NVARCHAR(4))

CREATE TABLE #ServicesServiceStatus			
( 
	 RowID INT IDENTITY(1,1)
	,ServerName NVARCHAR(128) 
	,ServiceName NVARCHAR(128)
	,ServiceStatus varchar(128)
	,StatusDateTime DATETIME DEFAULT (GETDATE())
	,PhysicalSrverName NVARCHAR(128)
)

DECLARE 
		 @ChkInstanceName nvarchar(128)				
		,@ChkSrvName nvarchar(128)					
		,@TrueSrvName nvarchar(128)					
		,@SQLSrv NVARCHAR(128)						
		,@PhysicalSrvName NVARCHAR(128)			
		,@FTS nvarchar(128)						
		,@RS nvarchar(128)							
		,@SQLAgent NVARCHAR(128)				
		,@OLAP nvarchar(128)					
		,@REGKEY NVARCHAR(128)					


SET @PhysicalSrvName = CAST(SERVERPROPERTY('MachineName') AS VARCHAR(128)) 
SET @ChkSrvName = CAST(SERVERPROPERTY('INSTANCENAME') AS VARCHAR(128)) 
SET @ChkInstanceName = @@serverName

IF @ChkSrvName IS NULL							
	BEGIN 
		SET @TrueSrvName = 'MSQLSERVER'
		SELECT @OLAP = 'MSSQLServerOLAPService' 	
		SELECT @FTS = 'MSFTESQL' 
		SELECT @RS = 'ReportServer' 
		SELECT @SQLAgent = 'SQLSERVERAGENT'
		SELECT @SQLSrv = 'MSSQLSERVER'
	END 
ELSE
	BEGIN
		SET @TrueSrvName =  CAST(SERVERPROPERTY('INSTANCENAME') AS VARCHAR(128)) 
		SET @SQLSrv = '$'+@ChkSrvName
	 	SELECT @OLAP = 'MSOLAP' + @SQLSrv	/*Setting up proper service name*/
		SELECT @FTS = 'MSFTESQL' + @SQLSrv 
		SELECT @RS = 'ReportServer' + @SQLSrv
		SELECT @SQLAgent = 'SQLAgent' + @SQLSrv
		SELECT @SQLSrv = 'MSSQL' + @SQLSrv
	END 


/* ---------------------------------- SQL Server Service Section ----------------------------------------------*/

SET @REGKEY = 'System\CurrentControlSet\Services\'+@SQLSrv

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC xp_servicecontrol N'QUERYSTATE',@SQLSrv
	UPDATE #ServicesServiceStatus set ServiceName = 'MS SQL Server Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'MS SQL Server Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END

/* ---------------------------------- SQL Server Agent Service Section -----------------------------------------*/

SET @REGKEY = 'System\CurrentControlSet\Services\'+@SQLAgent

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC xp_servicecontrol N'QUERYSTATE',@SQLAgent
	UPDATE #ServicesServiceStatus set ServiceName = 'SQL Server Agent Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'SQL Server Agent Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity	
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END


/* ---------------------------------- SQL Browser Service Section ----------------------------------------------*/

SET @REGKEY = 'System\CurrentControlSet\Services\SQLBrowser'

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',N'sqlbrowser'
	UPDATE #ServicesServiceStatus set ServiceName = 'SQL Browser Service - Instance Independent' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'SQL Browser Service - Instance Independent' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END

/* ---------------------------------- Integration Service Section ----------------------------------------------*/

SET @REGKEY = 'System\CurrentControlSet\Services\MsDtsServer'

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',N'MsDtsServer'
	UPDATE #ServicesServiceStatus set ServiceName = 'Intergration Service - Instance Independent' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'Intergration Service - Instance Independent' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END

/* ---------------------------------- Reporting Service Section ------------------------------------------------*/

SET @REGKEY = 'System\CurrentControlSet\Services\'+@RS

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',@RS
	UPDATE #ServicesServiceStatus set ServiceName = 'Reporting Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'Reporting Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END

/* ---------------------------------- Analysis Service Section -------------------------------------------------*/
IF @ChkSrvName IS NULL								
	BEGIN 
	SET @OLAP = 'MSSQLServerOLAPService'
	END
ELSE	
	BEGIN
	SET @OLAP = 'MSOLAP'+'$'+@ChkSrvName
	SET @REGKEY = 'System\CurrentControlSet\Services\'+@OLAP
END

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',@OLAP
	UPDATE #ServicesServiceStatus set ServiceName = 'Analysis Services' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'Analysis Services' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END

/* ---------------------------------- Full Text Search Service Section -----------------------------------------*/

SET @REGKEY = 'System\CurrentControlSet\Services\'+@FTS

INSERT #RegResult ( ResultValue ) EXEC master.sys.xp_regread @rootkey='HKEY_LOCAL_MACHINE', @key=@REGKEY

IF (SELECT ResultValue FROM #RegResult) = 1 
BEGIN
	INSERT #ServicesServiceStatus (ServiceStatus)		
	EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',@FTS
	UPDATE #ServicesServiceStatus set ServiceName = 'Full Text Search Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END
ELSE 
BEGIN
	INSERT INTO #ServicesServiceStatus (ServiceStatus) VALUES ('NOT INSTALLED')
	UPDATE #ServicesServiceStatus set ServiceName = 'Full Text Search Service' where RowID = @@identity
	UPDATE #ServicesServiceStatus set ServerName = @TrueSrvName where RowID = @@identity
	UPDATE #ServicesServiceStatus set PhysicalSrverName = @PhysicalSrvName where RowID = @@identity
	TRUNCATE TABLE #RegResult
END

/* -------------------------------------------------------------------------------------------------------------*/
GO

--> Link Server Details <--
SELECT 
    server_id	
,   name
,	product
,	provider
,	data_source
,	location
,	provider_string
,	[catalog]	
,   connect_timeout
,	query_timeout
,	is_linked
,	is_remote_login_enabled
,	is_rpc_out_enabled
,	is_data_access_enabled
,	is_collation_compatible
,	uses_remote_collation
,	collation_name
,	lazy_schema_validation
,	is_system
,	is_publisher
,	is_subscriber
,	is_distributor
,	is_nonsql_subscriber
,	modify_date
INTO #Link_Server_Details
FROM sys.servers 
WHERE is_linked ='1'
GO

--> Database Mail Details <--
CREATE TABLE #Database_Mail_Details
(Status NVARCHAR(7))
INSERT INTO #Database_Mail_Details (Status)
Exec msdb.dbo.sysmail_help_status_sp


CREATE TABLE #Database_Mail_Details2
(principal_id VARCHAR(124)
,principal_name VARCHAR(124)
,profile_id VARCHAR(124)
,profile_name VARCHAR(124)
,is_default VARCHAR(124))

INSERT INTO #Database_Mail_Details2(principal_id
,principal_name
,profile_id
,profile_name
,is_default)
EXEC msdb.dbo.sysmail_help_principalprofile_sp 
GO

--> Database Mirroring Status <--
SELECT DB.name,
CASE
    WHEN MIRROR.mirroring_state is NULL THEN 'Database Mirroring not configured and/or set'
    ELSE 'Mirroring is configured and/or set'
END as MirroringState
INTO #Database_Mirror_Stats
FROM sys.databases DB INNER JOIN sys.database_mirroring MIRROR
ON DB.database_id=MIRROR.database_id WHERE DB.database_id > 4 ORDER BY DB.NAME
GO
--> Database Mirroring Details <--
SELECT db_name(database_id) as 'Mirror DB_Name', 
	CASE mirroring_state 
		WHEN 0 THEN 'SuspENDed' 
		WHEN 1 THEN 'Disconnected from other partner' 
		WHEN 2 THEN 'Synchronizing' 
		WHEN 3 THEN 'PENDing Failover' 
		WHEN 4 THEN 'Synchronized' 
		WHEN null THEN 'Database is inaccesible or is not mirrored' 
	END as 'Mirroring_State', 
	CASE mirroring_role 
		WHEN 1 THEN 'Principal' 
		WHEN 2 THEN 'Mirror' 
		WHEN null THEN 'Database is not mirrored or is inaccessible' 
	END as 'Mirroring_Role', 
	CASE mirroring_safety_level 
		WHEN 0 THEN 'Unknown state' 
		WHEN 1 THEN 'OFF (Asynchronous)' 
		WHEN 2 THEN 'FULL (Synchronous)' 
		WHEN null THEN 'Database is not mirrored or is inaccessible' 
	END as 'Mirror_Safety_Level', 
	Mirroring_Partner_Name as 'Mirror_ENDpoint', 
	Mirroring_Partner_Instance as 'Mirror_ServerName', 
	Mirroring_Witness_Name as 'Witness_ENDpoint', 
	CASE Mirroring_Witness_State 
		WHEN 0 THEN 'Unknown' 
		WHEN 1 THEN 'Connected' 
		WHEN 2 THEN 'Disconnected' 
		WHEN null THEN 'Database is not mirrored or is inaccessible' 
	END as 'Witness_State', 
	Mirroring_Connection_Timeout as 'Failover Timeout in seconds', 
	Mirroring_Redo_Queue, 
	Mirroring_Redo_Queue_Type 
	INTO #DB_Mirror_Details
	FROM sys.Database_mirroring WHERE mirroring_role is not null
GO

--> Database Log Shipping Details <--
CREATE TABLE #LogShipping
([status] BIT
, [is_primary] BIT
, [server] sysname
, [database_name] sysname
, [time_since_last_backup] INT
, [last_backup_file] NVARCHAR(500)
, [backup_threshold] INT
, [is_backup_alert_enabled] BIT
, [time_since_last_copy] INT
, [last_copied_file] NVARCHAR(500)
, [time_since_last_restore] INT
, [last_restored_file]  NVARCHAR(500)
, [last_restored_latency] INT
, [restore_threshold] INT
, [is_restore_alert_enabled] BIT)
INSERT INTO #LogShipping
EXEC sp_help_log_shipping_monitor
GO

--> Always On Replication (SQL2012 and newer)

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'sys.availability_replicas') 
	BEGIN
		SELECT * INTO #AlwaysOnAvail FROM sys.availability_replicas
		SELECT * INTO #AlwaysOnListener FROM sys.dm_tcp_listener_states
	END
ELSE
	BEGIN
	   PRINT ' '
	END

---------------------- Display Results --------------------
PRINT ' '
PRINT '--> 1) Physical Server Settings <--'
PRINT ' '
SELECT * FROM #Physical_Server_Settings
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Physical Server Information ** '
	END
PRINT ' '

PRINT  '-- > 2) Hard Drive Space Available <--'   
PRINT ' '
SELECT * FROM #HD_space
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Hard Drive Information ** '
	END
PRINT ' '

PRINT '--> 3) SQL Server Information <--'
PRINT ' '
SELECT * FROM #SQL_Server_Information
	IF @@rowcount = 0 
	BEGIN 
		PRINT '**  No SQL Server Information ** '
	END
PRINT ' '

PRINT '--> 4) SQL Server Settings <--'
PRINT ' '
SELECT * FROM #SQL_Server_Settings
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No SQL Server Setting Information ** '
	END
PRINT ' '

PRINT '--> 5) Database and Log File Physical Locations <--'
PRINT ' '
SELECT * FROM #Database_and_log_physical_locataion
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Database and Log Information ** '
	END

PRINT ' '
PRINT '--> 6) Database(s) Details <--'
PRINT ' '
SELECT * FROM #Databases_Details
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Database(s) Information ** '
	END

PRINT ' '
PRINT  '--> 7) Last Backup Dates <-- ' 
PRINT ' '
SELECT * FROM  #List_of_Jobs
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Last Backup Information ** '
	END

PRINT ' '
PRINT  '--> 8) List of SQL Jobs <--'
PRINT ' '
SELECT * FROM #Last_Backup_Dates
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No SQL Job List Information ** '
	END

PRINT ' '
PRINT  '--> 9) Failed SQL Jobs <--'
PRINT ' '
SELECT * FROM #Failed_SQL_Jobs
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Failed SQL Jobs Information ** '
	END
GO

PRINT ' '
PRINT ' --> 10) Disabled Jobs <-- ' 
PRINT ' '
SELECT * FROM #Disabled_Jobs
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Disabled Jobs Information ** '
	END
GO

PRINT ' '
PRINT '--> 11) SQL Server Services Status <--'
PRINT ' '
SELECT   PhysicalSrverName AS 'Physical Server Name'    
		,ServerName AS 'SQL Instance Name'
		,ServiceName AS 'SQL Server Services'
		,ServiceStatus AS 'Current Service Service Status'
		,StatusDateTime AS 'Date/Time Service Status Checked'
FROM #ServicesServiceStatus
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No SQL Server Services Status Information ** '
	END
GO

PRINT ' '
PRINT '--> 12) Link Server Details <--'
PRINT ' '
SELECT * FROM #Link_Server_Details
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Link Server Details Information ** '
	END
GO

PRINT ' '
PRINT '--> 13) Database Mail Details <--'
PRINT ' '
SELECT [Status] AS'Database Mail Service Status' FROM #Database_Mail_Details
SELECT * FROM #Database_Mail_Details2
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Database Mail Service Status Information ** '
	END
PRINT ' '

SELECT * FROM #Database_Mail_Details2
	IF @@rowcount = 0 
	BEGIN 
		PRINT ' ** No Database Mail Service Status Information **'
	END
GO

PRINT ' '
PRINT '-->14) Database Mirroring Status <--'
PRINT ' '
SELECT [name] as 'Database Name', [MirroringState] as 'Mirroring Status' FROM #Database_Mirror_Stats 
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Database Mirroring Status Information **'
	END

GO
PRINT ' '
PRINT '--> Database Mirroring Details'
SELECT * FROM #DB_Mirror_Details
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Database Mirroring Details Information ** '
	END
PRINT ' '

PRINT ' -->15) Database Log Shipping Details <--'
PRINT ' '
SELECT * FROM #LogShipping
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Database Log Shipping Information ** '
	END
PRINT ' '
GO

PRINT ' -->16) Cluster Details <--'
PRINT ' '
PRINT 'Name of all nodes used and are part of this failover cluster'
SELECT * FROM sys.dm_os_cluster_nodes 
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Cluster Node Information ** '
	END

PRINT ' '
PRINT 'Drive letters that are part of the resourse group which contain the data and log files'
SELECT DriveName as 'Drive Letters' FROM sys.dm_io_cluster_shared_drives
	IF @@rowcount = 0 
	BEGIN 
		PRINT '** No Cluster Node Drive Information ** '
	END
PRINT ' '
GO

PRINT ' -->17) Always On Database Replication Details <--'
PRINT ' '
IF OBJECT_ID('#AlwaysOnAvail') IS NULL 
BEGIN
	PRINT '** No AlwayOn Replication Information ** '
END
ELSE
BEGIN
	SELECT * FROM #AlwaysOnAvail  
	DROP TABLE #AlwaysOnAvail
END	

		
IF OBJECT_ID('#AlwaysOnListener') IS NULL 
BEGIN
	PRINT '** No AlwayOn Replication Listener Information ** '
END
ELSE
BEGIN
SELECT *  FROM #AlwaysOnListener
DROP TABLE #AlwaysOnListener
END	


PRINT ' '
PRINT '--------------------------------------------------------------------------------------------------------------------'
PRINT 'NOTE: If SQL server has reports (SSRS) then you will need to export the SSRS key. '
PRINT 'You can export the SSRS key either with the command line tool or the GUI '
PRINT 'and either to import the key '
PRINT ' '   
PRINT 'The command line utilities are installed when you choose Administration Tools during Setup. '
PRINT 'You can run them from any directory on your file system. '
PRINT 'Rskeymgmt.exe is located at <drive>:\Program Files\Microsoft SQL Server\...\Tools\Binn'
PRINT ' '     
PRINT '--> SQL Server Documentation Collector for Disaster Recovery Report Completed <--'
 PRINT ' '  
 PRINT ' ------------------------------------------------------------------------------------------------------------------------------'  
GO


------------------------ Removal of all temp tables -----------------------------
DROP TABLE #Physical_Server_Settings
DROP TABLE #HD_space
DROP TABLE #SQL_Server_Settings 
DROP TABLE #Database_and_log_physical_locataion
DROP TABLE #Databases_Details
DROP TABLE #List_of_Jobs 
DROP TABLE #Last_Backup_Dates
DROP TABLE #Failed_SQL_Jobs
DROP TABLE #Disabled_Jobs
DROP TABLE #ServicesServiceStatus
DROP TABLE #RegResult
DROP TABLE #Link_Server_Details
DROP TABLE #Database_Mail_Details
DROP TABLE #Database_Mail_Details2
DROP TABLE #SQL_Server_Information 
DROP TABLE #Database_Mirror_Stats 
DROP TABLE #DB_Mirror_Details
DROP TABLE #LogShipping
GO
