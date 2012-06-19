echo off

echo %DATE% %TIME%: Starting script

call variables.bat

goto startpoint
:startpoint


ECHO %DATE% %TIME%: Connecting to farm
psconfig -cmd configdb -connect -server %SERVER_DB_CONFIG% -database %DB_CONFIG_NAME% -user %ACCT_SPFARM% -password %ACCT_SPFARM_PWD%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Installing services
psconfig -cmd services install
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Installing features
psconfig -cmd installfeatures
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Setting security on registry and file system
psconfig -cmd secureresources
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Enabling the office sharepoint search service
stsadm -o osearch -action start -role Query -farmcontactemail %ACCT_SPADMIN_EMAIL% -farmperformancelevel maximum -farmserviceaccount %ACCT_SSPSEARCH% -farmservicepassword %ACCT_SSPSEARCH_PWD%
stsadm -o osearch -action start -role Query -farmcontactemail %ACCT_SPADMIN_EMAIL% -farmperformancelevel maximum -farmserviceaccount %ACCT_SSPSEARCH% -farmservicepassword %ACCT_SSPSEARCH_PWD% -propagationlocation %PATH_SSP_INDEXES%
if not errorlevel 0 goto errhnd

ECHO %DATE% %TIME%: Creating log file path
mkdir %PATH_LOGS%
if not errorlevel 0 goto errhnd


ECHO %DATE% %TIME%: Resetting IIS
iisreset /noforce
if not errorlevel 0 goto errhnd

goto end

:errhnd

echo An error occured - terminating script.

:end
