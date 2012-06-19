:: Batch file script to retrieve IIS Server App Pool Properties ::
:: Useful for retrieving the App Pool Password ::
:: Usage: Run as an administrator and supply the appropriate App Pool Name when prompted ::
@ECHO OFF
:Start
SET /P AppPoolName=Please Enter Your App Pool Name:
IF "%AppPoolName%"=="" GOTO Error
%systemroot%\system32\inetsrv\APPCMD list apppool "%AppPoolName%" /text:*
:Error
ECHO "That App Pool Name doesn't appear to exist, please try again"
GOTO Start
