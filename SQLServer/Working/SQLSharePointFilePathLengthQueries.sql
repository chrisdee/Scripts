/* SharePoint: SQL Query to list Folders and Files Length Counts for Libraries in your content DB */

-- Usage: Works on content databases for both MOSS 2007 and SharePoint Server 2010 / 2013 Farms

select top 100 --Change this value to the 'top' number of documents you want to report on

SUM(len(dirname)+len(leafname)) as Total,

len(dirname) as DirLength,

dirname,

len(leafname) as LeafLength,

leafname

from alldocs with (NOLOCK)

where DeleteTransactionID = 0x

and IsCurrentVersion= 1

group by dirname, leafname

having cast(SUM(len(dirname)+len(leafname)) as int) > 260 --Change this value to the 'Total' number of characters you want to query

order by total desc