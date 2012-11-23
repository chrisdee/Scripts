/* SQL Server: Script to change All Databases recovery model options, and shrinks the Transaction Log files */

/*
 Only use this script for SQL Server Development and Testing Environments
 Script must be executed as sysadmin
 Note, the default installation recovery model for the 'model' database is FULL (script will change this to SIMPLE)

 As is, this script will execute the following actions on all databases:
 - set recovery model to [Simple]
 - truncate log file
 - shrink log file

 You can change / revert this by changing the following line:
 exec('alter database [' + @databaseName + '] set recovery Simple')
*/

use [master]
go

-- Declare container variabels for each column we select in the cursor
declare @databaseName nvarchar(128)

-- Define the cursor name
declare databaseCursor cursor
-- Define the dataset to loop
for
select [name] from sys.databases

-- Start loop
open databaseCursor

-- Get information from the first row
fetch next from databaseCursor into @databaseName

-- Loop until there are no more rows
while @@fetch_status = 0
begin
 print 'Setting recovery model to Simple for database [' + @databaseName + ']'
 exec('alter database [' + @databaseName + '] set recovery Simple') -- Change this to Full if you want to revert back from Simple

 print 'Shrinking logfile for database [' + @databaseName + ']'
 exec('
 use [' + @databaseName + '];' +'

 declare @logfileName nvarchar(128);
 set @logfileName = (
 select top 1 [name] from sys.database_files where [type] = 1
 );
 dbcc shrinkfile(@logfileName,1);
 ')

 -- Get information from next row
 fetch next from databaseCursor into @databaseName
end

-- End loop and clean up
close databaseCursor
deallocate databaseCursor
go
