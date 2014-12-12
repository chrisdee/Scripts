/* SQL Server: Query to provide stats on currently Executing Transactions on a Database */

SELECT des.session_id,des.status,des.login_name,des.[HOST_NAME],der.blocking_session_id,DB_NAME(der.database_id) as database_name,der.command,des.cpu_time,des.reads,des.writes,dec.last_write,des.[program_name],emg.requested_memory_kb,emg.granted_memory_kb,emg.used_memory_kb,der.wait_type,der.wait_time,der.last_wait_type,der.wait_resource,CASE des.transaction_isolation_level WHEN 0 THEN 'Unspecified' WHEN 1 THEN 'ReadUncommitted' WHEN 2 THEN 'ReadCommitted'
WHEN 3 THEN 'Repeatable' WHEN 4 THEN 'Serializable' WHEN 5 THEN 'Snapshot' END AS transaction_isolation_level,
OBJECT_NAME(dest.objectid, der.database_id) as OBJECT_NAME, dest.text as full_query_text,
SUBSTRING(dest.text, der.statement_start_offset /2,(CASE WHEN der.statement_end_offset = -1
THEN DATALENGTH(dest.text) ELSE der.statement_end_offset END - der.statement_start_offset) /2)
AS [executing_statement], deqp.query_plan
FROM  sys.dm_exec_sessions des
LEFT JOIN sys.dm_exec_requests der on des.session_id = der.session_id
LEFT JOIN sys.dm_exec_connections dec on des.session_id = dec.session_id
LEFT JOIN sys.dm_exec_query_memory_grants emg  on des.session_id = emg.session_id      
CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) dest
CROSS APPLY sys.dm_exec_query_plan(der.plan_handle) deqp
WHERE des.session_id <> @@SPID
ORDER BY  des.session_id