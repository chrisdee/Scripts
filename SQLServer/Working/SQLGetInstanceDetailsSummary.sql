/* SQL Server: Script to Report on Key Details Related to a SQL Instance */

create table #SVer(ID int,  Name  sysname, Internal_Value int, Value nvarchar(512))
insert #SVer exec master.dbo.xp_msver


declare @SmoRoot nvarchar(512)
DECLARE @sn NVARCHAR(128)
DECLARE @sa NVARCHAR(128)
exec master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\Setup', N'SQLPath', @SmoRoot OUTPUT
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'SYSTEM\CurrentControlSet\services\SQLSERVERAGENT',N'ObjectName', @sn OUTPUT;
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'SYSTEM\CurrentControlSet\services\MSSQLSERVER',N'ObjectName', @sa OUTPUT; 

SELECT
@@SERVERNAME as InstanceName,
(select Value from #SVer where Name = N'ProductName') AS [Product],
SERVERPROPERTY(N'ProductVersion') AS [VersionString],
case when convert(varchar(100), SERVERPROPERTY(N'ProductVersion'))  like '12.%' then 'SQL Server 2014'
 when convert(varchar(100), SERVERPROPERTY(N'ProductVersion')) like '11.%' then 'SQL Server 2012'
 when convert(varchar(100),SERVERPROPERTY(N'ProductVersion')) like '10.5%' then 'SQL Server 2008R2'
 when convert(varchar(100),SERVERPROPERTY(N'ProductVersion')) like '10.0%' then 'SQL Server 2008'
 when convert(varchar(100),SERVERPROPERTY(N'ProductVersion')) like '10.0%' then 'SQL Server 2008'
 when convert(varchar(100),SERVERPROPERTY(N'ProductVersion')) like '9.0%' then 'SQL Server 2005'
else 'Not Found'
end  as VersionName,

--(select Value from #SVer where Name = N'Language') AS [Language],
(select Value from #SVer where Name = N'Platform') AS [Platform],
CAST(SERVERPROPERTY(N'Edition') AS sysname) AS [Edition],
(select Internal_Value from #SVer where Name = N'ProcessorCount') AS [Processors],
(select Value from #SVer where Name = N'WindowsVersion') AS [OSVersion],
(select Internal_Value from #SVer where Name = N'PhysicalMemory') AS [PhysicalMemory_In_MB],
(SELECT value_in_use FROM sys.configurations WHERE name like '%max server memory%')AS max_server_memory_MB,
(SELECT value_in_use FROM sys.configurations WHERE name like '%min server memory%')AS min_server_memory_MB,
case when CAST(SERVERPROPERTY('IsClustered') AS bit) =1 then 'YES'
else 'NO' END
 AS [IsClustered],
case when CAST(SERVERPROPERTY('IsClustered') AS bit)= 1 then (select serverproperty('ComputerNamePhysicalNetBIOS'))
else NULL END  as Active_Node_Name,
(SELECT NodeName
FROM sys.dm_os_cluster_nodes where NodeName !=(select serverproperty('ComputerNamePhysicalNetBIOS'))) as Passive_Node_Name,
@SmoRoot AS [RootDirectory],
@sa as [SQLService_Account],
@sn as [SQLAgent_Account],
convert(sysname, serverproperty(N'collation')) AS [Collation]
/*Add for versions greater than 2005
,(SELECT sqlserver_start_time FROM sys.dm_os_sys_info) as SQLServer_Start_Time
*/

drop table #SVer