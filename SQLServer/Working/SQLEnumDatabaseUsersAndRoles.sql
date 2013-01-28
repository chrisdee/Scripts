/* SQL Server: Script To Query Users And Roles Against a Database */

-- Environments: SQL Server 2008 / 2012

WITH Roles_CTE(Role_Name, Username)
AS
(
	SELECT 
		User_Name(sm.[groupuid]) as [Role_Name],
		user_name(sm.[memberuid]) as [Username]
	FROM [sys].[sysmembers] sm
)

SELECT  
    Roles_CTE.Role_Name,
    [DatabaseUserName] = princ.[name],
    [UserType] = CASE princ.[type]
                    WHEN 'S' THEN 'SQL User'
                    WHEN 'U' THEN 'Windows User'
                    WHEN 'G' THEN 'Windows Group'
                    WHEN 'A' THEN 'Application Role'
                    WHEN 'R' THEN 'Database Role'
                    WHEN 'C' THEN 'User mapped to a certificate'
                    WHEN 'K' THEN 'User mapped to an asymmetric key'
                 END
FROM 
    sys.database_principals princ 
JOIN Roles_CTE on Username = princ.name
where princ.type in ('S', 'U', 'G', 'A', 'R', 'C', 'K')
ORDER BY princ.name
