## PowerShell: Useful Script to display Get-Date Format Info Options ##

## Resources: http://jdhitsolutions.com/blog/2014/10/powershell-dates-times-and-formats; http://msdn.microsoft.com/en-us/library/system.globalization.datetimeformatinfo%28VS.85%29.aspx

$patterns = "d","D","g","G","f","F","m","o","r","s", "t","T","u","U","Y","dd","MM","yyyy","yy","hh","mm","ss","yyyyMMdd","yyyyMMddhhmm","yyyyMMddhhmmss"

Write-host "It is now $(Get-Date)" -ForegroundColor Green

foreach ($pattern in $patterns) {

#create an Object
[pscustomobject]@{
 Pattern = $pattern
 Syntax = "Get-Date -format '$pattern'"
 Value = (Get-Date -Format $pattern)
}

} #foreach

Write-Host "Most patterns are case sensitive" -ForegroundColor Green