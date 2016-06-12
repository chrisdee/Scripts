/* SQL Server: SQL Command to Attach Database Files to a SQL Instance */

USE [master]
CREATE DATABASE [Your_Database_Name] ON
( FILENAME = 'U:\MSSQL\Data\Your_Database_Name.mdf'),--Path to database 'mdf' file
( FILENAME = 'N:\MSSQL\Data\Your_Database_Name.ldf') --Path to transaction log 'ldf' file
FOR ATTACH
GO