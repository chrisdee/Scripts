## Azure AD Connect: PowerShell Script to Get the Local SQL Instance Connection Details (Named Pipes)  ##

<#

Example of connection output to put into your SQL Client Connection: \\.\pipe\LOCALDB#SH618D23\tsql\query

Resource: https://itfordummies.net/2017/02/13/manage-localdb-aad-connect-sql-database

#>

$LocalSQLInstancePath = "C:\Program Files\Microsoft SQL Server\110\Tools\Binn" #Change this path if your local SQL instance path differs to the default installation location

Set-Location -Path $LocalSQLInstancePath

.\SqlLocalDB.exe info

.\SqlLocalDB.exe info .\ADSync