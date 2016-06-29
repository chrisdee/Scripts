## SharePoint Server: PowerShell Script to Deploy and Activate InfoPath Form Templates (Administrator-approved form template) ##

<#

Overview: PowerShell Script to Deploy and Enable Administrator Approved InfoPath Form Templates

Note: Essentially the same functionality as uploading these through Central Administration - /_admin/ManageFormTemplates.aspx

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the variables to match your environment and run the script

Resources:

http://www.appvity.com/blogs/post/2013/06/16/How-to-configure-and-publish-InfoPath-to-SharePoint-2013.aspx
https://technet.microsoft.com/en-us/library/ff608053.aspx
https://technet.microsoft.com/en-us/library/ff607608.aspx

#>

### Start Variables ###
$FormPath = "C:\BoxBuild\InfoPathTemplates"
$FormName = "YourTemplateName.xsn"
$SiteCollection = "http://YourSiteCollection.com"
### End Variables ###

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

##Install the InfoPath Form Template
Install-SPInfoPathFormTemplate -Path $FormPath + '\' $FormName

##Enable and activate the InfoPath Form Template Feature at Site Collection Level
Enable-SPInfoPathFormTemplate -Identity $FormName -Site $SiteCollection
