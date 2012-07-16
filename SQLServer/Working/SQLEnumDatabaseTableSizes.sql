/* SQL Query to Return a databases Row Count; Reserved Pages size; Data Pages size; Index size; Unused size */
-- Similar to the System Stored Procedure sp_spaceused; or sp_spaceused 'TableName'
-- Script goes through each Table in a Database and reports on the Row Counts and Sizes

DECLARE @ShowResultsInKB1_MB0 BIT
SET @ShowResultsInKB1_MB0 = 0; -- Results format: Select "1" for KB or "0" for MB --
WITH TableSizes AS (
    SELECT
        a3.name AS [schemaname],
        a2.name AS [tablename],
        a1.rows as row_count,
        (a1.reserved + ISNULL(a4.reserved,0))* 8 AS reserved,
        a1.data * 8 AS data,
        (CASE WHEN (a1.used + ISNULL(a4.used,0)) > a1.data THEN (a1.used + ISNULL(a4.used,0)) - a1.data ELSE 0 END) * 8 AS index_size,
        (CASE WHEN (a1.reserved + ISNULL(a4.reserved,0)) > a1.used THEN (a1.reserved + ISNULL(a4.reserved,0)) - a1.used ELSE 0 END) * 8 AS unused
    FROM
        (SELECT
            ps.object_id,
            SUM (
                CASE
                    WHEN (ps.index_id < 2) THEN row_count
                    ELSE 0
                END
                ) AS [rows],
            SUM (ps.reserved_page_count) AS reserved,
            SUM (
                CASE
                    WHEN (ps.index_id < 2) THEN (ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count)
                    ELSE (ps.lob_used_page_count + ps.row_overflow_used_page_count)
                END
                ) AS data,
            SUM (ps.used_page_count) AS used
        FROM sys.dm_db_partition_stats ps
        GROUP BY ps.object_id) AS a1
    LEFT OUTER JOIN
        (SELECT
            it.parent_id,
            SUM(ps.reserved_page_count) AS reserved,
            SUM(ps.used_page_count) AS used
         FROM sys.dm_db_partition_stats ps
         INNER JOIN sys.internal_tables it ON (it.object_id = ps.object_id)
         WHERE it.internal_type IN (202,204)
         GROUP BY it.parent_id) AS a4 ON (a4.parent_id = a1.object_id)
    INNER JOIN sys.all_objects a2  ON ( a1.object_id = a2.object_id )
    INNER JOIN sys.schemas a3 ON (a2.schema_id = a3.schema_id)
    WHERE a2.type <> N'S' and a2.type <> N'IT'
)
SELECT SchemaName, TableName, row_count
    , CAST(ROUND(CASE @ShowResultsInKB1_MB0 WHEN 1 THEN reserved ELSE reserved / 1024.0 END, 2) AS DECIMAL(18,2))  AS reserved
    , CAST(ROUND(CASE @ShowResultsInKB1_MB0 WHEN 1 THEN data ELSE data / 1024.0 END, 2) AS DECIMAL(18,2))  AS data
    , CAST(ROUND(CASE @ShowResultsInKB1_MB0 WHEN 1 THEN index_size ELSE index_size / 1024.0 END, 2) AS DECIMAL(18,2))  AS index_size
    , CAST(ROUND(CASE @ShowResultsInKB1_MB0 WHEN 1 THEN unused ELSE unused / 1024.0 END, 2) AS DECIMAL(18,2))  AS unused
FROM TableSizes
ORDER BY SchemaName, TableName