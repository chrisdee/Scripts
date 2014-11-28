/* SQL Server: Useful Backup History Queries */

/* 
Usage: The SQL Queries below perform the following backup history checks

- Database Backups for all databases For Specified Period
- Most Recent Database Backup for Each Database 
- Most Recent Database Backup for Each Database - Detailed
- Databases Missing a Data (aka Full) Back-Up Within Specified Period

Environments Tested: SQL Server 2012

Resource: http://www.mssqltips.com/sqlservertip/1601/script-to-retrieve-sql-server-database-backup-history-and-no-backups

*/

---------------------------------------------------------------------------------- 
--Database Backups for all databases For Previous Week 
--------------------------------------------------------------------------------- 
SELECT  
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   msdb.dbo.backupset.database_name,  
   msdb.dbo.backupset.backup_start_date,  
   msdb.dbo.backupset.backup_finish_date, 
   msdb.dbo.backupset.expiration_date, 
   CASE msdb..backupset.type  
       WHEN 'D' THEN 'Database'  
       WHEN 'L' THEN 'Log'  
   END AS backup_type,  
   msdb.dbo.backupset.backup_size,  
   msdb.dbo.backupmediafamily.logical_device_name,  
   msdb.dbo.backupmediafamily.physical_device_name,   
   msdb.dbo.backupset.name AS backupset_name, 
   msdb.dbo.backupset.description 
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7)  --Change the days number here if you want to go back further
ORDER BY  
   msdb.dbo.backupset.database_name, 
   msdb.dbo.backupset.backup_finish_date

------------------------------------------------------------------------------------------- 
--Most Recent Database Backup for Each Database 
------------------------------------------------------------------------------------------- 
SELECT  
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   msdb.dbo.backupset.database_name,  
   MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date 
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE  msdb..backupset.type = 'D' 
GROUP BY 
   msdb.dbo.backupset.database_name  
ORDER BY  
   msdb.dbo.backupset.database_name

------------------------------------------------------------------------------------------- 
--Most Recent Database Backup for Each Database - Detailed 
------------------------------------------------------------------------------------------- 
SELECT  
   A.[Server],  
   A.last_db_backup_date,  
   B.backup_start_date,  
   B.expiration_date, 
   B.backup_size,  
   B.logical_device_name,  
   B.physical_device_name,   
   B.backupset_name, 
   B.description 
FROM 
   ( 
   SELECT   
       CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
       msdb.dbo.backupset.database_name,  
       MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date 
   FROM    msdb.dbo.backupmediafamily  
       INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
   WHERE   msdb..backupset.type = 'D' 
   GROUP BY 
       msdb.dbo.backupset.database_name  
   ) AS A 
    
   LEFT JOIN  

   ( 
   SELECT   
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   msdb.dbo.backupset.database_name,  
   msdb.dbo.backupset.backup_start_date,  
   msdb.dbo.backupset.backup_finish_date, 
   msdb.dbo.backupset.expiration_date, 
   msdb.dbo.backupset.backup_size,  
   msdb.dbo.backupmediafamily.logical_device_name,  
   msdb.dbo.backupmediafamily.physical_device_name,   
   msdb.dbo.backupset.name AS backupset_name, 
   msdb.dbo.backupset.description 
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
WHERE  msdb..backupset.type = 'D' 
   ) AS B 
   ON A.[server] = B.[server] AND A.[database_name] = B.[database_name] AND A.[last_db_backup_date] = B.[backup_finish_date] 
ORDER BY  
   A.database_name

------------------------------------------------------------------------------------------- 
--Databases Missing a Data (aka Full) Back-Up Within Past 24 Hours 
------------------------------------------------------------------------------------------- 
--Databases with data backup over 24 hours old 
SELECT 
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   msdb.dbo.backupset.database_name, 
   MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date, 
   DATEDIFF(hh, MAX(msdb.dbo.backupset.backup_finish_date), GETDATE()) AS [Backup Age (Hours)] 
FROM    msdb.dbo.backupset 
WHERE     msdb.dbo.backupset.type = 'D'  
GROUP BY msdb.dbo.backupset.database_name 
HAVING      (MAX(msdb.dbo.backupset.backup_finish_date) < DATEADD(hh, - 24, GETDATE()))  --Change the hours number here if you want to check sooner

UNION  

--Databases without any backup history 
SELECT      
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,  
   master.dbo.sysdatabases.NAME AS database_name,  
   NULL AS [Last Data Backup Date],  
   9999 AS [Backup Age (Hours)]  
FROM 
   master.dbo.sysdatabases LEFT JOIN msdb.dbo.backupset 
       ON master.dbo.sysdatabases.name  = msdb.dbo.backupset.database_name 
WHERE msdb.dbo.backupset.database_name IS NULL AND master.dbo.sysdatabases.name <> 'tempdb' 
ORDER BY  
   msdb.dbo.backupset.database_name