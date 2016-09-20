## PowerShell: PowerShell Function that Measures Page Load Times and HTTP Protocol Status Codes ##

<#

Overview: PowerShell Function that uses the 'System.Net.WebClient' to Measure Page Load Times, and HTTP Protocol Status Codes over a specified number of Times

Usage Example:

MeasurePageLoad "https://google.com" -Times 10

#>

Function MeasurePageLoad {

param($URL, $Times)
$i = 1
While ($i -lt $Times)
{$Request = New-Object System.Net.WebClient
$Request.UseDefaultCredentials = $true
$Start = Get-Date
$PageRequest = $Request.DownloadString($URL)
$TimeTaken = ((Get-Date) – $Start).Totalseconds
$StatusCode = [int][system.net.httpstatuscode]::ok
$Request.Dispose()
Write-Host Request $i took $TimeTaken Seconds with a $StatusCode  HTTP Status Code -ForegroundColor Green
$i ++}
}