echo off

echo %DATE% %TIME%: Starting script

call variables.bat

goto startpoint
:startpoint
rem *** NOTE: The order of the following psconfig statements is critical - do not re-order.
ECHO %DATE% %TIME%:  Building configuration database
psconfig -cmd configdb -create -server %SERVER_DB_CONFIG% -database %DB_CONFIG_NAME% -user %ACCT_SPFARM% -password %ACCT_SPFARM_PWD% -admincontentdatabase %DB_CENTRALADMINCONTENT_NAME% 
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Installing help content
psconfig -cmd helpcollections -installall 
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Securing resources
psconfig -cmd secureresources 
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Installing services
psconfig -cmd services -install 
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Installing features
psconfig -cmd installfeatures 
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Creating central admin site
psconfig -cmd adminvs -provision -port %CENTRALADMIN_PORT% -windowsauthprovider enablekerberos 
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Adding application content to central admin site
psconfig -cmd applicationcontent -install
if not errorlevel 0 goto errhnd

pause

ECHO %DATE% %TIME%: Installing custom stsadm extensions
stsadm -o addsolution -filename "Lapointe.SharePoint.STSADM.Commands.wsp"
stsadm -o deploysolution -local -allowgacdeployment -name "Lapointe.SharePoint.STSADM.Commands.wsp"
stsadm -o execadmsvcjobs

REM ====================================
REM ======= BEGIN SERVICES CONFIG ======
REM ====================================

echo %DATE% %TIME%: BEGINNING SERVICES CONFIGURATIONS...
echo

ECHO %DATE% %TIME%: Enabling sharepoint services help search service
stsadm -o spsearch -action start -farmserviceaccount %ACCT_SEARCH_HELP% -farmservicepassword %ACCT_SEARCH_HELP_PWD% -farmperformancelevel maximum -farmcontentaccessaccount %ACCT_CONTENT_HELP% -farmcontentaccesspassword %ACCT_CONTENT_HELP_PWD% -indexlocation %PATH_HELPSEARCH_INDEXES% -databaseserver %SERVER_DB_SEARCH% -databasename %DB_SEARCHHELP_NAME%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Enabling the office sharepoint search service
stsadm -o osearch -action start -role Index -farmcontactemail %ACCT_SPADMIN_EMAIL% -farmperformancelevel maximum -farmserviceaccount %ACCT_SSPSEARCH% -farmservicepassword %ACCT_SSPSEARCH_PWD% -defaultindexlocation %PATH_SSP_INDEXES%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Starting excel calculation services
stsadm -o provisionservice -action start -servicetype "Microsoft.Office.Excel.Server.ExcelServerSharedWebService, Microsoft.Office.Excel.Server, Version = 12.0.0.0, Culture = neutral, PublicKeyToken = 71e9bce111e9429c"
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Starting Document Conversions Load Balancer Service
stsadm -o provisionservice -action start -servicetype "Microsoft.Office.Server.Conversions.LoadBalancerService, Microsoft.Office.Server.Conversions, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" -servicename DCLoadBalancer
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Starting Document Conversions Launcher Service 
stsadm -o provisionservice -action start -servicetype "Microsoft.Office.Server.Conversions.LauncherService, Microsoft.Office.Server.Conversions, Version=12.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" -servicename DCLauncher
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Resetting IIS
iisreset /noforce
if not errorlevel 0 goto errhnd


ECHO %DATE% %TIME%: Adding %ACCT_SPADMIN% to Farm Administrators group
stsadm -o adduser -url "http://localhost:%CENTRALADMIN_PORT%" -userlogin %ACCT_SPADMIN% -group "Farm Administrators" -username %ACCT_SPADMIN_NAME% -useremail %ACCT_SPADMIN_EMAIL%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Adding %ACCT_SPADMIN_GROUPNAME% to Farm Administrators group
stsadm -o gl-adduser2 -url "http://localhost:%CENTRALADMIN_PORT%" -userlogin %ACCT_SPADMIN_GROUPNAME% -group "Farm Administrators" -username %ACCT_SPADMIN_NAME%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting outbound email settings
stsadm -o email -outsmtpserver %SERVER_MAIL% -fromaddress %ACCT_SPADMIN_EMAIL% -replytoaddress %ACCT_SPADMIN_EMAIL% -codepage 65001
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting default content database server to %SERVER_DB_DEFAULTCONTENT%
stsadm -o setproperty -pn defaultcontentdb-server -pv %SERVER_DB_DEFAULTCONTENT%
if not errorlevel 0 goto errhnd

echo
echo %DATE% %TIME%: FINISHED SERVICES CONFIGURATIONS
echo TODO: Set Load Balancer Server and Port
pause

REM ====================================
REM ======= END SERVICES CONFIG ========
REM ====================================

echo
echo


REM ====================================
REM ========= BEGIN SSP ================
REM ====================================
echo %DATE% %TIME%: BEGINNING SSP SETTINGS
echo

ECHO %DATE% %TIME%: Creating the My Sites web application
stsadm -o gl-createwebapp -url %WEB_MYSITES_URL% -directory %PATH_MYSITESVDIR% -sethostheader -ownerlogin %ACCT_SPADMIN% -owneremail %ACCT_SPADMIN_EMAIL% -description %WEB_MYSITES_IISDESC% -apidname %WEB_MYSITES_APPIDNAME% -apidtype configurableid -apidlogin %ACCT_MYSITESAPPPOOL% -apidpwd %ACCT_MYSITESAPPPOOL_PWD% -databaseserver %SERVER_DB_MYSITES% -databasename %DB_MYSITES_NAME% -donotcreatesite -timezone 12
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Creating SSP Admin site.
stsadm -o gl-createwebapp -url %WEB_SSP_URL% -directory %PATH_SSPVDIR% -sethostheader -ownerlogin %ACCT_SPADMIN% -owneremail %ACCT_SPADMIN_EMAIL% -description %WEB_SSP_IISDESC% -apidname %WEB_SSP_APPIDNAME% -apidtype configurableid -apidlogin %ACCT_SSPAPPPOOL% -apidpwd %ACCT_SSPAPPPOOL_PWD% -databaseserver %SERVER_DB_CONFIG% -databasename %DB_SSPCONTENT_NAME% -donotcreatesite -timezone 12
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Creating the Shared Service Provider
stsadm -o createssp -title %WEB_SSP_NAME% -url %WEB_SSP_URL% -mysiteurl %WEB_MYSITES_URL% -ssplogin %ACCT_SSPSVC% -indexserver %SERVER_INDEX% -indexlocation %PATH_SSP_INDEXES% -ssppassword %ACCT_SSPSVC_PWD% -sspdatabaseserver %SERVER_DB_CONFIG% -sspdatabasename %DB_SSPCONFIG_NAME% -searchdatabaseserver %SERVER_DB_SEARCH% -searchdatabasename %DB_SEARCHCONTENT_NAME% -ssl no
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Resetting IIS
iisreset /noforce
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting the new SSP as the default SSP
stsadm -o setdefaultssp -title %WEB_SSP_NAME%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Giving %ACCT_SPADMIN_GROUPNAME% all permissions to SSP
stsadm -o gl-setsspacl -sspname %WEB_SSP_NAME% -rights All -user %ACCT_SPADMIN_GROUPNAME%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Giving %ACCT_SSPUSERPROFILESVC% profile management permissions
stsadm -o gl-setsspacl -sspname %WEB_SSP_NAME% -rights ManageUserProfiles -user %ACCT_SSPUSERPROFILESVC%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Giving %ACCT_SSPSEARCH% profile management permissions
stsadm -o gl-setsspacl -sspname %WEB_SSP_NAME% -rights ManageUserProfiles -user %ACCT_SSPSEARCH%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting usage analysis settings
mkdir %PATH_USAGELOGS%
stsadm -o gl-setusageanalysis -enablelogging true -enableusageprocessing true -logfilelocation %PATH_USAGELOGS% -numberoflogfiles 30 -processingstarttime "10:00PM" -processingendtime "1:00AM" -sspname %WEB_SSP_NAME% -enableadvancedprocessing true -enablequerylogging true
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Enabling kerberos on the SSP
stsadm -o setsharedwebserviceauthn -negotiate
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting delegation for excel services (to enable Kerberos)
stsadm -o set-ecssecurity -ssp %WEB_SSP_NAME% -accessmodel delegation 
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating excel services unattended service account
stsadm -o set-ecsexternaldata -ssp %WEB_SSP_NAME% -unattendedserviceaccountname %ACCT_EXCEL_USER% -unattendedserviceaccountpassword %ACCT_EXCEL_PWD%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Updating default content access account
stsadm -o gl-updatedefaultcontentaccessaccount -username %ACCT_SSPCONTENT% -password %ACCT_SSPCONTENT_PWD%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting user profile default access account
stsadm -o gl-setuserprofiledefaultaccessaccount -username %ACCT_SSPUSERPROFILESVC% -password %ACCT_SSPUSERPROFILESVC_PWD% -sspname %WEB_SSP_NAME%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Running pending jobs
stsadm -o execadmsvcjobs
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting user profile full import schedule
stsadm -o gl-setuserprofileimportschedule -sspname %WEB_SSP_NAME% -type full -occurrence weekly -hour 3 -dayofweek Saturday -enabled true -runjob
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting user profile incremental import schedule
stsadm -o gl-setuserprofileimportschedule -sspname %WEB_SSP_NAME% -type incremental -occurrence daily -hour 22 -enabled true
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Executing pending timer jobs
stsadm.exe -o execadmsvcjobs 
if not errorlevel 0 goto errhnd

echo
echo %DATE% %TIME%: FINISHED SSP SETTINGS

REM ====================================
REM =========== END SSP ================
REM ====================================

echo
echo

REM ====================================
REM =========== BEGIN PORTAL =============
REM ====================================
:portal
echo %DATE% %TIME%: BEGINNING PORTAL CORE SETTINGS
echo
call portal.bat
echo
echo %DATE% %TIME%: FINISHED PORTAL CORE SETTINGS
pause

REM ====================================
REM ============ END PORTAL ==============
REM ====================================



echo
echo


REM ====================================
REM =========== BEGIN TEAMS =============
REM ====================================
:teams
echo %DATE% %TIME%: BEGINNING TEAMS CORE SETTINGS
echo
call teams.bat
echo
echo %DATE% %TIME%: FINISHED TEAMS CORE SETTINGS
pause

REM ====================================
REM ============ END TEAMS ==============
REM ====================================


echo
echo

REM ====================================
REM ======= BEGIN MY SITES =============
REM ====================================
:mysites
echo %DATE% %TIME%: BEGINNING MY SITES SETTINGS
echo
call mysites.bat
echo
echo %DATE% %TIME%: FINISHED MY SITES SETTINGS
pause
REM ====================================
REM ========= END MY SITES =============
REM ====================================

echo
echo

ECHO ******************* Run Connect.bat on each WFE **************************
pause

ECHO %DATE% %TIME%: Setting log file path
mkdir %PATH_LOGS%
stsadm -o gl-tracelog -logdirectory %PATH_LOGS%
if not errorlevel 0 goto errhnd

echo
echo

ECHO %DATE% %TIME%: TODO 1 - Configure searching (http://sspadmin/ssp/admin/_layouts/listcontentsources.aspx)

goto end

:errhnd

echo An error occured - terminating script.

:end
