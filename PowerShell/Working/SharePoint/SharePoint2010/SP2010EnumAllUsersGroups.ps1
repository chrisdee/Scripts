## SharePoint Server: PowerShell Script To Enumerate All Users In Groups Across All Sites In A Farm ##

<#

Overview: PowerShell Script that gets each SharePoint site in a farm, enumerates all users against groups in site collections, and dumps the output to screen and a CSV file.

Environments: SharePoint Server 2010 / 2013 Farms

Resource: http://basementjack.com/sharepoint-2/get-all-users-in-the-farm-sort-of

#>

Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue
 
$timestamp = get-date -format "yyyyMMdd_hhmmtt"
$filenameStart = "SPFarmUsers"
$logfile = ("{0}{1}.csv" -f $filenamestart, $timestamp)
 
$header = "type,user,group,weburl,webname"
$header | out-file -FilePath $logfile
 
$iissitelist = get-spwebapplication 
foreach($onesite in $iissitelist)
{
 
	foreach ($SiteCollection in $onesite.sites)
	{
		write-host $SiteCollection -foregroundcolor Blue	
		foreach ($web in $SiteCollection.Allwebs)
		{ 
			 write-host "    " $web.url $web.name "users:" -foregroundcolor yellow
			 # Write-host "        " $web.users | select name 
			 foreach ($userw in $web.users)
			 {
				#if ($userw -like "domain\*")
				#{
					write-host "        " $userw -foregroundcolor white
					#$msg = ("{0},{1} user:{2}" -f $web.url,$web.name, $userw)
					$msg = ("RootUser,{0},-,{1},{2}" -f $userw, $web.url,$web.name) 
					$msg | out-file -FilePath $logfile  -append
				#  }
			   }
 
 
			 foreach ($group in $web.Groups)
			{
						Write-host "        " $web.url $group.name: -foregroundcolor green
				 foreach ($user in $group.users)
				 { 
					# if ($user -like "Domain\*")
					 #{   
						  Write-host "            " $user -foregroundcolor white
						  #$msg = ("{0},{1},group:{2}, user:{3}" -f $web.url, $web.name, $group, $user)
						  $msg = ("GroupUser,{0},{1},{2},{3}" -f $user, $group, $web.url, $web.name)
						  $msg | out-file -FilePath $logfile  -append
					 #}
				 }
			}	
			$web.Dispose()
		}
 
	}
}