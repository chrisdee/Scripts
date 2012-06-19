echo off

echo %DATE% %TIME%: Starting script

call variables.bat

goto startpoint
:startpoint


ECHO %DATE% %TIME%: Giving all authenticated users the use personal features right
stsadm -o gl-setsspacl -sspname %WEB_SSP_NAME% -rights UsePersonalFeatures -user "NT AUTHORITY\Authenticated Users"
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Giving the %ACCT_MYSITESUSERS_GROUP% rights to create my sites.
stsadm -o gl-setsspacl -sspname %WEB_SSP_NAME% -rights "UsePersonalFeatures,CreatePersonalSite" -user %ACCT_MYSITESUSERS_GROUP%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Creating the %WEB_MYSITES_QUOTANAME% quota template
stsadm -o gl-createquotatemplate -name %WEB_MYSITES_QUOTANAME% -storagemaxlevel 50 -storagewarninglevel 40
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Adding %WEB_MYSITES_QUOTANAME% quota template to %WEB_MYSITES_URL%
stsadm -o setproperty -pn defaultquotatemplate -pv %WEB_MYSITES_QUOTANAME% -url %WEB_MYSITES_URL%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Removing access to online web part gallery for %WEB_MYSITES_URL%
stsadm -o gl-setallowaccesstoonlinegallery -url %WEB_MYSITES_URL% -allowaccesstowebpartcatalog false
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Disabling CSS user permissions for %WEB_MYSITES_URL%
stsadm -o gl-disableuserpermissionforwebapp -url %WEB_MYSITES_URL% -applystylesheets
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Enabling self service site creation for %WEB_MYSITES_URL%
stsadm -o gl-setselfservicesitecreation -url %WEB_MYSITES_URL% -enabled true -requiresecondarycontact false
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting portal site connection for %WEB_MYSITES_URL%
stsadm -o gl-connecttoportalsite -url %WEB_MYSITES_URL% -portalurl %WEB_PORTAL_URL% -portalname %WEB_PORTAL_NAME%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting site naming format for %WEB_MYSITES_URL%:
stsadm -o gl-mysitesettings -sspname %WEB_SSP_NAME% -nameformat "Username_CollisionDomain" -searchcenter "%WEB_PORTAL_URL%SearchCenter/Pages"
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Resetting IIS
iisreset /noforce
if not errorlevel 0 goto errhnd


goto end

:errhnd

echo An error occured - terminating script.

:end