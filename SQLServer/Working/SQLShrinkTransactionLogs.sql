/* SQL Server: Shrink Database Transaction log file sizes */

-- In Production environments; you should always do a full database backup prior to and after this shrink process --
-- Environments: SQL Server 2008 / 2012 --

USE SharePoint_Config -- Data database file name, use [] around the name if you're getting errors locating the database --
GO
Alter Database SharePoint_Config Set Recovery Simple -- Data database file name --
DBCC SHRINKFILE ('SharePoint_Config_log', 100) -- Log file database name and size in MB --
Alter Database SharePoint_Config Set Recovery Full -- Data database file name --

-- Now check the recovery model for your database to make sure it's back to FULL if required --

USE Master
SELECT Name, Recovery_Model_Desc FROM Sys.Databases
where Name = 'SharePoint_Config'
