::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Requires Gary Lapointe's STSADM Extensions for complete automation.
:: Place his WSP package into the %UtilitySolutions% directory.
:: http://stsadm.blogspot.com/2009/02/downloads.html
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::---------------Start Variables------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::

::------------------------------------------------::
::----------------- Set Tools --------------------::
::------------------------------------------------::
set SPLocation="%CommonProgramFiles%\Microsoft Shared\web server extensions\12"
set STSADM=%SPLocation%\BIN\stsadm.exe
set PSCONFIG=%SPLocation%\BIN\psconfig.exe
set UtilitySolutions=C:\temp
::------------------------------------------------::

::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::: Set SharePoint Farm Configurations ::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::
::-------------- Server Names---------------------::
set SQLServerName=YourSQLInstanceInstanceName
set SPWebFrontEndName=YourSharePointWebFrontEndServerName
set SPSearchIndex=YourSharePointIndexServerName
::------------------------------------------------::

::-------------- Web application ports -----------::
::-------- These ports are configurable ----------::
::------------------------------------------------::
set SPCentralAdminPort=90
set SPSSPPort=91
set SPMySitePort=81
set DefaultApplicationPort=80
::------------------------------------------------::

::---- Shared Services Provider Configurations ---::
:: You can leave most of these alone except for the index location ::
::------------------------------------------------::
set SPSSPName=SharedServices1
set SPSSPUrl=http://%SPWebFrontEndName%:%SPSSPPort%
set SPSSPWebAppName="Shared Services Provider"
set SPSSPDescription="SSP Host"
set SSPApplicationPoolName="SharedServices1"
set SPSearchIndexLocation=c:\temp\spsearchindexes
mkdir %SPSearchIndexLocation%
::------------------------------------------------::

::--------------- Database Names -----------------::
:: Change if you want or leave them as they are   ::
::------------------------------------------------::
set SPConfigDatabaseName=SharePoint_Config
set SPConfigContentDB=SharePoint_CentralAdmin_Content
set SPSearchDatabaseName=WSS_Search
set SPSSPConfigDatabaseName=%SPSSPName%_Config_DB
set SPSSPDatabaseName=%SPSSPName%_DB
set SPSSPSearchDatabaseName=%SPSSPName%_Search_DB
set SPMySiteContentDBName=WSS_Content_MySites
::------------------------------------------------::

::------------------------------------------------::
::-------- Central Admin Configurations ----------::
::------------------------------------------------::

::-------------- Email Settings ------------------::
set SPSearchContactEmail=email@emailcom
set SPOutboundSMTPServer=email@emailcom
set SPOutboundEmailFrom=email@emailcom
set SPReplyToEmail=email@emailcom
::------------------------------------------------::

::------------- Search Settings ------------------::
set SPSearchIndexPerformance=Reduced
:: Your options: < Reduced | PartlyReduced | Maximum >

set SPSearchRole=indexquery
:: Your options: < Index | Query | IndexQuery >
::------------------------------------------------::

::------------- Diagnostic Logging ---------------::
set SPDiagnosticLoggingThrottle=Verbose
:: Your options: < None | Unexpected | Monitorable | High | Medium | Verbose >

:: You can change this directory if you want
set SPDiagnosticLoggingDirectory=c:\temp\spdiagnostics
mkdir %SPDiagnosticLoggingDirectory%

set SPDiagnosticLoggingFileCount=10
:: Your options: <0-1024>

set SPDiagnosticLoggingFileMinutes=30
:: Your options: <0-1440>
::------------------------------------------------::

::------------ Usage Analysis Settings -----------::

:: You can change this directory if you want
set SPUsageAnalysisLogFileLocation=c:\temp\spusageanalysis

mkdir %SPUsageAnalysisLogFileLocation%
set SPUSageAnalysisLogFileCount=1
:: Your options: <0-30>

set SPUsageAnalysisJobStartTime=2:00AM
set SPUsageAnalysisJobEndTime=3:00AM
::------------------------------------------------::
::------------------------------------------------::

::------------------------------------------------::
::------ Main Content Web App Configurations -----::
::------------------------------------------------::
IF /i %DefaultApplicationPort%==80 (set OOBApplicationURL=http://%SPWebFrontEndName%) ELSE (set OOBApplicationURL=http://%SPWebFrontEndName%:%DefaultApplicationPort%)
ECHO Default web application port is %DefaultApplicationPort%

:: Optional Alternate Access Mapping configurations
::set NewAlternateAccessMapping=http://test
::set NewAlternateAccessMappingZone=Default 
:: <Default | Intranet | Internet | Extranet | Custom>
:: More AAM settings can be added here if necessary

set WebApplicationOwner=domain\henry.ong
set WebApplicationOwnerEmail=email@email.com
set WebApplicationOwnerDisplayName="Henry Ong"
set SPSiteTitle="Collaboration Portal"
set SPSiteDecription="This is a description for your site collection."
set ApplicationPoolName="Application Pool Name for this Web App"
set SPContentDBName=WSS_Content_AppName

set SPSiteTemplate=SPSPORTAL#0

:: Possible templates listed below
:: GLOBAL (Placeholder, no template) 
:: STS#0 (Team Site)
:: STS#1 (Blank Site)
:: STS#2 (Document Workspace)
:: MPS#0 (Basic Meeting Workspace)
:: MPS#1 (Blank Meeting Workspace)
:: MPS#2 (Descision Meeting Workspace)
:: MPS#3 (Social Meeting Workspace)
:: MPS#4 (Multipage Meeting Workspace)
:: CENTRALADMIN#0 (Central Administration)
:: WIKI#0 (Wiki Site)
:: BLOG#0 (Blog Site)
:: BDR#0 (Document Center)
:: OFFILE#1 (Records Center)
:: OSRV#0 (Shared Services Administration Site)
:: SPSPERS#0 (SharePoint Portal Server Personal Space ? Obsolete ?)
:: SPSMSITE#0 (Personalization Site)
:: CMSPUBLISHING#0 (Publishing Site)
:: BLANKINTERNET#0 (Publishing Site)
:: BLANKINTERNET#1 (Press Releases Site)
:: BLANKINTERNET#2 (Publishing Site with workflow)
:: SPSNHOME#0 (News Site)
:: SPSSITES#0 (Site Directory)
:: SPSREPORTCENTER#0 (Report Center)
:: SPSPORTAL#0 (Collaboration Portal)
:: SRCHCEN#0 (Search Center with Tabs)
:: PROFILES#0 (Profiles)
:: BLANKINTERNETCONTAINER#0 (Publishing Portal)
:: SPSMSITEHOST#0 (My Site Host)
:: SRCHCENTERLITE#0 (Search Center)
:: SRCHCENTERLITE#1 (Search Center)


::------------------------------------------------::
::------------ My Site Configurations ------------::
::------------------------------------------------::
set CreateNewWebApp=false
:: Your options: <true | false>
:: False will create the My Site under your default web app configured above. 

set MySiteApplicationURL=http://%SPWebFrontEndName%:%SPMySitePort%
::set MySiteAlternateAccessMapping=http://mysite******
::set MySiteAlternateAccessMappingZone=Default ******
:: Your options: <Default | Intranet | Internet | Extranet | Custom>
:: More AAM settings can be added if necessary

set MySiteWebApplicationOwner=domain\henry.ong
set MySiteWebApplicationOwnerEmail=email@email.com
set MySiteWebApplicationOwnerDisplayName="Henry Ong"
set SPMySiteTemplate=SPSMSITEHOST#0
set SPMySiteSiteDecription="My Site Host"
set MySiteApplicationPoolName="My Sites"
::------------------------------------------------::
::------------------------------------------------::

::------------------------------------------------::
::--------- Set SharePoint Service Accounts ------::
::--------------- All Configurable ---------------::
::------------------------------------------------::
set ServiceAccountSPFarm=domain\spdbaccess
set ServiceAccountSPFarmPassword=password

set ServiceAccountSSP=domain\spssp
set ServiceAccountSSPPassword=password

set ServiceAccountSPSearch=domain\spsearch
set ServiceAccountSPSearchPassword=password

set ServiceAccountContentAccess=domain\spcontentaccess
set ServiceAccountContentAccessPassword=password

set ServiceAccountMySite=domain\spmysite
set ServiceAccountMySitePassword=password

set ServiceAccountApplicationAppPool=domain\spapppool
set ServiceAccountApplicationAppPoolPassword=password
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::----------------------------------------------------------------:: END VARIABLES ::---------------------------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::
::------------------------------------------------::::------------------------------------------------::::------------------------------------------------::

::------------------------------------------------::
:: Creating Central Administration
::------------------------------------------------::
ECHO "Create Central Admin"

%PSCONFIG% -cmd configdb -create -server %SQLServerName% -database %SPConfigDatabaseName% -user %ServiceAccountSPFarm% -password %ServiceAccountSPFarmPassword% -admincontentdatabase %SPConfigContentDB%

%PSCONFIG% -cmd helpcollections -installall

%PSCONFIG% -cmd secureresources

%PSCONFIG% -cmd services -install

:: Use this if activating all the farm services on this server
::%PSCONFIG% -cmd services -provision

%PSCONFIG% -cmd installfeatures

%PSCONFIG% -cmd adminvs -provision -port %SPCentralAdminPort% -windowsauthprovider onlyusentlm

%PSCONFIG% -cmd applicationcontent -install
ECHO "Finished creating Central Admin..."


::------------------------------------------------::
:: Configuring Central Administration
::------------------------------------------------::
ECHO "Configuring Central Admin..."

%STSADM% -o addsolution -filename %UtilitySolutions%\Lapointe.SharePoint.STSADM.Commands.wsp
%STSADM% -o deploysolution -name Lapointe.SharePoint.STSADM.Commands.wsp -immediate -allowgacdeployment
%STSADM% -o execadmsvcjobs
%STSADM% -o spsearch -action start -farmperformancelevel %SPSearchIndexPerformance% -farmserviceaccount %ServiceAccountSPSearch% -farmservicepassword %ServiceAccountSPSearchPassword% -farmcontentaccessaccount %ServiceAccountContentAccess% -farmcontentaccesspassword %ServiceAccountContentAccessPassword% -databaseserver %SQLServerName% -databasename %SPSearchDatabaseName%
%STSADM% -o osearch -action start -role %SPSearchRole% -farmcontactemail %SPSearchContactEmail% -farmperformancelevel %SPSearchIndexPerformance% -farmserviceaccount %ServiceAccountSPSearch% -farmservicepassword %ServiceAccountSPSearchPassword%
%STSADM% -o email -outsmtpserver %SPOutboundSMTPServer% -fromaddress %SPOutboundEmailFrom% -replytoaddress %SPReplyToEmail% -codepage 65001
%STSADM% -o setlogginglevel -tracelevel %SPDiagnosticLoggingThrottle%
%STSADM% -o gl-tracelog -logdirectory %SPDiagnosticLoggingDirectory% -logfilecount %SPDiagnosticLoggingFileCount% -logfileminutes %SPDiagnosticLoggingFileMinutes%
ECHO "Finished configuring Central Admin..."

IISRESET /STOP /NOFORCE
IISRESET /START

::------------------------------------------------::
:: Create Initial Application Web App
::------------------------------------------------::
ECHO "Creating initial web application portal..."

%STSADM% -o extendvs -url %OOBApplicationURL% -ownerlogin %WebApplicationOwner% -owneremail %WebApplicationOwnerEmail% -exclusivelyusentlm -ownername %WebApplicationOwnerDisplayName% -databaseserver %SQLServerName% -databasename %SPContentDBName% -donotcreatesite -description %SPSiteTitle% -apidname %ApplicationPoolName% -apidtype configurableid -apidlogin %ServiceAccountApplicationAppPool% -apidpwd %ServiceAccountApplicationAppPoolPassword%
%STSADM% -o createsite -url %OOBApplicationURL% -owneremail %WebApplicationOwnerEmail% -ownerlogin %WebApplicationOwner% -ownername %WebApplicationOwnerDisplayName% -sitetemplate %SPSiteTemplate% -title %SPSiteTitle% -description %SPSiteDecription% 
ECHO "Finished creating initial web application portal..."

::------------------------------------------------::
:: Create My Site Web App
::------------------------------------------------::
ECHO "Creating My Site Host..."

IF /i %CreateNewWebApp%==true (goto CreateNewMySiteWebApp) ELSE (goto CreateNewMySiteExistingWebApp)

:CreateNewMySiteWebApp 
ECHO "Creating new My Site Web App"
%STSADM% -o extendvs -url %MySiteApplicationURL% -ownerlogin %MySiteWebApplicationOwner% -owneremail %MySiteWebApplicationOwnerEmail% -exclusivelyusentlm -ownername %MySiteWebApplicationOwnerDisplayName% -databaseserver %SQLServerName% -databasename %SPMySiteContentDBName% -sitetemplate %SPMySiteTemplate% -description %SPMySiteSiteDecription% -apidname %MySiteApplicationPoolName% -apidtype configurableid -apidlogin %ServiceAccountMySite% -apidpwd %ServiceAccountMySitePassword%
%STSADM% -o enablessc -url %MySiteApplicationURL%
set MySiteURL=%MySiteApplicationURL%
ECHO "Finished Creating My Site Host..."

GOTO SSP

:CreateNewMySiteExistingWebApp
ECHO "Creating My Site Host using existing web app"
%STSADM% -o addpath -url %OOBApplicationURL%/MySites -type explicitinclusion
:: <ExplicitInclusion | WildcardInclusion>
%STSADM% -o enablessc -url %OOBApplicationURL%/MySites 


%STSADM% -o createsite -url %OOBApplicationURL%/MySites -oe %MySiteWebApplicationOwnerEmail% -ol %MySiteWebApplicationOwner% -on %MySiteWebApplicationOwnerDisplayName% -lcid 1033 -st %SPMySiteTemplate% -t %SPMySiteSiteDecription% -desc %SPMySiteSiteDecription%  
set MySiteURL=%OOBApplicationURL%/MySites/
ECHO "Finished Creating My Site Host..."

GOTO SSP

:SSP
::------------------------------------------------::
:: Create SSP
::------------------------------------------------::
ECHO "Creating SSP..."
%STSADM% -o extendvs -url %SPSSPUrl% -exclusivelyusentlm -databaseserver %SQLServerName% -databasename %SPSSPDatabaseName% -donotcreatesite -description %SPSSPWebAppName% -apidname %SSPApplicationPoolName% -apidtype configurableid -apidlogin %ServiceAccountSSP% -apidpwd %ServiceAccountSSPPassword%

IISRESET /STOP /NOFORCE
IISRESET /START

%STSADM% -o createssp -title %SPSSPName% -url %SPSSPUrl% -mysiteurl %MySiteURL% -ssplogin %ServiceAccountSSP% -indexserver %SPSearchIndex% -indexlocation %SPSearchIndexLocation% -ssppassword %ServiceAccountSSPPassword% -sspdatabaseserver %SQLServerName% -sspdatabasename %SPSSPConfigDatabaseName% -searchdatabaseserver %SQLServerName% -searchdatabasename %SPSSPSearchDatabaseName% -ssl no
ECHO "Finished Creating SSP..."

ECHO "Ignore Syntax error messages if not using alternate access mapping configurations in this script."

%STSADM% -o gl-setusageanalysis -enablelogging true -enableusageprocessing true -logfilelocation %SPUsageAnalysisLogFileLocation% -numberoflogfiles %SPUSageAnalysisLogFileCount% -processingstarttime %SPUsageAnalysisJobStartTime% -processingendtime %SPUsageAnalysisJobEndTime% -sspname %SPSSPName% -enableadvancedprocessing true -enablequerylogging true
%STSADM% -o addalternatedomain -url %OOBApplicationURL% -incomingurl %NewAlternateAccessMapping% -urlzone %NewAlternateAccessMappingZone%
%STSADM% -o addzoneurl -url %NewAlternateAccessMapping% -urlzone %NewAlternateAccessMappingZone% -zonemappedurl %NewAlternateAccessMapping%

ECHO Done!
PAUSE
