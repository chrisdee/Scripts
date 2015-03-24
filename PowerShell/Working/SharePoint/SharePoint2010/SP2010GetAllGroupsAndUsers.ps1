## SharePoint: PowerShell Script to Get All Groups and Users From a Site Collection and Sub Sites ##

<#

Overview: PowerShell Script that Gets all Groups and Users from a Site Collection into a tab delimited output text file

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Edit the following variables below and run the script: '$ReportLocation';  '$URL'

Tip: You should be able to import the tab delimited data into Excel for better review / analysis (Excel --> Data --> From Text)

#>

### Start Variables ###
$ReportLocation = "C:\BoxBuild\SPUsersList.txt"
$URL= "https://yourspsite.com"
### End Variables ###

Add-PsSnapin Microsoft.SharePoint.PowerShell

$site = Get-SPSite $URL
 
#Write the Header to "Tab Separated Text File"
 "Site Name `t Group Name `t User Name “| out-file "$ReportLocation"
       
#Iterate through all Webs (All Sub rooms)
      foreach ($web in $site.AllWebs)
      {

#Write the Header to "Tab Separated Text File"
        "$($web.title) `t" | out-file "$ReportLocation" -append

#Get all Groups  
         foreach ($group in $Web.groups)
         {
                "`t $($Group.Name)" | out-file "$ReportLocation" -append
             
                        foreach ($user in $group.users)
                        {
                           #Exclude Built-in User Accounts                            

                                "`t `t $($user.name)" | out-file "$ReportLocation" -append
                        }
         }
     }

write-host "Report Generated at $ReportLocation"