echo off

echo %DATE% %TIME%: Starting script

call variables.bat

goto startpoint
:startpoint

ECHO %DATE% %TIME%: Creating the %WEB_PORTAL_URL% web application
stsadm -o gl-createwebapp -url %WEB_PORTAL_URL% -directory %PATH_PORTALVDIR% -sethostheader -ownerlogin %ACCT_SPADMIN% -owneremail %ACCT_SPADMIN_EMAIL% -description %WEB_PORTAL_IISDESC% -apidname %WEB_PORTAL_APPIDNAME% -apidtype configurableid -apidlogin %ACCT_SPPORTALAPPPOOL% -apidpwd %ACCT_SPPORTALAPPPOOL_PWD% -databaseserver %SERVER_DB_DEFAULTCONTENT% -databasename %DB_PORTALCONTENT_NAME% -sitetemplate "SPSPORTAL#0" -timezone 12
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting site directory title
stsadm -o gl-setsitegeneralsettings -url %WEB_PORTAL_URL%sitedirectory -title "Site Directory"
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting secondary owner for %WEB_PORTAL_URL% to %ACCT_PORTAL_SECONDARYSITEOWNER%
stsadm -o siteowner -url %WEB_PORTAL_URL% -secondarylogin %ACCT_PORTAL_SECONDARYSITEOWNER%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Creating the %WEB_PORTAL_QUOTANAME% quota template
stsadm -o gl-createquotatemplate -name %WEB_PORTAL_QUOTANAME% -storagemaxlevel 500 -storagewarninglevel 400
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Assigning quota template %WEB_PORTAL_QUOTANAME% to %WEB_PORTAL_URL%
stsadm -o setproperty -propertyname defaultquotatemplate -propertyvalue %WEB_PORTAL_QUOTANAME% -url %WEB_PORTAL_URL%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Assigning site quota template %WEB_PORTAL_QUOTANAME% to %WEB_PORTAL_URL%
stsadm -o gl-syncquotas -scope site -url %WEB_PORTAL_URL% -quota %WEB_PORTAL_QUOTANAME% -setquota
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Granting %ACCT_SPADMIN_GROUPNAME% full control policy level for %WEB_PORTAL_URL%
stsadm -o gl-adduserpolicyforwebapp -url %WEB_PORTAL_URL% -userlogin %ACCT_SPADMIN_GROUPNAME% -username "SharePoint Administrators" -zone all -permissions "Full Control"
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Adding authenticated users to Viewer group for %WEB_PORTAL_URL%
stsadm -o gl-adduser2 -url %WEB_PORTAL_URL% -userlogin "NT AUTHORITY\authenticated users" -group "Viewers"
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting general settings (title, description, etc.) for %WEB_PORTAL_URL%
stsadm -o gl-setsitegeneralsettings -url %WEB_PORTAL_URL% -title %WEB_PORTAL_NAME% -description %WEB_PORTAL_DESC%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting master site directory settings
stsadm -o gl-setmastersitedirectory -url %WEB_PORTAL_SITEDIR_URL% -enforcelistinginsitedir -sitedirentryrequirement 2
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Removing access to online web part gallery for %WEB_PORTAL_URL%
stsadm -o gl-setallowaccesstoonlinegallery -url %WEB_PORTAL_URL% -allowaccesstowebpartcatalog false
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Disabling self service site creation for %WEB_PORTAL_URL%
stsadm -o gl-setselfservicesitecreation -url %WEB_PORTAL_URL% -enabled false -requiresecondarycontact true
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting local site directory settings for %WEB_PORTAL_URL%
stsadm -o gl-setlocalsitedirectory -siteurl %WEB_PORTAL_URL% -url "/SiteDirectory" -enforcelistinginsitedir -sitedirentryrequirement 2
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Set audit settings for %WEB_PORTAL_URL%
stsadm -o gl-setauditsettings -url %WEB_PORTAL_URL% -mode replace -delete -undelete -securitychange
if not errorlevel 0 goto errhnd

echo.
echo.

REM ====================================
REM ==== BEGIN JOB INITIALIZATIONS =====
REM ====================================

echo %DATE% %TIME%: BEGINNING JOB INITIALIZATIONS
echo.

ECHO %DATE% %TIME%: Setting site directory link scan view urls
stsadm -o gl-setsitedirectoryscanviewurls -urls "%WEB_PORTAL_SITEDIR_URL%/SitesList/AllItems.aspx" -updatesiteproperties true
if not errorlevel 0 goto errhnd

echo.
echo %DATE% %TIME%: FINISHED JOB INITIALIZATIONS

REM ====================================
REM ====== END JOB INITIALIZATIONS =====
REM ====================================

goto end

:errhnd

echo An error occured - terminating script.

:end