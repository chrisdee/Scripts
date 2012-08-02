/* SharePoint: SQL Query to list Full URLs to Document and Form Libraries in your content DB */
-- Usage: Works on content databases for both MOSS 2007 and SharePoint Server 2010 Farms
-- Edit "List URL" and "Template URL" to match your web application URL (keep '/' at the end)

-- Common List Template Type Ids --
-- 100 Generic list
-- 101 Document library
-- 102 Survey
-- 103 Links list
-- 104 Announcements list
-- 105 Contacts list
-- 106 Events list
-- 107 Tasks list
-- 108 Discussion board
-- 109 Picture library
-- 110 Data sources
-- 111 Site template gallery
-- 112 User Information list
-- 113 Web Part gallery
-- 114 List template gallery
-- 115 XML Form library

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