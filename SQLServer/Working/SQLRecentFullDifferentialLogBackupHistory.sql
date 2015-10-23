/* SQL Server: SQL Query to report on most Recent Full / Differential / Log Backups on a SQL Instance */

-- Reports on most Recent Full / Differential / Log Backups on SQL Instances, and includes number of days since last Full Backup

SELECT      [ServerName],
            [DatabaseName],
            [BackupSystem],
            [FullBackup] = MAX([FullBackup]),
            [DifferentialBackup] = MAX([DifferentialBackup]),
            [LogBackup] = MAX([LogBackup]),
            [DaysSinceLastFull] = DATEDIFF(DAY,MAX([FullBackup]),GETDATE())
FROM
(
        SELECT      [ServerName]    = @@SERVERNAME,
                    [DatabaseName]  = [A].[database_name],
                    [BackupSystem]  = [A].[name],
                    [FullBackup]    = MAX([A].[backup_finish_date]),
                    [DifferentialBackup] = NULL,
                    [LogBackup] = NULL
        FROM        [msdb].[dbo].[backupset] A INNER JOIN
                    [master].[dbo].[sysdatabases] B ON [A].[database_name] = [B].[name]
        WHERE       [A].[type] = 'D'
        GROUP BY    [A].[database_name],
                    [A].[name]
        UNION ALL
        SELECT      [ServerName]    = @@SERVERNAME,
                    [DatabaseName]  = [A].[database_name],
                    [BackupSystem]  = [A].[name],
                    [FullBackup]    = NULL,
                    [DifferentialBackup] = MAX([A].[backup_finish_date]),
                    [LogBackup] = NULL
        FROM        [msdb].[dbo].[backupset] A INNER JOIN
                    [master].[dbo].[sysdatabases] B ON [A].[database_name] = [B].[name]
        WHERE       [A].[type] = 'I'
        GROUP BY    [A].[database_name],
                    [A].[name]
        UNION ALL
        SELECT      [ServerName]    = @@SERVERNAME,
                    [DatabaseName]  = [A].[database_name],
                    [BackupSystem]  = [A].[name],
                    [FullBackup]    = NULL,
                    [DifferentialBackup] = NULL,
                    [LogBackup] = MAX([A].[backup_finish_date])
        FROM        [msdb].[dbo].[backupset] A INNER JOIN
                    [master].[dbo].[sysdatabases] B ON [A].[database_name] = [B].[name]
        WHERE       [A].[type] = 'L'
        GROUP BY    [A].[database_name],
                    [A].[name] ) B
--WHERE BackupSystem IN ('NetAppBackup','CommVault Galaxy Backup','SQL Native')
GROUP BY    [ServerName],
            [DatabaseName],
            [BackupSystem]
ORDER BY    [DatabaseName],
            [BackupSystem]
