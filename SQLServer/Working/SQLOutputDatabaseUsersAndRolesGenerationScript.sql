/* SQL Script To Run Against a Database To Output Users / Roles For Reuse */

-- Resource: http://www.sqlservercentral.com/articles/Automation/76791/


/***USAGE: SET RESULTS TO TEXT TO ENSURE FULL OUTPUT******/
/**
NOTE:  This script should be run once prior to a database restore to generate the
appropriate permissions scripts.  Set results to text or to file and save it.
(Tools -- Options -- Query Results)
First, you will run the script on the database prior to a restore and retain the output.
Second, restore the database, run the output of first script.
Then run the output of that script again to drop any users.
Finally repair any orphaned users.

Campbell  7-11-2011
**/

/*** NOTE- THIS SCRIPT RETAINS PERMISSIONS BUT DOES NOT REPAIR ORPHANED USERS
YOU MUST STILL RUN SP_CHANGE_USERS_LOGIN TO REPAIR ORPHANED USERS
***/

-- The following line produces the USE statement
print 'USE ['+db_name()+']'

--next block enters some comments at the start of our script
SET NOCOUNT ON

print'--paste these results into new query window and run with results to text,'
print'--then execute the drop statement output again'
print'--permissions script for ' +db_name()+' on '+@@servername
print ' '

--If there are any user created roles, the following will recreate that role
if ((select COUNT (name) from sys.database_principals where type='R' and is_fixed_role =0 and name!='public') >0)
begin

print '--recreate any user created roles'
select 'create role ['+name+'] authorization [dbo]' from sys.database_principals where type='R' and is_fixed_role =0 and name!='public'

end
else
begin

print '--no user created roles to script'

end

print 'go'

--This next block creates the statements to grant users access to the database  This is
--our first opportunity for an "expected error".  If a user user exists in both environments,
--we try to grant it access and might get the error "the user already exists".  If so,
--we can just ignore that error.

print'--grant users access'

SELECT 'EXEC [sp_grantdbaccess] @loginame =['+[master].[dbo].[syslogins].[loginname]+'], @name_in_db =['+
 [sysusers].[name]+']'
 FROM [dbo].[sysusers]
 INNER JOIN [master].[dbo].[syslogins]
  ON [sysusers].[sid] = [master].[dbo].[syslogins].[sid]
--WHERE [sysusers].[name]

print 'go'

--Now we add users to roles.  Pretty straight forward here:
PRINT '--add users to roles'
select 'EXEC sp_addrolemember ' + '@rolename=['+r.name+ '], @membername= ['+ m.name+']'
 from sys.database_role_members rm
  join sys.database_principals r on rm.role_principal_id = r.principal_id
  join sys.database_principals m on rm.member_principal_id = m.principal_id
 where m.name!='dbo'
 order by r.name, m.name

--Now we generate object level permissions. 
print 'go'
print '--object level perms'
select p.state_desc + ' ' + p.permission_name + ' ON [' + s.name +'].['+ o.name collate Latin1_general_CI_AS+ '] TO [' + u.name collate Latin1_general_CI_AS + ']' from sys.database_permissions p inner join sys.objects o on p.major_id = o.object_id inner join sys.schemas s on s.schema_id = o.schema_id inner join sys.database_principals u on p.grantee_principal_id = u.principal_id

print 'go'

--Following is database wide permissions.  for example, if you "grant execute to USER" and don't include an ON statement,
-- the object level permissions will not pick that up.  This does:
print '--grant database wide permissions'

select p.state_desc + ' ' + p.permission_name +' TO [' + u.name collate Latin1_general_CI_AS + ']' from sys.database_permissions p inner join sys.database_principals u on p.grantee_principal_id = u.principal_id
 where p.class_desc='DATABASE' and u.name !='dbo'

/**Next part generates a select statement which will create a "drop user" statement on the restored database. 

So, you will run the script, restore the database, run the output of first script,
then run the output of that script again... it's simpler than it sounds
**/

print 'go'
PRINT'--list of users to drop'

select 'select ''drop user[''+name+'']'' from sysusers where name not in('

select ''''+name+''',' from sysusers
PRINT '''dropusername'')'

--In some cases, the script to "drop users" will want to drop a user that owns a schema and this will create an error.
--This is to be expected and you need to decide how you want to deal with it.  If there are no objects in the schema
--perhaps just drop it.  If the user owns objects, that needs to be dealt with differently and your cross environment
--restore needs to be discussed with the data owners. 
PRINT'--REMEMBER TO RUN SP_CHANGE_USERS_LOGIN'