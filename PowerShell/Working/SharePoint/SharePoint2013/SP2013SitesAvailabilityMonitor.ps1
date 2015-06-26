## SharePoint Server: PowerShell Script to Monitor Site Collections Availability With HTML Report Output ##

<#

Overview: PowerShell Script that uses SharePoint commandlets to get a list of all site collections into a text file so that these can be checked with a web request (Invoke-WebRequest), and their availability status reported into a HTML report file

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the variables below to suit your requirements and run the script. If you don't want to launch the HTML report in a browser after running the script comment out the 'Invoke-Expression' command at the end of the script

#>

######################## Start Variables ########################
$ReportLastRun = Get-Date -format 'f' #Change the date format to suite your requirements
$SitesFilePath = "C:\BoxBuild\Scripts\URLList.txt" #Change the path to the Site Collections list text file to match your environment
$ReportFilePath = "C:\BoxBuild\Scripts\SPSiteAvailabilityMonitor.htm" #Change the path to the Sites Availability Monitor HTML report
$SPWebApplication = "https://YourWebApp.com" #Provide your Web Application URL here
######################## End Variables ########################

## Get a list of all Site Collections
Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue
Get-SPWebApplication "$SPWebApplication" | Get-SPSite -Limit ALL | Format-Table -Property URL | Out-File "$SitesFilePath"

## Strip out headers and white spaces in the Sites list text file
(Get-Content "$SitesFilePath") | Foreach-Object {$_ -replace "Url", ""}  | Foreach-Object {$_ -replace "---", ""} | ? {$_.trim() -ne "" } | set-content "$SitesFilePath"
 
## The URI list to test 
$URLListFile = "$SitesFilePath"  
$URLList = Get-Content $URLListFile -ErrorAction SilentlyContinue 
  $Result = @() 
      
  Foreach($Uri in $URLList) { 
  $time = try{ 
  $request = $null 
   ## Request the URI, and measure how long the response took. 
  $result1 = Measure-Command { $request = Invoke-WebRequest -Uri $uri -UseDefaultCredential} 
  $result1.TotalMilliseconds 
  }  
  catch 
  { 
   <# If the request generated an exception (i.e.: 500 server 
   error or 404 not found), we can pull the status code from the 
   Exception.Response property #> 
   $request = $_.Exception.Response 
   $time = -1 
  }   
  $result += [PSCustomObject] @{ 
  Time = Get-Date; 
  Uri = $uri; 
  StatusCode = [int] $request.StatusCode; 
  StatusDescription = $request.StatusDescription; 
  ResponseLength = $request.RawContentLength; 
  TimeTaken =  $time;  
  } 
 
} 
    #Prepare email body in HTML format 
if($result -ne $null) 
{ 
    $Outputreport = "<HTML><TITLE>Website Availability Report</TITLE><BODY background-color:white><font color =""#336699"" face=""verdana""><H3> Website Availability Report - $ReportLastRun </H3></font><Table border=1 cellpadding=1 cellspacing=1><TR bgcolor=LightSlateGray align=center><TD><B>URL</B></TD><TD><B>StatusCode</B></TD><TD><B>StatusDescription</B></TD><TD><B>ResponseLength</B></TD><TD><B>TimeTaken</B></TD</TR>" 
    Foreach($Entry in $Result) 
    { 
        if($Entry.StatusCode -ne "200") 
        { 
            $Outputreport += "<TR bgcolor=red>" 
        } 
        else 
        { 
            $Outputreport += "<TR>" 
        } 
        $Outputreport += "<TD>$($Entry.uri)</TD><TD align=center>$($Entry.StatusCode)</TD><TD align=center>$($Entry.StatusDescription)</TD><TD align=center>$($Entry.ResponseLength)</TD><TD align=center>$($Entry.timetaken)</TD></TR>" 
    } 
    $Outputreport += "</Table></BODY></HTML>" 
} 
 
$Outputreport | out-file "$ReportFilePath" 
Invoke-Expression "$ReportFilePath"  #Keep this line here if you want to launch the HTML report straight after running the script