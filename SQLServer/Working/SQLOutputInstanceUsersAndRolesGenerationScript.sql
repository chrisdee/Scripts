/****************************************************************
SQL Server: Script that runs against an instance and creates a
re-usable script to generate all users logins and roles for all
Databases

This Script Generates A script to Create all Logins, Server Roles
,DB Users, and DB roles on a SQL Server

Running this Script will create a script which can be used to recreate
all Logins and Server Roles for each Database
****************************************************************/
SET NOCOUNT ON

DECLARE
        @sql nvarchar(max)
,       @Line int = 1
,       @max int = 0
,       @@CurDB nvarchar(100) = ''

CREATE TABLE #SQL
       (
        Idx int IDENTITY
       ,xSQL nvarchar(max)
       )

INSERT INTO #SQL
        ( xSQL
        )
        SELECT
                'IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'''
                + QUOTENAME(name) + ''')
' + '	CREATE LOGIN ' + QUOTENAME(name) + ' WITH PASSWORD='
                + sys.fn_varbintohexstr(password_hash) + ' HASHED, SID='
                + sys.fn_varbintohexstr(sid) + ', ' + 'DEFAULT_DATABASE='
                + QUOTENAME(COALESCE(default_database_name , 'master'))
                + ', DEFAULT_LANGUAGE='
                + QUOTENAME(COALESCE(default_language_name , 'us_english'))
                + ', CHECK_EXPIRATION=' + CASE is_expiration_checked
                                            WHEN 1 THEN 'ON'
                                            ELSE 'OFF'
                                          END + ', CHECK_POLICY='
                + CASE is_policy_checked
                    WHEN 1 THEN 'ON'
                    ELSE 'OFF'
                  END + '
Go

'
            FROM
                sys.sql_logins
            WHERE
                name <> 'sa'

INSERT INTO #SQL
        ( xSQL
        )
        SELECT
                'IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'''
                + QUOTENAME(name) + ''')
' + '	CREATE LOGIN ' + QUOTENAME(name) + ' FROM WINDOWS WITH '
                + 'DEFAULT_DATABASE='
                + QUOTENAME(COALESCE(default_database_name , 'master'))
                + ', DEFAULT_LANGUAGE='
                + QUOTENAME(COALESCE(default_language_name , 'us_english'))
                + ';
Go

'
            FROM
                sys.server_principals
            WHERE
                type IN ( 'U' , 'G' )
                AND name NOT IN ( 'BUILTIN\Administrators' ,
                                  'NT AUTHORITY\SYSTEM' );
                                  
PRINT '/*****************************************************************************************/'
PRINT '/*************************************** Create Logins ***********************************/'
PRINT '/*****************************************************************************************/'
SELECT
        @Max = MAX(idx)
    FROM
        #SQL 
WHILE @Line <= @max
      BEGIN



            SELECT
                    @sql = xSql
                FROM
                    #SQL AS s
                WHERE
                    idx = @Line
            PRINT @sql

            SET @line = @line + 1
        
      END
DROP TABLE #SQL

CREATE TABLE #SQL2
       (
        Idx int IDENTITY
       ,xSQL nvarchar(max)
       )

INSERT INTO #SQL2
        ( xSQL
        )
        SELECT
                'EXEC sp_addsrvrolemember ' + QUOTENAME(L.name) + ', '
                + QUOTENAME(R.name) + ';
GO

'
            FROM
                sys.server_principals L
            JOIN sys.server_role_members RM
            ON  L.principal_id = RM.member_principal_id
            JOIN sys.server_principals R
            ON  RM.role_principal_id = R.principal_id
            WHERE
                L.type IN ( 'U' , 'G' , 'S' )
                AND L.name NOT IN ( 'BUILTIN\Administrators' ,
                                    'NT AUTHORITY\SYSTEM' , 'sa' );


PRINT '/*****************************************************************************************/'
PRINT '/******************************Add Server Role Members     *******************************/'
PRINT '/*****************************************************************************************/'
SELECT
        @Max = MAX(idx)
    FROM
        #SQL2 
SET @line = 1
WHILE @Line <= @max
      BEGIN



            SELECT
                    @sql = xSql
                FROM
                    #SQL2 AS s
                WHERE
                    idx = @Line
            PRINT @sql

            SET @line = @line + 1
        
      END
DROP TABLE #SQL2

PRINT '/*****************************************************************************************/'
PRINT '/*****************Add User and Roles membership to Indivdual Databases********************/'
PRINT '/*****************************************************************************************/'


--Drop Table #Db
CREATE TABLE #Db
       (
        idx int IDENTITY
       ,DBName nvarchar(100)
       );



INSERT INTO #Db
        SELECT
                name
            FROM
                master.dbo.sysdatabases
            WHERE
                name NOT IN ( 'Master' , 'Model' , 'msdb' , 'tempdb' )
            ORDER BY
                name;


SELECT
        @Max = MAX(idx)
    FROM
        #Db
SET @line = 1
--Select * from #Db


--Exec sp_executesql @SQL

WHILE @line <= @Max
      BEGIN
            SELECT
                    @@CurDB = DBName
                FROM
                    #Db
                WHERE
                    idx = @line

            SET @SQL = 'Use ' + @@CurDB + '

Declare  @@Script NVarChar(4000) = ''''
DECLARE cur CURSOR FOR

Select  ''Use ' + @@CurDB + ';
Go
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'''''' +
                mp.[name] + '''''')
CREATE USER ['' + mp.[name] + ''] FOR LOGIN ['' +mp.[name] + ''] WITH DEFAULT_SCHEMA=[dbo]; ''+ CHAR(13)+CHAR(10) +
''GO'' + CHAR(13)+CHAR(10) +

''EXEC sp_addrolemember N'''''' + rp.name + '''''', N''''['' + mp.[name] + '']''''; 
Go''  
FROM sys.database_role_members a
INNER JOIN sys.database_principals rp ON rp.principal_id = a.role_principal_id
INNER JOIN sys.database_principals AS mp ON mp.principal_id = a.member_principal_id


OPEN cur

FETCH NEXT FROM cur INTO @@Script;
WHILE @@FETCH_STATUS = 0
BEGIN   
PRINT @@Script
FETCH NEXT FROM cur INTO @@Script;
END

CLOSE cur;
DEALLOCATE cur;';
--Print @SQL
Exec sp_executesql @SQL;
--Set @@Script = ''
            SET @Line = @Line + 1

      END

DROP TABLE #Db