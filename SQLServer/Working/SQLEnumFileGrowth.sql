/* SQL Server: Query To Get File Growth Settings And Status For All Databases In An Instance */
-- Environments: SQL Server 2008 / 2012
use master
go
select b.name DB_Name, a.name Logical_name, a.filename File_Name,
cast((a.size * 8.00) / 1024 as numeric(12,2)) as DB_Size_in_MB,
case when a.growth > 100 then 'In MB' else 'In Percentage' end File_Growth,
cast(case when a.growth > 100 then (a.growth * 8.00) / 1024
else (((a.size * a.growth) / 100) * 8.00) / 1024
end as numeric(12,2)) File_Growth_Size_in_MB,
case when ( maxsize = -1 or maxsize=268435456 ) then 'AutoGrowth Not Restricted' else 'AutoGrowth Restricted' end AutoGrowth_Status
from sysaltfiles a
join sysdatabases b on a.dbid = b.dbid
where DATABASEPROPERTYEX(b.name, 'status') = 'ONLINE'
order by b.name