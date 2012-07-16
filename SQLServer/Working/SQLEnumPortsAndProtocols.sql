/* SQL Query To Determine What Protocols, IPs, Ports, and End Points SQL Server is Listening On */
SELECT      e.name,
            e.endpoint_id,
            e.principal_id,
            e.protocol,
            e.protocol_desc,
            ec.local_net_address,
            ec.local_tcp_port,
            e.[type],
            e.type_desc,
            e.[state],
            e.state_desc,
            e.is_admin_endpoint
FROM        sys.endpoints e
            LEFT OUTER JOIN sys.dm_exec_connections ec
                ON ec.endpoint_id = e.endpoint_id
GROUP BY    e.name,
            e.endpoint_id,
            e.principal_id,
            e.protocol,
            e.protocol_desc,
            ec.local_net_address,
            ec.local_tcp_port,
            e.[type],
            e.type_desc,
            e.[state],
            e.state_desc,
            e.is_admin_endpoint

/* SQL Query To Determine From The Registry What Port SQL Server Is Listening On */

DECLARE @InstName VARCHAR(16)

DECLARE @RegLoc VARCHAR(100)

SELECT @InstName = @@SERVICENAME

IF @InstName = 'MSSQLSERVER'
  BEGIN
    SET @RegLoc='Software\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib\Tcp\'
  END
 ELSE
  BEGIN
   SET @RegLoc='Software\Microsoft\Microsoft SQL Server\' + @InstName + '\MSSQLServer\SuperSocketNetLib\Tcp\'
  END

EXEC [master].[dbo].[xp_regread] 'HKEY_LOCAL_MACHINE', @RegLoc, 'tcpPort'
