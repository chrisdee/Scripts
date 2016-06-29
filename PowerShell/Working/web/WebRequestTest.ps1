## PowerShell: Web Request Test Script ##

<#>

Overview: PowerShell Script that demonstrates how PowerShell can be used for Web Request calls to return HTTP Content

Usage Example: Provide values for the following 2 parameters when running the script - '$target'; '$verb'

Supply values for the following parameters:
target: http://www.posttestserver.com/
verb: POST


<#>

[CmdletBinding()]
Param(
  
  
    [Parameter(Mandatory=$True,Position=1)]
    [string] $target,
  
    [Parameter(Mandatory=$True,Position=2)]
    [string] $verb,      
  
    [Parameter(Mandatory=$False,Position=3)]
    [string] $content
  
)
  
  
write-host "Http Url: $target"
write-host "Http Verb: $verb"
write-host "Http Content: $content"
  
 
  
$webRequest = [System.Net.WebRequest]::Create($target)
$encodedContent = [System.Text.Encoding]::UTF8.GetBytes($content)
$webRequest.Method = $verb
$WebRequest.UseDefaultCredentials = $True #Use this method to try prevent the 'The remote server returned an error: (401) Unauthorized Error'
  
write-host "UTF8 Encoded Http Content: $content"
if($encodedContent.length -gt 0) {
    $webRequest.ContentLength = $encodedContent.length
    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($encodedContent, 0, $encodedContent.length)
    $requestStream.Close()
}
  
[System.Net.WebResponse] $resp = $webRequest.GetResponse();
if($resp -ne $null) 
{
    $rs = $resp.GetResponseStream();
    [System.IO.StreamReader] $sr = New-Object System.IO.StreamReader -argumentList $rs;
    [string] $results = $sr.ReadToEnd();
  
    return $results
}
else
{
    exit ''
}
