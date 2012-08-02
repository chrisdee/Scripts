/* SharePoint: SQL Query to List All List Template Titles and SP List Template Type IDs used in your content DB */
-- Usage: Works on content databases for both MOSS 2007 and SharePoint Server 2010 Farms
-- Resource: http://techtrainingnotes.blogspot.ch/2008/01/sharepoint-registrationid-list-template.html

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

USE YourContentDBName --Change this to your Content Database name      
SELECT tp_Title, tp_BaseType, tp_ServerTemplate, tp_Description      
FROM AllLists      
ORDER BY tp_ServerTemplate, tp_Title