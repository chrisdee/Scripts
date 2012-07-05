## SharePoint Server 2010: PowerShell Script To Set Site Quotas Across Site Collections ##
# Resource: http://blogs.msdn.com/b/brporter/archive/2011/02/25/how-to-update-site-collection-quotas-for-existing-site-collections.aspx
# Usage: The 3 different scripts cover the following 3 scenarios: Apply a new quota template; Replace an existing quota template; Remove an existing quota template

# Scenario 1: Replaces all site collections quotas in a web application with a new template
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

############# Start Variables ################
$TemplateName = "My Template Name"
$WebApplicationUrl = "http://my/"
############# End Variables ################

$contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
$quotaTemplate = $contentService.QuotaTemplates[$TemplateName]
$webApplication = Get-SPWebApplication $WebApplicationUrl
$webApplication.Sites | ForEach-Object { try { $_.Quota = $quotaTemplate; } finally { $_.Dispose(); } }


# Scenario 2: Replaces all site collections quotas in a web application from an existing template with a new template
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

############# Start Variables ################
$OldTemplateName = "Old Template Name"
$NewTemplateName = "New Template Name"
$WebApplicationUrl = "http://my/"
############# End Variables ################

$contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
$quotaTemplate = $contentService.QuotaTemplates[$OldTemplateName]
$replaceQuotaTemplate = $contentService.QuotaTemplates[$NewTemplateName]
$webApplication = Get-SPWebApplication $WebApplicationUrl
$webApplication.Sites | ForEach-Object { try { if ($_.Quota.QuotaID -eq $quotaTemplate.QuotaID) { $_.Quota = $replaceQuotaTemplate } } finally { $_.Dispose(); } }

# Scenario 3: Removes all site collections quotas in a web application that have a quota template associated with them
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

############# Start Variables ################
$OldTemplateName = "Bad Template"
$WebApplicationUrl = "http://my/"
############# End Variables ################

$contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
$quotaTemplate = $contentService.QuotaTemplates[$OldTemplateName]
$webApplication = Get-SPWebApplication $WebApplicationUrl
$webApplication.Sites | ForEach-Object { try { if ($_.Quota.QuotaID -eq $quotaTemplate.QuotaID) { $_.Quota = $null } } finally { $_.Dispose(); } }
