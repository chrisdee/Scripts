/* SQL Server: Query to view SQL Server Database Restore History */

USE msdb ;
SELECT
DISTINCT
        DBRestored = destination_database_name ,
        RestoreDate = restore_date ,
        SourceDB = b.database_name ,
        BackupDate = backup_start_date
FROM    RestoreHistory h
        JOIN MASTER..sysdatabases sd ON sd.name = h.destination_database_name
        INNER JOIN BackupSet b ON h.backup_set_id = b.backup_set_id
        INNER JOIN BackupFile f ON f.backup_set_id = b.backup_set_id
GROUP BY destination_database_name ,
        restore_date ,
        b.database_name ,
        backup_start_date
ORDER BY RestoreDate DESC
GO
