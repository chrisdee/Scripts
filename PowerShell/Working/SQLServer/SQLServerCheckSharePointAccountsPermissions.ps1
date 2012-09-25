## SharePoint Server: PowerShell Script To Check Service Accounts Permissions Set On A SQL Server Instance ##

<#

Overview: PowerShell script that connects to a SQL Server Instance checking some details related to the SQL Instance, and also checks 
server roles for the service account.

Resource: http://sharemypoint.in/2011/04/18/powershell-script-to-check-sql-server-connectivity-version-custering-status-user-permissions

#>


$currentUser = "$env:USERDOMAIN\$Env:USERNAME" #Add your environment specific DOMAIN and USERNAME here
$sqlServer = "SQLINSTANCE" #Add your environment specific SQL Instance here

$serverRolesToCheck = "dbcreator","securityadmin"

#$serverRolesToCheck = "sysadmin","dbcreator","diskadmin","processadmin",`
#					  "serveradmin","setupadmin","securityadmin","fake"

$objSQLConnection = New-Object System.Data.SqlClient.SqlConnection
$objSQLCommand = New-Object System.Data.SqlClient.SqlCommand

Try {

	$objSQLConnection.ConnectionString = "Server=$sqlServer;Integrated Security=SSPI;"
	Write-Host "Trying to connect to SQL Server instance on $sqlServer..." -NoNewline
	$objSQLConnection.Open() | Out-Null
	Write-Host "Success."

	$strCmdSvrDetails = "SELECT SERVERPROPERTY('productversion') as Version"
	$strCmdSvrDetails += ",SERVERPROPERTY('IsClustered') as Clustering"
	$objSQLCommand.CommandText = $strCmdSvrDetails
	$objSQLCommand.Connection = $objSQLConnection
	$objSQLDataReader = $objSQLCommand.ExecuteReader()
	if($objSQLDataReader.Read()){
		Write-Host ("SQL Server version is: {0}" -f $objSQLDataReader.GetValue(0))
		if ($objSQLDataReader.GetValue(1) -eq 1){
			Write-Host "This instance of SQL Server is clustered"
		} else {
			Write-Host "This instance of SQL Server is not clustered"
		}
	}
	$objSQLDataReader.Close()

	ForEach($serverRole in $serverRolesToCheck) {
		$objSQLCommand.CommandText = "SELECT IS_SRVROLEMEMBER('$serverRole')"
		$objSQLCommand.Connection = $objSQLConnection
		Write-Host "Check if $currentUser has $serverRole server role..." -NoNewline
		$objSQLDataReader = $objSQLCommand.ExecuteReader()
		if ($objSQLDataReader.Read() -and $objSQLDataReader.GetValue(0) -eq 1){
			Write-Host -BackgroundColor Green -ForegroundColor White "Pass"
		}
		elseif($objSQLDataReader.GetValue(0) -eq 0) {
			Write-Host -BackgroundColor Red -ForegroundColor White "Fail"
		}
		else {
			Write-Host -BackgroundColor Red -ForegroundColor White "Invalid Role"
		}
		$objSQLDataReader.Close()
	}

	$objSQLConnection.Close()
}
Catch {
	Write-Host -BackgroundColor Red -ForegroundColor White "Fail"
	$errText =  $Error[0].ToString()
	if ($errText.Contains("network-related")){
		Write-Host "Connection Error. Check server name, port, firewall."
	}
	elseif ($errText.Contains("Login failed")){
		Write-Host "Not able to login. SQL Server login not created."
	}
	Write-Host $errText
}