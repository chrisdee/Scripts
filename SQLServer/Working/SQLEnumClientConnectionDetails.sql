/* SQL Server: Queries to Check Connections  to an Instance along with a Client Connections Count */

-- https://www.mssqltips.com/sqlservertip/3171/identify-sql-server-databases-that-are-no-longer-in-use/
-- http://www.brentozar.com/archive/2014/05/4-lightweight-ways-tell-database-used/

-- Detailed SQL Server Connection Information
SELECT @@ServerName AS SERVER
 ,NAME
 ,login_time
 ,last_batch
 ,getdate() AS DATE
 ,STATUS
 ,hostname
 ,program_name
 ,nt_username
 ,loginame
FROM sys.databases d
LEFT JOIN sysprocesses sp ON d.database_id = sp.dbid
WHERE database_id NOT BETWEEN 0
  AND 4
 AND loginame IS NOT NULL
 
 -- SQL Server User / Client Connection Count
 SELECT @@ServerName AS server
 ,NAME AS dbname
 ,COUNT(STATUS) AS number_of_connections
 ,GETDATE() AS timestamp
FROM sys.databases sd
LEFT JOIN sysprocesses sp ON sd.database_id = sp.dbid
WHERE database_id NOT BETWEEN 1 AND 4
GROUP BY NAME