/* SQL Server: Query to Find Text in all Columns of all Tables in a Database */

-- Search /  Find Text in all columns of all tables in a Database --

DECLARE @TEXT VARCHAR(500)
SET @TEXT = 'YourTextHere' --Change this value to match your search criteria

DECLARE @TABLES TABLE([id] INT IDENTITY(1,1), TableName VARCHAR(500), ColumnName VARCHAR(500))
INSERT INTO @TABLES(TableName, ColumnName)
SELECT O.[NAME], C.[NAME]--SELECT *
FROM SYSOBJECTS O
JOIN SYSCOLUMNS C
 ON C.ID = O.ID
WHERE O.XTYPE = 'U'
 AND C.XTYPE NOT IN
 (
 127 --bigint
 , 173 --binary
 , 104 --bit
 , 61 --datetime
 , 106 --decimal
 , 62 --float
 , 34 --image
 , 56 --int
 , 60 --money
 , 108 --numeric
 , 59 --real
 , 58 --smalldatetime
 , 52 --smallint
 , 122 --smallmoney
 , 189 --timestamp
 , 48 --tinyint
 , 36 --uniqueidentifier
 , 165 --varbinary
 )
ORDER BY O.[NAME], C.[NAME]

IF EXISTS (SELECT NAME FROM TEMPDB.DBO.SYSOBJECTS WHERE NAME LIKE '#TMPREPORT%')
BEGIN
 DROP TABLE #TMPREPORT
END
CREATE TABLE #TMPREPORT(COUNTER INT, TABLENAME VARCHAR(500), COLUMNNAME VARCHAR(500))

DECLARE @CNTR INT, @POS INT, @TableName VARCHAR(500), @ColumnName VARCHAR(500), @SQL VARCHAR(8000)
SELECT @POS = 1, @CNTR = MAX([ID]), @TableName = '', @ColumnName = ''
FROM @TABLES

--SELECT @POS, @CNTR, * FROM @TABLES

WHILE @POS <= @CNTR
BEGIN
 SELECT @TableName = TableName, @ColumnName = ColumnName
 FROM @TABLES
 WHERE [ID] = @POS

 SELECT @SQL = 'SELECT COUNT(*), ''' + @TABLENAME + ''' [TABLE],''' + @COLUMNNAME + '''[COLUMN] FROM ' + @TableName + ' WHERE CAST(' + @ColumnName + ' AS VARCHAR) LIKE ''%' + @TEXT + '%'''
 --PRINT @SQL
 BEGIN TRY
 INSERT INTO #TMPREPORT(COUNTER, TABLENAME, COLUMNNAME)
 EXEC(@SQL)
 END TRY
 BEGIN CATCH
 PRINT @@ERROR
 PRINT @SQL
 END CATCH
 SELECT @POS = @POS + 1
END

SELECT * FROM #TMPREPORT WHERE COUNTER > 0
DROP TABLE #TMPREPORT
----------------------------------------------------------------------------------------
/*127 : bigint
173' --binary
104' --bit
175' --char
61' --datetime
106' --decimal
62' --float
34' --image
56' --int
60' --money
239' --nchar
99' --ntext
108' --numeric
231' --nvarchar
59' --real
58' --smalldatetime
52' --smallint
122' --smallmoney
98' --sql_variant
231' --sysname
35' --text
189' --timestamp
48' --tinyint
36' --uniqueidentifier
165' --varbinary
167' --varchar
*/
