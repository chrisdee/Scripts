## SharePoint Server 2010: PowerShell Script to Enumerate Permissions for each Web Application ##

##Important: Script needs to be run with the Farm account or another account with sufficient farm administration rights

$logfilepath = "C:\BoxBuild\Scripts\PowerShell" #Change this path to suit your environment
 
##Create Table - ScanTable
$ScanTable = New-Object system.Data.DataTable "ScanTable"
$col1 = New-Object system.Data.DataColumn ("URL", [string])
$col2 = New-Object system.Data.DataColumn ("Member", [string])
$col3 = New-Object system.Data.DataColumn ("BasePermissions", [string])
$col4 = New-Object system.Data.DataColumn ("PermFriendlyName", [string])
$col5 = New-Object system.Data.DataColumn ("User_Group", [string])
$ScanTable.columns.add($col1)
$ScanTable.columns.add($col2)
$ScanTable.columns.add($col3)
$ScanTable.columns.add($col4)
$ScanTable.columns.add($col5)
 
$PermLevels = @{}
 
function getsec
{
	Add-PSSnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue
 
	$PortalName = Get-SPWebApplication | select DisplayName
	foreach ($p in $PortalName)
	{
		$webapp = Get-SPWebApplication | ? {$_.DisplayName -eq $p.Displayname}
		#$webapp = Get-SPWebApplication | ? {$_.DisplayName -eq "SharePoint"}
		foreach ($s in $webapp.Sites)
		{
			foreach ($web in $s.AllWebs)
			{
				foreach ($r in $web.roles)
				{
					$permpermmask = $r.PermissionMask
					$permname = $r.Name
					$PermLevels.Add("$permpermmask", "$permname")
					trap [Exception] {continue;}
				}
				$red = $web.HasUniqueRoleDefinitions
				foreach ($perm in $web.Permissions)
				{
					#$perm | select *
					#$perm.PermissionMask
					$permpermmaskcurrent = $perm.PermissionMask
					$level = $PermLevels.Get_Item("$permpermmaskcurrent")
					if ($perm.xml -like "*GroupName*")
					{
						$usergroup = "SharePoint Group"
					}
					if ($perm.xml -like "*UserLogin*")
					{
						$usergroup = "AD User"
					}
					$MemberIsADGroup = $perm.Member.IsDomainGroup
					if ($MemberIsADGroup -eq $true)
					{
						$usergroup = "AD Group"
					}
					$output = $ScanTable.Rows.Add($web.url, $perm.Member, $perm.BasePermissions, $level, $usergroup)
				}
			}
		}
	}
	$ScanTable.WriteXML("$logfilepath\SecurityReport.xml") #Change your report file name here
}
getsec