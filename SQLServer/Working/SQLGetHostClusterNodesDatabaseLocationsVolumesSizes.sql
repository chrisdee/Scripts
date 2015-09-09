/* SQL Server: Get Host, Cluster Nodes, and file location / sizes of database files, along with free space on disk for SQL Instances */

-- ===============================================================================================================
-- Author:		Jonathan Roberts
-- Create date: 2015-07-23
-- Description:	Script to display the hosts, database data, and log file sizes, and available space on the volume
--              Can be run on a registered server group to get data for all database servers
-- Note: FileType 'ROWS' = database files and 'LOG' = Transaction Log files
-- ===============================================================================================================
GO

DECLARE @ServerVersion varchar(100)
SET @ServerVersion = CONVERT(varchar,SERVERPROPERTY('productversion'))
SET @ServerVersion = LEFT(@ServerVersion, CHARINDEX('.',@ServerVersion, 4)-1)
--PRINT @ServerVersion
DECLARE @command nvarchar(2000)  
    
IF OBJECT_ID('tempdb..#FileData','U') IS NOT NULL
BEGIN
    PRINT 'Dropping #FileData'
    DROP TABLE tempdb..#FileData
END    

CREATE TABLE tempdb..#FileData
(
    [CurrentHost]                   varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [ClusterNodes]                  varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [DB]                            varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [FileType]                      varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [Name]                          varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [VolumeOrDrive]                 varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [FileName]                      varchar(250) COLLATE Latin1_General_CI_AS NULL,
    [File Size (MB)]                decimal(15,2) NULL,
    [Space Used In File (MB)]       decimal(15,2) NULL,
    [Available Space In File (MB)]  decimal(15,2) NULL,
    [Drive Free Space (MB)]         decimal(15,2) NULL
)    
IF CONVERT(float, @ServerVersion) < 10.5 BEGIN --–2000, 2005, 2008

    IF OBJECT_ID('tempdb..#xp_fixeddrives','U') IS NOT NULL
    BEGIN 
        PRINT 'Dropping table #xp_fixeddrives'
        DROP TABLE #xp_fixeddrives;
    END

    CREATE TABLE #xp_fixeddrives
    (
        Drive   varchar(250),
        MBFree  int
    )
    
    INSERT INTO #xp_fixeddrives
    (
        Drive,
        MBFree
    )
    EXEC master..xp_fixeddrives  


    SET @command = '
    USE [?]
    INSERT INTO #FileData
    (
        [CurrentHost],
        [ClusterNodes],
        [DB],
        [FileType],
        [Name],
        [VolumeOrDrive],
        [FileName],
        [File Size (MB)],
        [Space Used In File (MB)],
        [Available Space In File (MB)],
        [Drive Free Space (MB)]
    )
    SELECT CONVERT(varchar(250), SERVERPROPERTY(''ComputerNamePhysicalNetBIOS'')) COLLATE Latin1_General_CI_AS AS  [CurrentHost],
           CONVERT(varchar(250), ISNULL(STUFF((SELECT '', '' + NodeName FROM fn_virtualservernodes() FOR XML PATH('''')), 1, 1, '''' ), '''')) COLLATE Latin1_General_CI_AS AS [CluserNodes],
           CONVERT(varchar(250), DB_NAME())             COLLATE Latin1_General_CI_AS    [DB],
           CONVERT(varchar(250), df.type_desc)          COLLATE Latin1_General_CI_AS    [FileType],
           CONVERT(varchar(250), f.Name)                COLLATE Latin1_General_CI_AS    [Name],
           CONVERT(varchar(250), LEFT(f.FileName, 3))   COLLATE Latin1_General_CI_AS    [VolumeOrDrive],
           CONVERT(varchar(250), f.FileName)            COLLATE Latin1_General_CI_AS    [FileName],
           CONVERT(Decimal(15,2), ROUND(f.Size/128.000, 2))                             [File Size (MB)],
           CONVERT(Decimal(15,2), ROUND(FILEPROPERTY(f.Name,''SpaceUsed'')/128.000,2))  [Space Used In File (MB)],
           CONVERT(Decimal(15,2), ROUND((f.Size-FILEPROPERTY(f.Name,''SpaceUsed''))/128.000,2))  [Available Space In File (MB)],
           CONVERT(Decimal(15,2), d.MBFree) [Drive Free Space (MB)] 
      FROM dbo.sysfiles f WITH (NOLOCK)
     INNER JOIN sys.database_files df ON df.file_id = f.fileid 
      LEFT JOIN tempdb..#xp_fixeddrives d
             ON LEFT(f.FileName, 1) COLLATE Latin1_General_CI_AS = d.Drive COLLATE Latin1_General_CI_AS;'
END
ELSE -- SQL 2008R2+ (function sys.dm_os_volume_stats is available)
BEGIN
    SET @command = 'USE [?]
    INSERT INTO #FileData
    (
        [CurrentHost],
        [ClusterNodes],
        [DB],
        [FileType],
        [Name],
        [VolumeOrDrive],
        [FileName],
        [File Size (MB)],
        [Space Used In File (MB)],
        [Available Space In File (MB)],
        [Drive Free Space (MB)]
    )
    SELECT CONVERT(varchar(250), SERVERPROPERTY(''ComputerNamePhysicalNetBIOS'')) COLLATE Latin1_General_CI_AS AS [CurrentHost],
           CONVERT(varchar(250), ISNULL(STUFF((SELECT '', '' + NodeName FROM fn_virtualservernodes() FOR XML PATH('''')), 1, 1, '''' ), '''')) COLLATE Latin1_General_CI_AS AS [CluserNodes],
           CONVERT(varchar(250), DB_NAME(v.database_id)) COLLATE Latin1_General_CI_AS       [DB],
           CONVERT(varchar(250), df.type_desc)            COLLATE Latin1_General_CI_AS      [FileType],
           CONVERT(varchar(250), f.name)                 COLLATE Latin1_General_CI_AS       [Name],
           CONVERT(varchar(250), v.volume_mount_point)   COLLATE Latin1_General_CI_AS       [VolumeOrDrive],
           CONVERT(varchar(250), f.[Filename])           COLLATE Latin1_General_CI_AS       [Filename],
           CONVERT(Decimal(15,2), ROUND(f.Size/128.000,2))                                  [File Size (MB)],
           CONVERT(Decimal(15,2), ROUND(FILEPROPERTY(f.Name,''SpaceUsed'')/128.000,2))      [Space Used In File (MB)],
           CONVERT(Decimal(15,2), ROUND((f.Size-FILEPROPERTY(f.Name,''SpaceUsed''))/128.000,2))    [Available Space In File (MB)],
           CONVERT(Decimal(15,2), v.available_bytes/1048576.0)                              [Drive Free Space (MB)]
      FROM sys.sysfiles f WITH (NOLOCK)
     INNER JOIN sys.database_files df ON df.file_id = f.fileid 
     CROSS APPLY sys.dm_os_volume_stats(DB_ID(), f.fileid) v;'
END -- END IF

EXEC sp_MSforeachdb @command 

SELECT *
  FROM #FileData

DROP TABLE tempdb..#FileData
GO