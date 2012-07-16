/* SQL Server: Query to Identify SharePoint Database Names against their GUID IDs */
-- Usage: Works on both MOSS 2007 and SharePoint Server 2010 Farm Config DBs
-- Run these queries against your 'farm config' DB
Select ID, Name from objects
where properties like
'%Microsoft.SharePoint.Administration.SPContentDatabase%m_nWarningSiteCount%'

-- Or if you have given your DBs unique name prefixes --
Select ID, Name from objects
where Name like '%SPS_%DB%'