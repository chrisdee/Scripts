/*  SQL SERVER		Script to Rebuild Indexes Across All Databases on a SQL Instance
	SCRIPT NAME		Smart Index Rebuild - All Databases
	DATE			Oct 2012
	DEVELOPER		Tim Hollobon
	HISTORY			Original #fraglist table code created by Microsoft, Corrected By Pinal Dave.
	RESOURCE		http://www.sqlservercentral.com/scripts/index/94122

	DESCRIPTION		
	The script was born out of the need to rebuild indexes in a maintenance plan where it would
	take too long to do every index in every database, and be too hard to maintain a specific list every time another
	database was added or removed.

	There are plenty of examples that do a specific database (i.e. one at a time) but I needed something that
	traverses all databases and all indexes and rebuilds only those over a certain fragmentation threshold.

	*It rebuilds the indexes instead of reorganising them, as I have found this to be more robust in the event of invalid key values etc. and
		I like my maint plans to just complete no matter what. Original script used DBCC DBREINDEX; this is a deprecated feature so
		this script uses the more current ALTER INDEX.

	**Change the @maxfrag variable near the top to adjust the fragmentation level over which indexes will be rebuilt (default 30).
		N.B. if you are wondering why the index depth >0 test is in the final execution code and not before, thus reducing the result set, it's
		because INDEXPROPERTY must be called when USEing the database in which the index resides.

	***Yes, it uses a cursor. I hate cursors. There is always a set based alternative. However, it will always be a relatively small dataset and
		it was in the original Microsoft script, so I've made a rare exception.

*/
 
 -- Specify your Database Name
USE [master] ;
GO

--create global temp table to hold the table name info
--IF EXISTS (SELECT 1 FROM tempdb.sys .tables WHERE [name] like '#tbllist%')
--        DROP TABLE #tbllist;

CREATE TABLE #tbllist(FullName varchar (255) NOT NULL, DatabaseName varchar(255), TableName varchar (255) NOT NULL)
GO


--get all three part table names from all databases 
sp_msforeachdb
'INSERT INTO #tbllist SELECT ''['' + "?" + ''].['' + [TABLE_SCHEMA] + ''].['' + [TABLE_NAME] + '']'' as FullName, ''['' + "?" + '']'' as DatabaseName, [TABLE_NAME] as TableName
FROM [?].INFORMATION_SCHEMA.TABLES
WHERE TABLE_CATALOG <> ''tempdb'' AND TABLE_TYPE = ''BASE TABLE'''

 -- Declare variables
 SET NOCOUNT ON ;
 DECLARE @fullname VARCHAR (255);
 DECLARE @DatabaseName varchar (255);
 DECLARE @tableName varchar (255);
 DECLARE @execstr VARCHAR (255);
 DECLARE @objectid INT ;
 DECLARE @indexid INT ;
 DECLARE @frag decimal ;
 DECLARE @maxfrag decimal ;
 
-- Decide on the maximum fragmentation to allow for.
SET @maxfrag = 30.0 ; -- Default is set to 30%, change this here if required


 -- Declare a cursor.
 DECLARE tables CURSOR FOR
 SELECT FullName, DatabaseName, TableName
 FROM #tbllist

 -- Create the table.
 CREATE TABLE #fraglist (
        ObjectName varchar (255),
        ObjectId INT ,
        IndexName varchar (255),
        IndexId INT ,
        Lvl INT ,
        CountPages INT ,
        CountRows INT ,
        MinRecSize INT ,
        MaxRecSize INT ,
        AvgRecSize INT ,
        ForRecCount INT ,
        Extents INT ,
        ExtentSwitches INT ,
        AvgFreeBytes INT ,
        AvgPageDensity INT ,
        ScanDensity decimal ,
        BestCount INT ,
        ActualCount INT ,
        LogicalFrag decimal ,
        ExtentFrag decimal );
 -- Open the cursor.
 OPEN tables;
 -- Loop through all the tables in the database.
 FETCH NEXT
 FROM tables
 INTO @fullname, @DatabaseName, @tableName;
 WHILE @@FETCH_STATUS = 0
 BEGIN;

 -- Do the showcontig of all indexes of the table
 INSERT INTO #fraglist
        EXEC ('DBCC SHOWCONTIG (''' + @fullname + ''')
       WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS' );
--put the full table name into the object name, as we need it below
UPDATE #fraglist
SET ObjectName = @fullname
WHERE ObjectName = @tableName

 FETCH NEXT
 FROM tables
 INTO @fullname, @DatabaseName, @tableName;
 END;

 -- Close and deallocate the cursor.
CLOSE tables ;
DEALLOCATE tables ;

SELECT DISTINCT
        IDENTITY(int ,1, 1) as ord
        , 'Executing USE ' + T.DatabaseName + '; ' +
        'IF ((SELECT INDEXPROPERTY (' + CAST( F.ObjectId as varchar(255 )) + ', ' + CHAR(39 ) + F. IndexName + CHAR( 39) + ', ''IndexDepth'')) > 0) ' +
        'ALTER INDEX ' + RTRIM(F.IndexName) + ' ON ' + RTRIM (T. FullName) + ' REBUILD - ' + CAST(LogicalFrag as varchar(5)) + '% Fragmented' as [task_descr]
        , 'USE ' + T.DatabaseName + '; ' +
        'IF ((SELECT INDEXPROPERTY (' + CAST( F.ObjectId as varchar(255 )) + ', ' + CHAR(39 ) + F. IndexName + CHAR( 39) + ', ''IndexDepth'')) > 0) ' +
        'ALTER INDEX [' + RTRIM(F.IndexName) + '] ON ' + RTRIM (T. FullName) + ' REBUILD' as [exec_sql]
INTO #tmp_exec_rebuild_index
FROM #fraglist as F
        INNER JOIN #tbllist as T ON T.FullName = f.ObjectName
WHERE LogicalFrag >= @maxfrag
ORDER BY 1


DECLARE @max_loop int,
        @loopcount int ,
        @exec_sql varchar (4000),
        @exec_descr varchar (4000)
       


SET @max_loop = (SELECT MAX([ord] ) FROM #tmp_exec_rebuild_index)
SET @loopcount = 1

WHILE (@loopcount <=@max_loop )
BEGIN
        SET @exec_descr = (SELECT [task_descr] FROM #tmp_exec_rebuild_index WHERE [ord] = @loopcount)
        SET @exec_sql = (SELECT [exec_sql] FROM #tmp_exec_rebuild_index WHERE [ord] = @loopcount )
        PRINT @exec_descr
        EXEC(@exec_sql );
        SET @loopcount = @loopcount + 1
END


 -- Delete the temporary table.
 DROP TABLE #fraglist ;
 DROP TABLE #tbllist ;
 DROP TABLE #tmp_exec_rebuild_index
 GO