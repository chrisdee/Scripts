/* SharePoint Server: SQL Query to Show All User Profiles With a My Site */
-- Usage: Should work on MOSS 2007 and SharePoint Server 2010 Farms
-- Needs to be run against your ProfileDB
-- With SharePoint Server 2010 there is an additional table called 'MySiteDeletionStatus'

SELECT PropertyVal, p.* 
FROM dbo.UserProfileValue v inner join dbo.UserProfile_Full p on p.RecordID=v.RecordID 
where PropertyID=22 and PropertyVal is not null