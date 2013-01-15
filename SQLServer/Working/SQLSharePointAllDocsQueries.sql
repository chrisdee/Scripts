/* Query to look for all Master Pages, docs, css, etc. in a Web Application along with their Folder Paths and Site Names*/
-- Usage: Work in MOSS 2007 Farms, and some queries will work on SharePoint Server 2010 / 2013 Farms
-- Resources: http://www.codeproject.com/Articles/14232/Useful-SQL-Queries-to-Analyze-and-Monitor-SharePoi
			
set transaction isolation level read uncommitted
SELECT AllDocs.Leafname AS 'FileName',
                 AllDocs.Dirname AS 'Folder Path',
                 AllLists.tp_Title AS 'List Title',
                 Webs.Title AS 'Web Title'
FROM AllDocs
JOIN AllLists
ON
AllLists.tp_Id=AllDocs.ListId
JOIN Webs
ON
Webs.Id=AllLists.tp_WebId
WHERE Extension='master' -- can also change this extension to look for examples like: js, css, doc --
ORDER BY Webs.Title


/* Query to look for all Master Pages, docs, css, etc. in a Web Application along with their Folder Paths and Site Names - includes dates created and last time modified */

set transaction isolation level read uncommitted
SELECT AllDocs.Leafname AS 'FileName',
                 AllDocs.Dirname AS 'Folder Path',
                 AllLists.tp_Title AS 'List Title',
                 Webs.Title AS 'Web Title',
                 AllDocs.TimeCreated AS 'Created date',
                 AllDocs.TimeLastModified AS 'Time Last Modified'
FROM AllDocs
JOIN AllLists
ON
AllLists.tp_Id=AllDocs.ListId
JOIN Webs
ON
Webs.Id=AllLists.tp_WebId
WHERE Extension='PDF' -- can also change this extension to look for examples like: js, css, doc --
ORDER BY Webs.Title

/* Query to look for all Master Pages in a Web Application */

set transaction isolation level read uncommitted
select Title, MasterUrl, CustomMasterUrl from webs


/* Query to look for the largest documents added to a Content Database within a Period of time */

Select
   Top 100 W.FullUrl, W.Title, L.tp_Title as ListTitle, A.tp_DirName, A.tp_LeafName, A.tp_id , DS.Content , DS.Size, D.DocLibRowID, D.TimeCreated, D.Size, D.MetaInfoTimeLastModified, D.ExtensionForFile
From
   [your_content_database].dbo.AllLists L With (NoLock) join
   [your_content_database].dbo.AllUserData A With (NoLock)
      On L.tp_ID=tp_ListId join
   [your_content_database].dbo.AllDocs D With (NoLock)
      On A.tp_ListID=D.ListID
      And A.tp_SiteID=D.SiteID
      And A.tp_DirName=D.DirName
      And A.tp_LeafName=D.LeafName join
   [your_content_database].dbo.AllDocStreams DS With (NoLock)
      On DS.SiteID=A.tp_SiteID
      And DS.ParentID=D.ParentID
      And DS.ID=D.ID join
    [your_content_database].dbo.Webs W With (NoLock) 
      On W.ID=D.WebID
      And W.ID=L.Tp_WebID
      And W.SiteID=A.tp_SiteID
Where
   DS.DeleteTransactionID=0x
   And D.DeleteTransactionID=0x
   And D.IsCurrentVersion=1
   And A.tp_DeleteTransactionID=0x
   And A.tp_IsCurrentVersion=1
   And D.HasStream=1
   And L.tp_DeleteTransactionId=0x
   And ExtensionForFile not in ('webpart','dwp','aspx','xsn','master','rules','xoml')
   And D.MetaInfoTimeLastModified>DateAdd(d,-1,GetDate())
Order by DS.Size desc 


/* Query to look for the largest documents added to a Content Database (latest versions) */

SELECT TOP 100 Webs.FullUrl As SiteUrl, 
Webs.Title 'Document/List Library Title', 
DirName + '/' + LeafName AS 'Document Name',
CAST((CAST(CAST(Size as decimal(10,2))/1024 As 
      decimal(10,2))/1024) AS Decimal(10,2)) AS 'Size in MB'
FROM     Docs INNER JOIN Webs On Docs.WebId = Webs.Id
INNER JOIN Sites ON Webs.SiteId = SItes.Id
WHERE
Docs.Type <> 1 AND (LeafName NOT LIKE '%.stp')  
               AND (LeafName NOT LIKE '%.aspx') 
               AND (LeafName NOT LIKE '%.xfp') 
               AND (LeafName NOT LIKE '%.dwp') 
               AND (LeafName NOT LIKE '%template%') 
               AND (LeafName NOT LIKE '%.inf') 
               AND (LeafName NOT LIKE '%.css') 
ORDER BY 'Size in MB' DESC


/* SharePoint: SQL Query to list Full URLs to Document and Form Libraries in your content DB */
-- Usage: Works on content databases for both MOSS 2007 and SharePoint Server 2010 Farms

SELECT
"Template Type" = CASE
WHEN [Lists].[tp_ServerTemplate] = 101 THEN 'Doc Lib'
WHEN [Lists].[tp_ServerTemplate] = 115 THEN 'Form Lib'
ELSE 'Unknown'
END,
"List URL" = 'http://YourSharePointApp.com/' + CASE -- Replace this with your web app url
WHEN [Webs].[FullUrl]=''
THEN [Webs].[FullUrl] + [Lists].[tp_Title]
ELSE [Webs].[FullUrl] + '/' + [Lists].[tp_Title]
END,
"Template URL" = 'http://YourSharePointApp.com/' + -- Replace this with your web app url
[Docs].[DirName] + '/' + [Docs].[LeafName]
FROM [Lists] LEFT OUTER JOIN [Docs] ON [Lists].[tp_Template]=[Docs].[Id], [Webs]
WHERE ([Lists].[tp_ServerTemplate] = 101 OR [Lists].[tp_ServerTemplate] = 115)
   AND [Lists].[tp_WebId]=[Webs].[Id]
order by "List URL"


/* Query to look for the most versioned documents along with their sizes in a Content DB */

SELECT TOP 100
Webs.FullUrl As SiteUrl, 
Webs.Title 'Document/List Library Title', 
DirName + '/' + LeafName AS 'Document Name',
COUNT(Docversions.version)AS 'Total Version',
SUM(CAST((CAST(CAST(Docversions.Size as decimal(10,2))/1024 As 
   decimal(10,2))/1024) AS Decimal(10,2)) )  AS  'Total Document Size (MB)',
CAST((CAST(CAST(AVG(Docversions.Size) as decimal(10,2))/1024 As 
   decimal(10,2))/1024) AS Decimal(10,2))   AS  'Avg Document Size (MB)'
FROM Docs INNER JOIN DocVersions ON Docs.Id = DocVersions.Id 
   INNER JOIN Webs On Docs.WebId = Webs.Id
INNER JOIN Sites ON Webs.SiteId = SItes.Id
WHERE
Docs.Type <> 1 
AND (LeafName NOT LIKE '%.stp')  
AND (LeafName NOT LIKE '%.aspx')  
AND (LeafName NOT LIKE '%.xfp') 
AND (LeafName NOT LIKE '%.dwp') 
AND (LeafName NOT LIKE '%template%') 
AND (LeafName NOT LIKE '%.inf') 
AND (LeafName NOT LIKE '%.css') 
GROUP BY Webs.FullUrl, Webs.Title, DirName + '/' + LeafName
ORDER BY 'Total Version' desc, 'Total Document Size (MB)' desc


/* Query to look for the total size of all documents in a Content DB */

SELECT SUM(CAST((CAST(CAST(Size as decimal(10,2))/1024 
       As decimal(10,2))/1024) AS Decimal(10,2))) 
       AS  'Total Size in MB'
FROM     Docs INNER JOIN Webs On Docs.WebId = Webs.Id
INNER JOIN Sites ON Webs.SiteId = SItes.Id
WHERE
Docs.Type <> 1 AND (LeafName NOT LIKE '%.stp') 
               AND (LeafName NOT LIKE '%.aspx') 
               AND (LeafName NOT LIKE '%.xfp') 
               AND (LeafName NOT LIKE '%.dwp') 
               AND (LeafName NOT LIKE '%template%') 
               AND (LeafName NOT LIKE '%.inf') 
               AND (LeafName NOT LIKE '%.css') 
               AND (LeafName <>'_webpartpage.htm')


/* Query to list all documents according to the date they were created (TimeCreated) and last modified (TimeLastModified */

SELECT Webs.FullUrl AS SiteUrl, Webs.Title AS [Title], DirName + '/' + LeafName AS [Document Name], Docs.TimeCreated, Docs.TimeLastModified
FROM Docs INNER JOIN Webs On Docs.WebId = Webs.Id
INNER JOIN Sites ON Webs.SiteId = Sites.Id
WHERE Docs.Type <> 1
AND (LeafName IS NOT NULL)
AND (LeafName <> '')
AND (LeafName NOT LIKE '%.stp')
AND (LeafName NOT LIKE '%.aspx')
AND (LeafName NOT LIKE '%.xfp')
AND (LeafName NOT LIKE '%.dwp')
AND (LeafName NOT LIKE '%template%')
AND (LeafName NOT LIKE '%.inf')
AND (LeafName NOT LIKE '%.css')
AND (LeafName NOT LIKE '%.xml')
ORDER BY Docs.TimeCreated DESC
--ORDER BY Docs.TimeLastModified DESC