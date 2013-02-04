/* SQL Server: Scripts To Check SharePoint Database Statistics Timer Jobs Statistics */

-- Overview: The 2 scripts below perform the following:

-- 1. Queries the index statistics for each database and reports on when these were last updated.
-- 2. Runs 'proc_UpdateStatistics' stored procedure for each database. This script could be used as part of a daily SQL Job to update the Index stats.

-- Environments: MOSS 2007 and SharePoint Server 2010 / 2013 Farms

-- Resource: http://blogs.msdn.com/b/erica/archive/2012/10/31/sharepoint-and-database-statistics-why-are-they-out-of-date-and-what-to-do-about-it.aspx

-- 1. Running the following query will show the statistics information for each database --

EXECUTE sp_msforeachdb
'USE [?];
IF DB_NAME() NOT IN(''master'',''msdb'',''tempdb'',''model'')
   begin
        SELECT  ''CHECKING STATS FOR '' + DB_NAME() AS ''DATABASE NAME''
        SELECT   OBJECT_NAME(A.OBJECT_ID) AS ''TABLE NAME''
               , A.NAME AS ''INDEX NAME''
               , STATS_DATE(A.OBJECT_ID,A.INDEX_ID) AS ''STATS LAST UPDATED''
          FROM   SYS.INDEXES A
          JOIN   SYS.OBJECTS B
            ON   B.OBJECT_ID = A.OBJECT_ID
         WHERE   B.IS_MS_SHIPPED = 0
         ORDER   BY OBJECT_NAME(A.OBJECT_ID),A.INDEX_ID
     end'

-- 2. Running the following query calls the 'proc_UpdateStatistics' stored procedure in each database to update the index statistics

EXECUTE sp_msforeachdb
'USE [?];
IF DB_NAME() NOT IN(''master'',''msdb'',''tempdb'',''model'')
     begin
          print ''updating statistics in database  ==> '' + db_name()
          if exists (select 1 from sys.objects where name = ''proc_updatestatistics'')
             begin
                  print ''updating statistics via proc_updatestatistics''
                  exec proc_updatestatistics
             end
         else
             begin
                  print ''updating statistics via sp_updatestats''
                  exec sp_updatestats
             end
    end'
