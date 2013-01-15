/*SharePoint Server: SQL Query To Get Details On All Site Sizes in Site Collections Within A Content Database*/

-- Usage: Work in MOSS 2007 Farms, and SharePoint Server 2010 /2013 Farms
-- Important: It appears that content crawls will affect the 'LastContentChange', DaysSinceLastChange' stats

Use YourContentDBName --Change this to your content database name

select distinct a.fullurl as [SiteUrl], a.TimeCreated as Created,

b.tp_login as [SiteOwnerAdmin],

sum(cast(c.size as decimal))/1024/1024 as [RecycleBin(MB)],

cast(d.bwused as decimal)/1024/1024 as [BandwidthUsed(MB)],

cast(d.diskused as decimal)/1024/1024 as [SiteSize(MB)],

cast(d.diskquota as decimal)/1024/1024 as [SiteMaxQuota(MB)],

d.id as [SiteID],(select db_name(dbid) from master..sysprocesses where spid=@@SPID) as [ContentDB],

(select @@servername) as [ServerName],

d.lastcontentchange as [LastContentChange],

(select datediff(day,d.lastcontentchange,current_timestamp)) as [DaysSinceLastChange]

from webs as a inner join

sites as d on a.siteid=d.id inner join

userinfo as b on a.siteid=b.tp_siteid left join

recyclebin as c on a.siteid=c.siteid where b.tp_siteadmin = '1' and a.parentwebid is null

group by a.fullurl, b.tp_login, d.diskused, d.id, d.bwused, d.diskquota, d.lastcontentchange, a.TimeCreated

Order by a.fullurl