/* SQL Server: Query to check connections on port 1433 or other ports */

SELECT c.session_id, c.local_tcp_port, s.login_name, s.host_name, s.program_name
FROM sys.dm_exec_connections AS c INNER JOIN
            sys.dm_exec_sessions AS s on c.session_id = s.session_id
-- WHERE c.local_tcp_port <> 1433 -- Not equal to port '1433' --
WHERE c.local_tcp_port = 1433 -- Equal to port '1433' --
