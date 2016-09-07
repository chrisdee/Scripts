## IIS Server: PowerShell Script to List All Web Applications and Their Identity Details within an IIS Server ##

<# 

Overview: Uses the 'WebAdministration' PowerShell module to List All Web Applications and Their App Pool Identity Details within an IIS Server

Resource: https://melcher.it/2013/03/powershell-list-all-iis-webapplications-net-version-state-identity

Sample Output:

WebAppName	Version	State	UserIdentityType	Username	Password
SharePoint – 80	v2.0	Started	SpecificUser	demo\spservices	pass@word1

#>

try{
Import-Module WebAdministration
Get-WebApplication
 
$webapps = Get-WebApplication
$list = @()
foreach ($webapp in get-childitem IIS:\AppPools\)
{
$name = "IIS:\AppPools\" + $webapp.name
$item = @{}
 
$item.WebAppName = $webapp.name
$item.Version = (Get-ItemProperty $name managedRuntimeVersion).Value
$item.State = (Get-WebAppPoolState -Name $webapp.name).Value
$item.UserIdentityType = $webapp.processModel.identityType
$item.Username = $webapp.processModel.userName
$item.Password = $webapp.processModel.password
 
$obj = New-Object PSObject -Property $item
$list += $obj
}
 
$list | Format-Table -a -Property "WebAppName", "Version", "State", "UserIdentityType", "Username", "Password"
 
}catch
{
$ExceptionMessage = "Error in Line: " + $_.Exception.Line + ". " + $_.Exception.GetType().FullName + ": " + $_.Exception.Message + " Stacktrace: " + $_.Exception.StackTrace
$ExceptionMessage
}