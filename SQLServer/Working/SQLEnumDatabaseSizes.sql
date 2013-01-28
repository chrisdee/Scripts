/*SQL Server: Query to Report on Databases Status, Recovery Model, and Database and Transaction Log Sizes */

-- Useful for morning checks and reports
-- Environments: SQL Server 2008 / 2012

if exists (select * from tempdb.sys.all_objects where name like '%#dbsize%')
drop table #dbsize
create table #dbsize
(Dbname varchar(30),dbstatus varchar(20),Recovery_Model varchar(10) default ('NA'), file_Size_MB decimal(20,2)default (0),Space_Used_MB decimal(20,2)default (0),Free_Space_MB decimal(20,2) default (0))
go
 
insert into #dbsize(Dbname,dbstatus,Recovery_Model,file_Size_MB,Space_Used_MB,Free_Space_MB)
exec sp_msforeachdb
'use [?];
  select DB_NAME() AS DbName,
    CONVERT(varchar(20),DatabasePropertyEx(''?'',''Status'')) , 
    CONVERT(varchar(20),DatabasePropertyEx(''?'',''Recovery'')), 
sum(size)/128.0 AS File_Size_MB,
sum(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))/128.0 as Space_Used_MB,
SUM( size)/128.0 - sum(CAST(FILEPROPERTY(name,''SpaceUsed'') AS INT))/128.0 AS Free_Space_MB 
from sys.database_files  where type=0 group by type' 
go
 
-------------------log size--------------------------------------
  if exists (select * from tempdb.sys.all_objects where name like '#logsize%')
drop table #logsize
create table #logsize
(Dbname varchar(30), Log_File_Size_MB decimal(20,2)default (0),log_Space_Used_MB decimal(20,2)default (0),log_Free_Space_MB decimal(20,2)default (0))
go
 
insert into #logsize(Dbname,Log_File_Size_MB,log_Space_Used_MB,log_Free_Space_MB)
exec sp_msforeachdb
'use [?];
  select DB_NAME() AS DbName,
sum(size)/128.0 AS Log_File_Size_MB,
sum(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))/128.0 as log_Space_Used_MB,
SUM( size)/128.0 - sum(CAST(FILEPROPERTY(name,''SpaceUsed'') AS INT))/128.0 AS log_Free_Space_MB 
from sys.database_files  where type=1 group by type' 
go

--------------------------------database free size
  if exists (select * from tempdb.sys.all_objects where name like '%#dbfreesize%')
drop table #dbfreesize
create table #dbfreesize
(name varchar(50),
database_size varchar(50),
Freespace varchar(50)default (0.00))
 
insert into #dbfreesize(name,database_size,Freespace)
exec sp_msforeachdb
'use ?;SELECT database_name = db_name()
    ,database_size = ltrim(str((convert(DECIMAL(15, 2), dbsize) + convert(DECIMAL(15, 2), logsize)) * 8192 / 1048576, 15, 2) + ''MB'')
    ,''unallocated space'' = ltrim(str((
                CASE 
                    WHEN dbsize >= reservedpages
                        THEN (convert(DECIMAL(15, 2), dbsize) - convert(DECIMAL(15, 2), reservedpages)) * 8192 / 1048576
                    ELSE 0
                    END
                ), 15, 2) + '' MB'')
FROM (
    SELECT dbsize = sum(convert(BIGINT, CASE 
                    WHEN type = 0
                        THEN size
                    ELSE 0
                    END))
        ,logsize = sum(convert(BIGINT, CASE 
                    WHEN type <> 0
                        THEN size
                    ELSE 0
                    END))
    FROM sys.database_files
) AS files
,(
    SELECT reservedpages = sum(a.total_pages)
        ,usedpages = sum(a.used_pages)
        ,pages = sum(CASE 
                WHEN it.internal_type IN (
                        202
                        ,204
                        ,211
                        ,212
                        ,213
                        ,214
                        ,215
                        ,216
                        )
                    THEN 0
                WHEN a.type <> 1
                    THEN a.used_pages
                WHEN p.index_id < 2
                    THEN a.data_pages
                ELSE 0
                END)
    FROM sys.partitions p
    INNER JOIN sys.allocation_units a
        ON p.partition_id = a.container_id
    LEFT JOIN sys.internal_tables it
        ON p.object_id = it.object_id
) AS partitions'
-----------------------------------
 
if exists (select * from tempdb.sys.all_objects where name like '%#alldbstate%')
drop table #alldbstate 
create table #alldbstate 
(dbname varchar(25),
DBstatus varchar(25),
R_model Varchar(20))
 
 
--select * from sys.master_files
 
insert into #alldbstate (dbname,DBstatus,R_model)
select name,CONVERT(varchar(20),DATABASEPROPERTYEX(name,'status')),recovery_model_desc from sys.databases
--select * from #dbsize
 
insert into #dbsize(Dbname,dbstatus,Recovery_Model)
select dbname,dbstatus,R_model from #alldbstate where DBstatus <> 'online'
 
insert into #logsize(Dbname)
select dbname from #alldbstate where DBstatus <> 'online'
 
insert into #dbfreesize(name)
select dbname from #alldbstate where DBstatus <> 'online'
 
select 
 
d.Dbname,d.dbstatus,d.Recovery_Model,
(file_size_mb + log_file_size_mb) as DBsize,
d.file_Size_MB,d.Space_Used_MB,d.Free_Space_MB,
l.Log_File_Size_MB,log_Space_Used_MB,l.log_Free_Space_MB,fs.Freespace as DB_Freespace
from #dbsize d join #logsize l 
on d.Dbname=l.Dbname join #dbfreesize fs 
on d.Dbname=fs.name
order by Dbname
 
Drop table #dbsize 
