rem SET PATH=C:\Program Files\Common Files\Microsoft Shared\web server extensions\12\BIN;%PATH%

rem ******* SERVERS *********
SET DOMAIN=spdev
SET SERVER_MAIL="sharepoint1.spdev.com"
SET SERVER_INDEX=sharepoint1
SET SERVER_DB_CONFIG=spsql1
SET SERVER_DB_SEARCH=spsql1
SET SERVER_DB_DEFAULTCONTENT=spsql1
SET SERVER_DB_TEAMS=spsql1
SET SERVER_DB_MYSITES=spsql1

rem ******* DATABASES ********
SET DB_CONFIG_NAME="SharePoint_ConfigDB"
SET DB_CENTRALADMINCONTENT_NAME="SharePoint_CentralAdminContent"
SET DB_SEARCHHELP_NAME="SharePoint_Search_HelpData"
SET DB_SSPCONFIG_NAME="SharePoint_SSP_ConfigDB"
SET DB_MYSITES_NAME="SharePoint_MySites"
SET DB_SSPCONTENT_NAME="SharePoint_SSP_Content"
SET DB_SEARCHCONTENT_NAME="SharePoint_SSP_SearchContent1"
SET DB_PORTALCONTENT_NAME="SharePoint_PortalContent1"
SET DB_TEAMSCONTENT_NAME="SharePoint_TeamsContent1"

rem ******* FILE PATHS ********
SET PATH_HELPSEARCH_INDEXES="e:\MOSS\Indexes\HelpData"
SET PATH_SSP_INDEXES="e:\MOSS\Indexes\Office Server\Applications"
SET PATH_SSPVDIR="e:\MOSS\Webs\SSPAdmin"
SET PATH_MYSITESVDIR="e:\MOSS\Webs\MySites"
SET PATH_USAGELOGS="e:\MOSS\Usage"
SET PATH_PORTALVDIR="e:\MOSS\Webs\Portal"
SET PATH_TEAMSVDIR="e:\MOSS\Webs\Teams"
SET PATH_LOGS="e:\MOSS\Logs"

rem ******* ACCOUNTS ********
SET ACCT_SPFARM="%DOMAIN%\spfarm"
SET ACCT_SPFARM_PWD="pa$$w0rd"

SET ACCT_SPADMIN="%DOMAIN%\spadmin"
SET ACCT_SPADMIN_EMAIL="no-reply@spdev.com"
SET ACCT_SPADMIN_NAME="SharePoint Administrator"
SET ACCT_SPADMIN_GROUPNAME="%DOMAIN%\spadministrators"

rem *** SharePoint Server Search Service Account 
SET ACCT_SSPSEARCH="%DOMAIN%\sspsearch"
SET ACCT_SSPSEARCH_PWD="pa$$w0rd"

rem *** SharePoint Services Help Search Service Account 
SET ACCT_SEARCH_HELP="%DOMAIN%\sphelpsearch"
SET ACCT_SEARCH_HELP_PWD="pa$$w0rd"

rem *** content access account for windows sharepoint services help search
set ACCT_CONTENT_HELP="%DOMAIN%\spcontentsearch"
set ACCT_CONTENT_HELP_PWD="pa$$w0rd"

rem *** Default content access account for office search
SET ACCT_SSPCONTENT="%DOMAIN%\sspcontent"
SET ACCT_SSPCONTENT_PWD="pa$$w0rd"

rem *** SharePoint SSP Application Pool Account
SET ACCT_SSPAPPPOOL="%DOMAIN%\sspapppool"
SET ACCT_SSPAPPPOOL_PWD="pa$$w0rd"

rem *** My sites application pool account
SET ACCT_MYSITESAPPPOOL="%DOMAIN%\spmysitesapppool"
SET ACCT_MYSITESAPPPOOL_PWD="pa$$w0rd"
SET ACCT_MYSITESUSERS_GROUP="%DOMAIN%\SPMySiteUsers"

rem *** SharePoint SSP Service Account
SET ACCT_SSPSVC="%DOMAIN%\sspsvc"
SET ACCT_SSPSVC_PWD="pa$$w0rd"

rem *** User profile import account
SET ACCT_SSPUSERPROFILESVC="%DOMAIN%\sspuserprofilesvc"
SET ACCT_SSPUSERPROFILESVC_PWD="pa$$w0rd"

rem *** Portal application pool account
SET ACCT_SPPORTALAPPPOOL="%DOMAIN%\spportalapppool"
SET ACCT_SPPORTALAPPPOOL_PWD="pa$$w0rd"

rem *** Teams sites application pool account
SET ACCT_SPTEAMSAPPPOOL="%DOMAIN%\spteamsapppool"
SET ACCT_SPTEAMSAPPPOOL_PWD="pa$$w0rd"

rem *** Excel Services unattended access account
set ACCT_EXCEL_USER="%DOMAIN%\sspexcelsvc"
set ACCT_EXCEL_PWD="pa$$w0rd"

SET ACCT_PORTAL_SECONDARYSITEOWNER="%DOMAIN%\siteowner1"
SET ACCT_PORTAL_SECONDARYSITEOWNER_EMAIL="siteowner1@spdev.com"
SET ACCT_PORTAL_SECONDARYSITEOWNER_NAME="Site Owner1"


SET ACCT_TEAMS_SECONDARYSITEOWNER="%DOMAIN%\siteowner1"
SET ACCT_TEAMS_SECONDARYSITEOWNER_EMAIL="siteowner1@spdev.com"
SET ACCT_TEAMS_SECONDARYSITEOWNER_NAME="Site Owner1"


rem ******** WEB APPLICATIONS **********
SET CENTRALADMIN_PORT=1234

SET WEB_SSP_URL="http://sspadmin/"
SET WEB_SSP_IISDESC="SharePoint Shared Services Admin (80)"
SET WEB_SSP_APPIDNAME="SharePoint_SSP_AppPool"
SET WEB_SSP_NAME="SSP1"

SET WEB_MYSITES_URL="http://mysites/"
SET WEB_MYSITES_IISDESC="SharePoint My Sites (80)"
SET WEB_MYSITES_APPIDNAME="SharePoint_MySites_AppPool"
SET WEB_MYSITES_QUOTANAME="My Sites"

SET WEB_PORTAL_URL=http://portal/
SET WEB_PORTAL_SITEDIR_URL="%WEB_PORTAL_URL%SiteDirectory"
SET WEB_PORTAL_NAME="Portal"
SET WEB_PORTAL_QUOTANAME="Portal"
SET WEB_PORTAL_DESC=""
SET WEB_PORTAL_IISDESC="SharePoint Portal (80)"
SET WEB_PORTAL_APPIDNAME="SharePoint_Portal_AppPool"

SET WEB_TEAMS_URL=http://teams/
SET WEB_TEAMS_SITEDIR_URL="%WEB_PORTAL_URL%SiteDirectory"
SET WEB_TEAMS_NAME="Teams"
SET WEB_TEAMS_QUOTANAME="Teams"
SET WEB_TEAMS_DESC=""
SET WEB_TEAMS_IISDESC="SharePoint Teams (80)"
SET WEB_TEAMS_APPIDNAME="SharePoint_Collaboration_AppPool"
