## SQL Server: PowerShell Script To Script Out The Database Mail Configuration For Re-use From A SQL Instance ##

<#

Overview: Useful PowerShell Script To Connect To A SQL Instance and obtain the 'Database Mail' configuration options
for re-use on other SQL Server Instances.

Usage: Edit the '$ServerName' variable to match your environments source server you want to get the DB Mail config from

Resources:

http://www.ssistalk.com/2012/09/28/sql-scripting-out-db-mail-config-with-powershell-and-smo
http://sqlblog.com/blogs/jonathan_kehayias/archive/2010/08/23/scripting-database-mail-configuration-with-powershell-and-smo.aspx

#>

[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo");

$Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size (500, 25);

"sp_configure 'show advanced options',1
RECONFIGURE
GO
sp_configure 'Database Mail XPs',1
RECONFIGURE 
GO
"

#Set the server to script from 
$ServerName = "SQLServerInstance"; #Change the SQL Instance Name To Suit Your Environment

#Get a server object which corresponds to the default instance 
$srv = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Server $ServerName

#Script Database Mail configuration from the server 
$srv.Mail.Script();

ForEach ($account in $srv.Mail.Accounts) {
	$AccountName = $account.Name
	$MailServerName = $account.MailServers[0].Name;
	$MailServerPort = $account.MailServers[0].Port;
	"EXEC msdb.dbo.sysmail_update_account_sp @account_name = N'$AccountName',";
		"	@mailserver_name = N'$MailServerName',";
		"	@port = N'$MailServerPort'";
}
