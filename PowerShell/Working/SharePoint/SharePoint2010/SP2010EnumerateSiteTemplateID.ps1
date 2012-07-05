## SharePoint Server 2010: PowerShell Script To Enumerate Site Template IDs ##
## Resource of Site Template IDs: http://www.sp2010blog.com/Blog/Lists/Posts/Post.aspx?ID=48

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue
$web = Get-SPWeb "http://sp2010devportal.npe.theglobalfund.org/sites/recordscenter"
write-host "Web Template:" $web.WebTemplate " | Web Template ID:" $web.WebTemplateId
$web.Dispose()