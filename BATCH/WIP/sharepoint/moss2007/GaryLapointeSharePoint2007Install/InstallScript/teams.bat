echo off

echo %DATE% %TIME%: Starting script

call variables.bat

goto startpoint
:startpoint

ECHO %DATE% %TIME%: Creating the %WEB_TEAMS_URL% web application
stsadm -o gl-createwebapp -url %WEB_TEAMS_URL% -directory %PATH_TEAMSVDIR% -sethostheader -ownerlogin %ACCT_SPADMIN% -owneremail %ACCT_SPADMIN_EMAIL% -description %WEB_TEAMS_IISDESC% -apidname %WEB_TEAMS_APPIDNAME% -apidtype configurableid -apidlogin %ACCT_SPTEAMSAPPPOOL% -apidpwd %ACCT_SPTEAMSAPPPOOL_PWD% -databaseserver %SERVER_DB_TEAMS% -databasename %DB_TEAMSCONTENT_NAME% -sitetemplate "SPSPORTAL#0" -timezone 12
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting secondary owner for %WEB_TEAMS_URL% to %ACCT_TEAMS_SECONDARYSITEOWNER%
stsadm -o siteowner -url %WEB_TEAMS_URL% -secondarylogin %ACCT_TEAMS_SECONDARYSITEOWNER%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Creating the %WEB_TEAMS_QUOTANAME% quota template
stsadm -o gl-createquotatemplate -name %WEB_TEAMS_QUOTANAME% -storagemaxlevel 100 -storagewarninglevel 80
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Assigning quota template %WEB_TEAMS_QUOTANAME% to %WEB_TEAMS_URL%
stsadm -o setproperty -propertyname defaultquotatemplate -propertyvalue %WEB_TEAMS_QUOTANAME% -url %WEB_TEAMS_URL%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Assigning site quota template %WEB_TEAMS_QUOTANAME% to %WEB_TEAMS_URL%
stsadm -o gl-syncquotas -scope site -url %WEB_TEAMS_URL% -quota %WEB_TEAMS_QUOTANAME% -setquota
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Granting %ACCT_SPADMIN_GROUPNAME% full control policy level for %WEB_TEAMS_URL%
stsadm -o gl-adduserpolicyforwebapp -url %WEB_TEAMS_URL% -userlogin %ACCT_SPADMIN_GROUPNAME% -username "SharePoint Administrators" -zone all -permissions "Full Control"
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Adding authenticated users to Viewer group for %WEB_TEAMS_URL%
stsadm -o gl-adduser2 -url %WEB_TEAMS_URL% -userlogin "NT AUTHORITY\authenticated users" -group "Viewers"
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting general settings (title, description, etc.) for %WEB_TEAMS_URL%
stsadm -o gl-setsitegeneralsettings -url %WEB_TEAMS_URL% -title %WEB_TEAMS_NAME% -description %WEB_TEAMS_DESC%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Removing access to online web part gallery for %WEB_TEAMS_URL%
stsadm -o gl-setallowaccesstoonlinegallery -url %WEB_TEAMS_URL% -allowaccesstowebpartcatalog false
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting portal site connection for teamsites
stsadm -o gl-connecttoportalsite -url %WEB_TEAMS_URL% -portalurl %WEB_PORTAL_URL% -portalname %WEB_PORTAL_NAME%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Enabling self service site creation for %WEB_TEAMS_URL%
stsadm -o gl-setselfservicesitecreation -url %WEB_TEAMS_URL% -enabled true -requiresecondarycontact true
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Enabling FullMask for %WEB_TEAMS_URL%
stsadm -o gl-enableuserpermissionforwebapp -url %WEB_TEAMS_URL% -FullMask
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Adding "Team Sites" search scope to SSP
stsadm -o gl-createsearchscope -url "%WEB_SSP_URL%ssp/admin" -name "Team Sites" -description "Search everything on %WEB_TEAMS_URL%" -groups "search dropdown, advanced search" -sspisowner
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Adding rule to %WEB_TEAMS_URL% search scope
stsadm -o gl-addsearchrule -url "%WEB_SSP_URL%ssp/admin" -scope "Team Sites" -behavior include -type webaddress -webtype folder -webvalue %WEB_TEAMS_URL%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating intranet with "Team Sites" search scope
stsadm -o gl-updatesearchscope -url "%WEB_PORTAL_URL%" -name "Team Sites" -groups "search dropdown, advanced search"
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating team sites with "Team Sites" search scope
stsadm -o gl-updatesearchscope -url %WEB_TEAMS_URL% -name "Team Sites" -groups "search dropdown, advanced search"
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Set audit settings for %WEB_TEAMS_URL%
stsadm -o gl-setauditsettings -url %WEB_TEAMS_URL% -mode replace -delete -undelete -securitychange
if not errorlevel 0 goto errhnd

goto end

:errhnd

echo An error occured - terminating script.

:end