/* SQL Server: Script To Run On A Database To List All Stored Procedures And Column Details */

--------------------------------------------------------------
-- Scriptlet to generate a list of all SPs for the current DB.
-- Includes all parameters for the SPs, datatype and nullability.
-- Useful if building an offline data dictionary or documentation.
-- SQLEnumDatabaseStoredProcs.sql
-- Author: Derek Colley, derek@derekcolley.co.uk, 08/08/12
-- Modification History:
-- 2012/08/08	Initial Version		Derek Colley
--------------------------------------------------------------

-- Create a temp table to house the output of sp_sproc_columns 
DECLARE @t1 TABLE (
PROCEDURE_QUALIFIER NVARCHAR(MAX),PROCEDURE_OWNER NVARCHAR(MAX),
PROCEDURE_NAME NVARCHAR(MAX),	COLUMN_NAME NVARCHAR(MAX),
  COLUMN_TYPE SMALLINT, 		DATA_TYPE SMALLINT,
  [TYPE_NAME] NVARCHAR(MAX),		[PRECISION] INT,
LENGTH INT,		SCALE INT,
  RADIX INT,				NULLABLE BIT,
  REMARKS NVARCHAR(MAX),		COLUMN_DEF NVARCHAR(MAX),
SQL_DATA_TYPE INT,		SQL_DATETIME_SUB INT,
  CHAR_OCTET_LENGTH INT,		ORDINAL_POSITION INT,
  IS_NULLABLE NVARCHAR(100),		SS_DATA_TYPE BIGINT )

-- Populate the table 
INSERT INTO @t1
EXEC sp_sproc_columns

-- Define a target table for the columns we're interested in
DECLARE @procedureListTable TABLE ( 
	sch_name NVARCHAR(MAX), 	proc_name NVARCHAR(MAX), 
col_name NVARCHAR(MAX), 	col_type NVARCHAR(MAX), 
nullable BIT )

-- Populate this table (filtering from @t1, pick your own columns) 
INSERT INTO @procedureListTable 
SELECT PROCEDURE_OWNER, PROCEDURE_NAME, COLUMN_NAME, TYPE_NAME, NULLABLE 
FROM @t1
ORDER BY PROCEDURE_OWNER ASC, PROCEDURE_NAME ASC, COLUMN_NAME ASC

-- Dump output.  Send this to a table / SSIS / Excel as you see fit.
SELECT * FROM @procedureListTable