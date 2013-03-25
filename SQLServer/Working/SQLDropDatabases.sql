/* SQL Server: SQL Query To List All User Databases To Bulk DROP Them*/

-- Usage: Change 'Query Results' options to 'Results to text' and run the query. Paste your results in another query window and run.
-- Environments: SQL Server 2008 / 2012

USE master;
Go
SELECT 'DROP DATABASE '+ name 
FROM sys.databases WHERE name like 'DEV_%'; --Change your name here
GO