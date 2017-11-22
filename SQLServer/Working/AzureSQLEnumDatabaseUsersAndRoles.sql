/* Azure SQL Server: SQL Command to show Database Permissions on an Azure SQL Instance */

--Resource: https://blobeater.blog/2017/05/22/ad-authentication-and-azure-sql-database/

SELECT
p.name,
prm.permission_name,
prm.class_desc,
prm.state_desc,
p2.name as 'Database role',
p3.name as 'Additional database role'
FROM sys.database_principals p
JOIN sys.database_permissions prm
ON p.principal_id = prm.grantee_principal_id
LEFT JOIN sys.database_principals p2
ON prm.major_id = p2.principal_id
LEFT JOIN sys.database_role_members r
ON p.principal_id = r.member_principal_id
LEFT JOIN sys.database_principals p3
ON r.role_principal_id = p3.principal_id
WHERE p.name <> 'public'
ORDER BY p.name