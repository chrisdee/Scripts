/* SharePoint Server: SQL Query To Truncate Usage And Health Data Collection Content */

-- Overview: Use the SQL below in a situation where your usage and health data collection service causes massive growth in the content database
-- Environments: SP2013 Farms
-- Usage: Run the SQL below on your 'UsageAndHealth' content database to Truncate data from the table
-- Resource: http://www.bondbyte.com/Blog/tabid/55/EntryId/25/SharePoint-2013-unexpected-database-growth.aspx

DECLARE @TableName AS VARCHAR(MAX)
 
DECLARE table_cursor CURSOR
FOR
 SELECT TABLE_NAME
 FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_TYPE = 'BASE TABLE'
 AND TABLE_NAME LIKE '%_Partition%'
OPEN table_cursor
 
FETCH NEXT FROM table_cursor INTO @TableName
 
WHILE @@FETCH_STATUS = 0
BEGIN
 DECLARE @SQLText AS NVARCHAR(4000)
  
 SET @SQLText = 'TRUNCATE TABLE ' + @TableName
  
 EXEC sp_executeSQL @SQLText
  
 FETCH NEXT FROM table_cursor INTO @TableName
END
 
CLOSE table_cursor
DEALLOCATE table_cursor