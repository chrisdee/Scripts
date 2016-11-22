## PowerShell: Function to return the number of .NET Framework Versions Installed on a Client ##

function Get-DotNETFrameworkVersions()
{
Write-Host ""
Write-Host "Version Table on MSDN: https://msdn.microsoft.com/en-us/library/hh925568(v=vs.110).aspx"
Write-Host "Release 379893 is .NET Framework 4.5.2" -ForegroundColor "Yellow"
Write-Host ""
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
Get-ItemProperty -name Version,Release -EA 0 |
Where { $_.PSChildName -match '^(?!S)\p{L}'} |
Select PSChildName, Version, Release
}

Get-DotNETFrameworkVersions