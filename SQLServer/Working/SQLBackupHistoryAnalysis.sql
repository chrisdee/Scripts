/* SQL Server Backup History Analysis */

SELECT s.database_name,
m.physical_device_name,
cast(s.backup_size/1000000 as varchar(14))+' '+'MB' as bkSize,
CAST (DATEDIFF(second,s.backup_start_date , s.backup_finish_date)AS VARCHAR(4))+' '+'Seconds' TimeTaken,
s.backup_start_date,
CASE s.[type]
WHEN 'D' THEN 'Full'
WHEN 'I' THEN 'Differential'
WHEN 'L' THEN 'Transaction Log'
END as BackupType,
s.server_name,
s.recovery_model
FROM msdb.dbo.backupset s
inner join msdb.dbo.backupmediafamily m
ON s.media_set_id = m.media_set_id
WHERE s.database_name IN (
-- List your databases here, and remember to leave off the ',' at the end of the last database --
'SPS_ECMPortalContentDB',
'SPS_PortalContentDB'
)
AND s.backup_start_date > '2011-10-01 00:00:00.000' -- change this to your date and time of backup --
ORDER BY database_name, backup_start_date, backup_finish_date