## SharePoint Server 2010: PowerShell Script To Enumerate User Permissions Across Web Apps And Site Collections ##

<#

Overview: Useful script with lots of parameters and output formatting options to query user and group permissions across web applications, sites, and lists

Resource: http://sharepointpsscripts.codeplex.com/releases/view/21699

Script Name: Get-EffectiveSPPermissions.ps1

Usage Examples:

./Get-EffectiveSPPermissions.ps1 -url "http://YourWebApp.com"
./Get-EffectiveSPPermissions.ps1 -url "http://YourWebApp.com/YourSite"
./Get-EffectiveSPPermissions.ps1 -url "http://YourWebApp.com" -formatoutput
./Get-EffectiveSPPermissions.ps1 -url "http://YourWebApp.com/YourSite" -formatoutput
./Get-EffectiveSPPermissions.ps1 -url "http://YourWebApp.com" | ConvertTo-Csv
./Get-EffectiveSPPermissions.ps1 -url "http://YourWebApp.com/YourSite" | ConvertTo-Csv
./Get-EffectiveSPPermissions.ps1 -url "http://YourWebApp.com" | ConvertTo-Csv | Out-File "Users.csv"
./Get-EffectiveSPPermissions.ps1 -url "http://YourWebApp.com/YourSite" | ConvertTo-Csv | Out-File "Users.csv"
./Get-EffectiveSPPermissions.ps1 -url "http://YourWebApp.com" | ConvertTo-Html | Out-File "Users.html"
./Get-EffectiveSPPermissions.ps1 -url "http://YourWebApp.com/YourSite" | ConvertTo-Html | Out-File "Users.html"

#>

##.SYNOPSIS    
## Retrieves effective permissions for a specified Windows user/group account or all accounts for any part of a SharePoint web application
##
##.DESCRIPTION
## The Get-EffectiveSPPermissions.ps1 script traverses SharePoint content structure starting from a given level (a single list item, list, site, site collection or web application) and reports all unique (not inherited) permissions within this scope for all Windows users/groups or for a specified user/group.
##
## The script has two reporting modes as governed by the -sconly parameter - it can either return each permission as a separate object or it can summarize and only return a single object for each security principal (user or group) that has access to at least some content within a particular site collection.
##
## The output of the script is an array of custom objects (PSObjects) which can be used further in a pipeline - for additional filtering, custom formatting or exporting (e.g. producing an HTML report with ConvertTo-Html cmdlet).
##
##.PARAMETER url
## A URL identifying the reporting scope (web application, site collection, site, list or list item). This parameter is required. 
##
## IMPORTANT: If a base URL is specified (e.g. http://sharepoint.contoso.com), the way it is interpreted depends on the presence or absence of the trailing slash. The slash is regarded as root site collection identifier, so if it is present the script will report on all unique permissions within the root site collection only; if the slash is not present, the scope will be assumed to be the entire web application.
##
##.PARAMETER principal
## Name of the Windows/Active Directory user or group account to be included in the report. If this parameter is specified, the results will be limited only to permissions that the specified account has within the specified scope.
##
## The syntax for this parameter is 'DOMAIN\username'. This parameter is optional.
##
##.PARAMETER nolists
## Switch parameter that excludes lists and libraries from the results (if the entry point is a site or higher). If present, only subwebs with unique permissions will be analyzed, rather then all subwebs.
##
## This is quite important, as it can make the processing significantly faster, especially for large web applications/site collections.
## 
##.PARAMETER nofolders
## Switch parameter that excludes folders in libraries from the results (if the entry point is a site or higher). If present, only lists and libraries with unique permissions will be analyzed, rather then all lists.
##
## This is quite important, as it can make the processing significantly faster, especially for large web applications/site collections.
## 
##.PARAMETER noitems
## Switch parameter that excludes individual list items from the results (if the entry point is a list or higher). If present, only lists and libraries with unique permissions will be analyzed, rather then all lists.
##
## This is quite important, as it can make the processing significantly faster, especially for large web applications/site collections.
## 
##.PARAMETER sconly
## Switch parameter defining the reporting mode. If present, each Windows user/group account will be only reported once per site collection, and with no details of the actual permissions that account has.
## 
## This is used to produce more generic reports on ALL accounts that have some sort of access to something within a particular site collection.
##
##.PARAMETER showlimited
## Switch parameter that if present instructs the script to include 'Limited Access' type permissions in the result. By default permissions of this level are ignored.
##
##.PARAMETER formatoutput
## Switch parameter instructing the script to return a formatted table of results rather than a 'raw' collection of objects.
##
## This is used for conveniently viewing the results immediately in the PowerShell console, without additional processing or redirecting output.
##
##.EXAMPLE
## PS C:\> .\Get-EffectiveSPPermissions.ps1 -url http://sharepoint.contoso.com/sites/testsite -formatOutput
##
## Description
## -----------
## This example returns all unique permissions within the specified site collection as a formatted table.
## 
## It produces the following output:
##
## User Login            User Name      Permissions
## ----------            ---------      -----------
## CONTOSO\lbarnes       Lucy Barnes    Item URL:       http://sharepoint.contoso.com/sites/testsite/subsite1/Shared
##                                       Documents/dropdown.htm
##                                      Item Name:
##                                      Item Type:      ListItem
##                                      As Member Of:
##                                      Permissions:    Contribute
## 
## 
## CONTOSO\administrator {}             Item URL:       http://sharepoint.contoso.com/sites/testsite/subsite1/Shared
##                                       Documents/dropdown.htm
##                                      Item Name:
##                                      Item Type:      ListItem
##                                      As Member Of:   Subsite1 Owners
##                                      Permissions:    Full Control
## 
##                                      Item URL:       http://sharepoint.contoso.com/sites/testsite/subsite1
##                                      Item Name:      Subsite1
##                                      Item Type:      Site
##                                      As Member Of:   Subsite1 Owners
##                                      Permissions:    Full Control
## 
##                                      Item URL:       http://sharepoint.contoso.com/sites/testsite
##                                      Item Name:      Site Admins Test
##                                      Item Type:      Site
##                                      As Member Of:   Power Contributors
##                                      Permissions:    Extended Contribute
## 
## 
## CONTOSO\semartin      Sean Martin    Item URL:       http://sharepoint.contoso.com/sites/testsite
##                                      Item Name:      Site Admins Test
##                                      Item Type:      Site
##                                      As Member Of:   Power Contributors
##                                      Permissions:    Extended Contribute
## 
## CONTOSO\dabarnes      David Barnes   Item URL:       http://sharepoint.contoso.com/sites/testsite
##                                      Item Name:      Site Admins Test
##                                      Item Type:      Site
##                                      As Member Of:   Site Collection Administrators
##                                      Permissions:    Full Control
##
##.EXAMPLE
## PS C:\> .\Get-EffectiveSPPermissions.ps1 -url http://sharepoint.contoso.com/sites/testsite/subsite1 | ConvertTo-Csv
##
## Description
## -----------
## This example returns all unique permissions for a particular site within a site collection and instead of formatting the results it converts them to a comma-separated table (this output could then be redirected to a text file).
## 
## It produces the following output:
##
## #TYPE System.Management.Automation.PSCustomObject
## "UserLogin","UserName","ItemUrl","ItemName","ItemType","AsMemberOf","Permissions","InheritedFrom"
## "CONTOSO\lbarnes","Lucy Barnes","http://sharepoint.contoso.com/sites/testsiteadmins/subsite1/Shared Documents/dropdown.htm",,"ListItem",,"Contribute",
## "CONTOSO\administrator","CONTOSO\Administrator","http://sharepoint.contoso.com/sites/testsiteadmins/subsite1/Shared Documents/dropdown.htm",,"ListItem","Subsite1 Owners","Full Control",
## "CONTOSO\dabarnes","David Barnes","http://sharepoint.contoso.com/sites/testsiteadmins/subsite1","Subsite1","Site","Site Collection Administrators","Full Control",
## "CONTOSO\administrator","CONTOSO\Administrator","http://sharepoint.contoso.com/sites/testsiteadmins/subsite1","Subsite1","Site","Subsite1 Owners","Full Control",
##
##.EXAMPLE
## PS C:\> .\Get-EffectiveSPPermissions.ps1 -url http://sharepoint.contoso.com/sites/testsite -principal CONTOSO\Administrator -formatoutput
##
## Description
## -----------
## This example returns all unique permissions that a particular user has within a site collection and formats the output for easy immediate reading.
## 
## It produces the following output:
##
## Permissions for user CONTOSO\Administrator (CONTOSO\Administrator)
## 
## Item URL     : http://sharepoint.contoso.com/sites/testsite
## Item Name    : Site Admins Test
## Item Type    : Site
## As Member Of : Power Contributors
## Permissions  : Extended Contribute
## 
## Item URL     : http://sharepoint.contoso.com/sites/testsite/subsite1
## Item Name    : Subsite1
## Item Type    : Site
## As Member Of : Subsite1 Owners
## Permissions  : Full Control
## 
## Item URL     : http://sharepoint.contoso.com/sites/testsite/subsite1/Shared Documents/dropdown.htm
## Item Name    :
## Item Type    : ListItem
## As Member Of : Subsite1 Owners
## Permissions  : Full Control
##
##.EXAMPLE
## PS C:\> .\Get-EffectiveSPPermissions.ps1 -url http://sharepoint.contoso.com/sites/testsite -sconly -formatoutput
##
## Description
## -----------
## This example returns all unique permissions that a particular user has within a site collection and formats the output for easy immediate reading.
## 
## It produces the following output:
##
## Users with access to site collection [http://sharepoint.contoso.com/sites/testsite]
## 
## User Login            User Name
## ----------            ---------
## CONTOSO\administrator CONTOSO\Administrator
## CONTOSO\dabarnes      David Barnes
## CONTOSO\lbarnes       Lucy Barnes
## CONTOSO\semartin      Sean Martin
##
##.NOTES
## For bug reports and any questions or comments regarding the functionality of this script please contact Sergey Zelenov of Microsoft Premier Field Engineering (UK) at szelenov@microsoft.com
## 
## This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE
##
##.LINK
## SharePoint Management PowerShell Scripts Project: http://sharepointpsscripts.codeplex.com
##.LINK
## Microsoft TechNet Script Gallery: http://go.microsoft.com/fwlink/?LinkId=169615
##.LINK
## From The Field Blog: http://sharepoint.microsoft.com/blogs/fromthefield

#requires -Version 2.0
[CmdletBinding()]

## See parameter info above or run 'Get-Help .\Get-EffectiveSPPermissions.ps1 -detailed'
param 
(
    [parameter(Mandatory=$true)]
    [uri]$url, 
    [string]$principal, 
    [switch]$nofolders,
    [switch]$nolists, 
    [switch]$noitems, 
    [switch]$sconly, 
    [switch]$showlimited, 
    [switch]$formatoutput, 
    [switch]$outcsv 
)

## Set the ErrorActionPreference variable so that any error is treated as terminating
$ErrorActionPreference = "Stop";

# Update output buffer size to prevent output wrapping 
if ( $Host -and $Host.UI -and $Host.UI.RawUI ) 
{ 
	$rawUI = $Host.UI.RawUI; 
	$oldSize = $rawUI.BufferSize; 
	$typeName = $oldSize.GetType().FullName; 
	$newSize = New-Object -TypeName $typeName -ArgumentList 512, $oldSize.Height;
	$rawUI.BufferSize = $newSize;
} 

## Load the required SharePoint snap-in
## The trap statement is used to check for the presence of assemblies on the local computer
& { 
	trap 
	{ 
		Write-Warning -Message "This computer does not seem to have Windows SharePoint Services installed!
         Please run this script on a server that is a member of a configured SharePoint farm.`n
         This script will now exit."; 
		exit;
	}
	if (-not (Get-PSSnapin | Where-Object {$_.Name -eq "Microsoft.SharePoint.PowerShell"}))
    {
        Add-PSSnapin Microsoft.SharePoint.PowerShell;
    } 
  }

##.SYNOPSIS    
## Retrieves the highest (most permissive) role definition from a collection of role definition bindings for a role assignment.
##
##.PARAMETER allroles
## TypeName: Microsoft.SharePoint.SPRoleDefinitionBindingCollection
function Get-HighestRole ($allroles)
{
	## Check if the collection contains a role with Full Control permissions - if it does then just return that
	$fc = $allroles | Where-Object {$_.BasePermissions -eq [Microsoft.SharePoint.SPBasePermissions]::FullMask}
	if ($fc) 
	{
		return $fc;
	}
	## If there is no Full Control role, identify the highest one by sorting the collection on the cumulative permissions and return the top one
	else
	{
		return ($allroles | Sort-Object -Property BasePermissions -Descending | Select-Object -First 1);
	}
}

##.SYNOPSIS    
## Works through a collection of individual permissions (custom PSObjects produced by the script) to obtain a display name of a user.
## This function is only used by the formatting scriptblock (i.e. if -formatoutput parameter is present in the call)
##
##.PARAMETER userinfo
## TypeName: System.Collections.ObjectModel.Collection`1[[System.Management.Automation.PSObject]
##
##.OUTPUTS
## System.String
function Get-UserName ($userinfo)
{
	for ($i=0; $i -lt $userinfo.Count; $i++)
	{
		if ($userinfo[$i].UserName -ne $userinfo[$i].UserLogin)
		{
			return $userinfo[$i].UserName
		}
	}
}

##.SYNOPSIS    
## Works through a collection of individual permissions (custom PSObjects produced by the script) to produce a multiline easy-to-read summary of each permission.
## This function is only used by the formatting scriptblock (i.e. if -formatoutput parameter is present in the call)
##
##.PARAMETER userinfo
## TypeName: System.Collections.ObjectModel.Collection`1[[System.Management.Automation.PSObject]
##
##.OUTPUTS
## System.String
function Expand-Permissions ($perminfo)
{
	for ($i=0; $i -lt $perminfo.Count; $i++)
	{
		$output += "Item URL:       {0}`r`nItem Name:      {1}`r`nItem Type:      {2}`r`n" -f $perminfo[$i].ItemUrl, $perminfo[$i].ItemName, $perminfo[$i].ItemType;
		$output += "As Member Of:   {0}`r`nPermissions:    {1}`r`n" -f $perminfo[$i].AsMemberOf, $perminfo[$i].Permissions;
		if ($perminfo[$i].InheritedFrom)
		{
			$output += "Inherited From: {0}`r`n`r`n" -f $perminfo[$i].InheritedFrom;
		}
		else
		{
			$output += "`r`n";
		}
	}
	return $output;
}

##.SYNOPSIS    
## This function simply produces a string value for the 'InheritedFrom' property of each permission object.
##
##.PARAMETER item
## TypeName: System.Object
##
##.OUTPUTS
## System.String
function Identify-Ancestor ($item)
{
	switch ($item)
	{
		{$_ -is [Microsoft.SharePoint.SPWeb]}
		{
			$ancestor = $item.Url;
		}
		{$_ -is [Microsoft.SharePoint.SPList]}
		{
			$ancestor = [Microsoft.SharePoint.Utilities.SPUtility]::GetFullUrl($item.ParentWeb.Site,$item.RootFolder.ServerRelativeUrl);
		}
	}
	return ("{0} ({1})" -f $item.Title, $ancestor);
}

##.SYNOPSIS    
## Get-Permissions function is the main logical part of the script that does most of the work.
##
##.PARAMETER item
## TypeName: System.Object
##
##.PARAMETER isRoot
## TypeName: System.Boolean
## Specifies whether the input object is an original object or a child (result of a recursive call)
##
##.OUTPUTS
## None. The function does not produce output but rather adds entries to a script-wide variable ($script:allperms)
function Get-Permissions ($item, [bool]$isRoot=$false)
{
	trap {Write-Error -Message ("Error processing item {0}. Details: {1}" -f $script:itemurl, $_.Exception.Message)}
	
	## Branch execution paths based on the type of the object received as input
	switch ($item)
	{
		## If the input object is a site collection, re-call the function for its root web
		{$_ -is [Microsoft.SharePoint.SPSite]}
		{
			Get-Permissions $item.RootWeb $true;
			$item.Dispose();
		}
		## If the input object is a site, call the function for all its lists and all its subwebs
		{$_ -is [Microsoft.SharePoint.SPWeb]}
		{
			## Check if -nolists parameter is present - in which case only need to process subwebs that have unique permissions
			if (-not $nolists)
			{
				## Check if -noitemss parameter is present - in which case only need to process subwebs that have unique permissions
				if ($noitems)
				{
					$alllists = $item.Lists |
						Where-Object {$_.HasUniqueRoleAssignments};
				}
				else
				{ 
					$alllists = $item.Lists
				}
				
				$allwebs = $item.Webs;
				
				$alllists | 
						ForEach-Object {Get-Permissions $_};
			}
			else
			{
				$allwebs = $item.Webs |
					Where-Object {$_.HasUniqueRoleAssignments};
			}
			$allwebs | 
					ForEach-Object {Get-Permissions $_};
					
			## Assign the $web variable which is required as part of making permission processing type-agnostic
			$web = $item;
			
			$itemtype = "Site";
			$script:itemurl = $item.Url;
		}
		## If the input object is a list or library, call the function for its items (unless -noitems parameter is present)
		{$_ -is [Microsoft.SharePoint.SPList]}
		{
			## Make sure we only process user-created lists and not system lists
			if ($item.AllowDeletion -and (-not $item.Hidden))
            {
				if (-not $nofolders)
                {
                    $secfldrs = $item.Folders |
                        Where-Object {$_.HasUniqueRoleAssignments};
                    $secfldrs |
                        Foreach-Object {Get-Permissions $_};
                            
                    if (-not $noitems)
    				{
    					$query = New-Object -TypeName Microsoft.SharePoint.SPQuery;
    					$query.ViewFields = "<FieldRef Name=`"ID`"/>"
                        $query.ViewAttributes = "Scope=`"Recursive`"";

    					$secitems = $item.GetItems($query) | 
    						Where-Object {$_.HasUniqueRoleAssignments}; 
                        $secitems | 
    						ForEach-Object {Get-Permissions $_};
    				}
                }
				$web = $item.ParentWeb;
    			$itemtype = "List"
    			$script:itemurl = $web.Site.MakeFullUrl($item.RootFolder.Url);
            }
			else
			{
				return;
			}
		}
		## If the input object is a list item, calculate correct url for it based on whether it's a file or not
		{$_ -is [Microsoft.SharePoint.SPListItem]}
		{
            if ($_.FileSystemObjectType -ne "Folder")
            {
			     $itemtype = "ListItem";
            }
            else
            {
                $itemtype = "Folder";
            }
			$web = $item.Web;
			if (-not ($item.File -or $item.Folder))
			{
				$script:itemurl = $web.Site.MakeFullUrl(($item.ParentList.Forms | Where-Object {$_.Type -eq "PAGE_DISPLAYFORM"}).Url + "?ID=" + $item.ID); 
			}
			else
			{
				$script:itemurl = $web.Site.MakeFullUrl($item.Url);
			}
		}
	}
	
	## Do another unique permissions check - this may be required if the item itself does not have unique permissions but its children might
	## E.g. list and list items - items would be processed above, but now the list itself does not need to be processed (unless it is the starting point)
	if (($web -eq $null) -or (-not ($item.HasUniqueRoleAssignments -or $isRoot)))
	{
		return;
	}
	
	Write-Verbose -Message ("Processing {0} at {1}..." -f $itemtype, $script:itemurl)
	## Initialize a hashtable to hold all permission entries for the item being processed
	$users = @{};
	
	## If the current item is the starting point for the script, make sure we report all site collection administrators
	## Site collection administrators have access to everything by definition, but may not have any permissions specified explicitly
	if ($isRoot)
	{
		## This line does not really do anything useful, but rather helps to work around a very strange issue where
		## the ParentWeb property of an SPList object returns a non-fully-functional instance of SPWeb, which has to be thus re-initialized
		$web | Format-List * | Out-Null
		$web.SiteAdministrators |
			ForEach-Object `
			{
				## If -principal paramter is present, only report a site collection administrator if it is the same account as -principal
				if (($principal -eq [string]::Empty) -or ($principal -eq $_.LoginName))
				{
					## Add an object to the $users collection - there is no need to do any permission checking, as we know it is Full Control
					$users[$_.LoginName] = `
						($_ | Select-Object `
							@{Name="Name";Expression={$_.Name}}, 
							@{Name="LoginName";Expression={$_.LoginName}},
							@{Name="Email";Expression={$_.Email}},
							@{Name="Role";Expression=
								{
									$rd = New-Object -TypeName Microsoft.SharePoint.SPRoleDefinition;
									$rd.BasePermissions, $rd.Name = [Microsoft.SharePoint.SPBasePermissions]::FullMask, "Full Control"; 
									$rd;
								}
							},
							@{Name="Group";Expression={"Site Collection Administrators"}}
						);
				}
			}
	}
	
	## Because we checked for unique permissions above, the FirstUniqueAncestor property should always return the object itself - but using it just in case
	## The pipeline below checks for direct individual assignments - i.e. users that are granted access outside of any group memberships
	$item.FirstUniqueAncestor.RoleAssignments | 
		Where-Object {($_.Member.GetType() -eq [Microsoft.SharePoint.SPUser]) -and (($principal -eq [string]::Empty) -or ($principal -eq $_.Member.ToString()))} | 
			ForEach-Object `
			{
				$user = & {trap {continue};  $web.SiteUsers[$_.Member.ToString()] };
				if ($user -eq $null)
				{
					$user = $_.Member;
				}
				## Check that user is not a Site Collection Administrator, as those were reported separately above
				if (-not $user.IsSiteAdmin)
				{
					$users[$user.LoginName] = `
						($_ | Select-Object `
							@{Name="Name";Expression={$user.Name}}, 
							@{Name="LoginName";Expression={$user.LoginName}},
							@{Name="Email";Expression={$_.Email}},
							@{Name="Role";Expression={ Get-HighestRole $_.RoleDefinitionBindings }}, 
							@{Name="Group";Expression={}}
						);
				}
			}
	## The pipeline below checks for group assignments - i.e. permissions that users have as members of SharePoint groups
	$item.FirstUniqueAncestor.RoleAssignments | 
		Where-Object {$_.Member.GetType() -eq [Microsoft.SharePoint.SPGroup]} |
			ForEach-Object `
			{
				$group = & {trap {continue}; $web.SiteGroups[$_.Member.ToString()] };
				if ($group -eq $null)
				{
					$group = $_.Member;
				}
				
				## Obtain the highest (most permissive) role definition, in case there is more than one
				$role = Get-HighestRole $_.RoleDefinitionBindings;
				
				## Add a separate object for each group member to the $users collection
				$group.Users | ForEach-Object `
				{
					$member = $_;
					## Check that user is not a Site Collection Administrator, as those were reported separately above
					if (-not $member.IsSiteAdmin)
					{
						## Check that the -principal parameter is not present, or if is that the current user is a match
						if (($member.LoginName -eq $principal) -or ($principal -eq [string]::Empty))
						{
							## If the $users collection does not contain an entry for the current user yet, add one
							if (-not $users[$member.LoginName])
							{
								$users[$member.LoginName] = $member | 
									Select-Object Name, LoginName, Email, @{Name="Role";Expression={$role}}, @{Name="Group";Expression={$group.Name}};
							}
							## If there is an entry in the $users collection for the current user already, check if the currently processed role assignment has higher permissions and thus the entry should be replaced
							elseif (($users[$member.LoginName].Role.BasePermissions -ne [Microsoft.SharePoint.SPBasePermissions]::FullMask) -and ($role.BasePermissions -gt $users[$member.LoginName].Role.BasePermissions))
							{
								$users[$member.LoginName].Role = $role;
								$users[$member.LoginName].Group = $group.Name;	
							}
						}
					}
				}
			}
	
	## Process the raw data contained in the $users collection (remember this is for the current content item ($item) only)
	$users.Values |
		ForEach-Object `
		{
			## Do not process an entry if the associated permission level is 'Limited Access' and -showlimited parameter is not present
			if ($showlimited -or ($_.Role.Name -ne "Limited Access"))
			{
				## Construct a new custom object
				## Note how values of some properties vary depending on whether the -sconly parameter is present
				$perm = (New-Object -TypeName PSObject | 
					Add-Member -MemberType NoteProperty -Name "UserLogin" -Value $_.LoginName -PassThru |
					Add-Member -MemberType NoteProperty -Name "UserName" -Value $_.Name -PassThru |
					Add-Member -MemberType NoteProperty -Name "UserEmail" -Value $_.Email -PassThru |
					Add-Member -MemberType NoteProperty -Name "ItemUrl" -Value $(if (-not $sconly) { $script:itemurl } else {$web.Site.Url}) -PassThru |
					Add-Member -MemberType NoteProperty -Name "ItemName" -Value $(if (-not $sconly) { $item.Title } else {$web.Site.RootWeb.Title}) -PassThru |
					Add-Member -MemberType NoteProperty -Name "ItemType" -Value $(if (-not $sconly) { $itemtype } else {"SiteCollection"}) -PassThru);
				## If the -sconly paramter is present, then the details added below are irrelevant
				if (-not $sconly)
				{
					$perm | Add-Member -MemberType NoteProperty -Name "AsMemberOf" -Value $_.Group -PassThru |
					Add-Member -MemberType NoteProperty -Name "Permissions" -Value $_.Role.Name -PassThru |
					Add-Member -MemberType NoteProperty -Name "InheritedFrom" -Value $(if (-not $item.HasUniqueRoleAssignments) {Identify-Ancestor $item.FirstUniqueAncestor} else { $null })
				}
				## Add the permission object to a script-wide array
				$script:allperms += $perm;
			}
		}
	## Dispose of the $web object to save memory
	$web.Dispose();
}

## This is the actual entry point into the script - execution starts here

## The if/elseif statement below is there to deal with URLs that contain spaces and are not enclosed in quotes
## If this is the case PowerShell does not throw an error but rather treats the part(s) after the space(s) as addition un-named arguments
## This obviously means that the validity of the report produced could be seriously compromised

## Check if any un-named arguments are present (they shouldn't be)
if ($args.Length -gt 0)
{
	## Check if the $principal variable contains a value although the -principal switch is not present
	## This will happen if the un-quoted input URL contains more than 1 space
	if (($principal -ne [string]::Empty) -and ($MyInvocation.Line.IndexOf("-principal") -eq -1))
	{
		## Start restoring the original url
		$url = [uri]($url.AbsoluteUri + " " + $principal);
		## Set the $principal to Empty, which it should be
		$principal = [string]::Empty;
	}
	## Complete the correct original URL by appending all pieces that ended up as un-named arguments
	$url = [uri]($url.AbsoluteUri + " " + ([string]::Join(" ",$args)));
}
## Check if the $principal variable contains a value although the -principal switch is not present
## This will happen if the un-quoted input URL contains just 1 space
elseif (($principal -ne [string]::Empty) -and ($MyInvocation.Line.IndexOf("-principal") -eq -1))
{
	$url = [uri]([string]::Join(" ",@($url.AbsoluteUri, $principal)));
	$principal = [string]::Empty;
}

## Bind to the site collection identified by the input URL

$site = New-Object -TypeName Microsoft.SharePoint.SPSite -ArgumentList $url.AbsoluteUri;

## Initialize an empty array to hold all the initial (root) objects to be processed
$input = @();

## Initalize an empty script-wide array to hold the output
$script:allperms = @();

## Check if the input URL is a base URL (i.e. protocol spec and FQDN only)
## If it is and it ends with a forward slash, assume that the target is the root site collection
if ($url.AbsolutePath -eq "/")
{
	if ($url.AbsoluteUri -eq $url.OriginalString)
	{
		$input += $site;
	}
	## If the input URL is a base URL and does not end with a forward slash, assume the target is the entire web application with all the site collections in it
	else
	{
		## Bind to the target web application
		$wa = [Microsoft.SharePoint.Administration.SPWebApplication]::Lookup($url);
		## Add all site collections to the original input
		$input += $wa.Sites;
	}
}
## If the input URL is a site collection URL (that of a root web site in the collection) or -sconly paramter is present, only add the site collection to the original input
elseif (($url -eq $site.Url) -or ($sconly))
{
	$input += $site;
}
## If the URL is an extended URL that contains other segments and/or query, analyze it further
else
{
	## Get the part of the input URL that is relative to the URL of the site collection and store it in a variable
	$relUrl = ($url.AbsoluteUri -replace $site.Url).Trim("/");
	
	## If the relative URL identifies a site within a site collection, simply add that site to original input
	if ($site.AllWebs.Names -contains $relUrl)
	{
		$input += $site.AllWebs[$relUrl];
	}
	else
	{
		## Store all segments of the relative URL (including query) in an array
		$segments = $relUrl.Split("/?");
		
		## Initialize another string variable with the same value as the current relative URL
		$webUrl = $relUrl;
		
		## Process the array of segments backwards, removing segments one by one from the end of the URL, until the URL of the lowest level subsite is identified
		-1..-$segments.Count | 
			ForEach-Object `
			{
				$webUrl = ($webUrl -replace $segments[$_]).TrimEnd("/?");
				
				## Once the correct URL is obtained, initialize a variable containing an instance of SPWeb class for the lowest level subsite
				if ($site.AllWebs.Names -contains $webUrl)
				{
					if ($hostweb -eq $null)
					{
						$hostWeb = $site.AllWebs[$webUrl];
					}
				}
			}
		if ($hostWeb -ne $null)
		{
			## Check if the rest of the URL identifies a list or library by trying to bind to the list
			$list = & {trap { continue }; $hostWeb.GetList($($hostWeb.ServerRelativeUrl + ($url.AbsoluteUri -replace $hostWeb.Url).TrimEnd("/")))};
			
			if ($list -ne $null)
			{
				## Check if the input URL is longer than that of the identified list, i.e. it may point to a list item
				if (-not [Microsoft.SharePoint.Utilities.SPEncode]::UrlDecodeAsUrl($url.AbsoluteUri).TrimEnd("/").EndsWith($list.Title))
				{
					## If the list is a document library, check if the remaining part of the URL can be used to identify a document
					if ($list.BaseType -eq [Microsoft.SharePoint.SPBaseType]::DocumentLibrary)
					{
						## Obtain the name of the file only to be used in a query
						$docname = [Microsoft.SharePoint.Utilities.SPUtility]::GetUrlFileName($url.AbsoluteUri);
						
						## Check if the URL is not actually pointing to a form, in which case we have no interest in processing it
						if (-not (($list.Forms | Foreach-Object {$_.Url}) -eq [Microsoft.SharePoint.Utilities.SPEncode]::UrlDecodeAsUrl($url.AbsoluteUri -replace $hostWeb.Url).Trim("/")))
						{
							## Construct and run a CAML query to return the document
							$query = New-Object Microsoft.SharePoint.SPQuery;
							$query.Query = "<Query><Where><Eq><FieldRef Name='FileLeafRef'/><Value Type='File'>$docname</Value></Eq></Where></Query>";
							$items = $list.GetItems($query);
							
							## If a document is found, add it to the original input
							if ($items.Count -eq 1)
							{
								$input += $items[0];
							}
						}
					}
					## If the list is not a library, try to match the item by its ID
					else
					{
						if ($url.AbsoluteUri -match "ID=(\d*)")
						{
							$item = & { trap {continue}; $list.GetItemById($matches[1])};
							if ($item -ne $null)
							{
								$input += $item;
							}
						}
					}
				}
				## If the URL matches the URL of the list, add the list to the original input
				if ($input.Length -lt 1)
				{
					$input += $list;
				}
			}
			## If no list could be found, consider the identified site to be the starting point and add it to the original input
			else
			{
				$input += $hostWeb;
			}
		}
		else
		{
			Write-Host "No valid input detected" -ForegroundColor Red;
			break;
		}
	}
}

## Process the original input by running the Get-Permissions function for each root object
$input |
	ForEach-Object `
	{
		Get-Permissions $_ $true;
	}

## If the -sconly paramter is present, modify the output objects so that they contain User Name and User Login only
if ($sconly)
{
	$scperms = $script:allperms  | Group-Object -property ItemUrl, UserLogin | Foreach-Object {$_.Group[0]};
	$script:allperms = $scperms;
}

## Format results if the -formatoutput parameter is present
if ($formatOutput)
{
	if ($sconly)
	{
		$script:allperms | 
		Group-Object -Property ItemUrl |
			ForEach-Object `
			{
				Write-Output "";
				Write-Output ("Users with access to site collection [{0}]" -f $_.Name);
				if ($nolists -or $noitems)
				{
					$ignoremsg = "Ignoring access to individual ";
					if ($nolists)
					{
						$ignoremsg += "lists ";
						if ($noitems)
						{
							$ignoremsg += "and ";
						}
					}
					if ($noitems)
					{
						$ignoremsg += "list items";	
					}
					Write-Output $ignoremsg;
				}
				$_.Group | Sort-Object -Property UserName |
				Format-Table -Property @{l="User Login";e={$_.UserLogin}}, 
				@{l="User Name";e={$_.UserName}} -Wrap -AutoSize;
			}
	}
	elseif ($principal -ne [string]::Empty)
	{
		Write-Output "";
		Write-Output ("Permissions for user {1} ({0})" -f $principal,$script:allperms[0].UserName);
		$script:allperms | Sort-Object -Property ItemUrl | Format-List -Property @{l="Item URL";e={$_.ItemUrl}},
		@{l="Item Name";e={$_.ItemName}}, @{l="Item Type";e={$_.ItemType}}, @{l="As Member Of";e={$_.AsMemberOf}}, 
		@{l="Permissions";e={$_.Permissions}};
	}
	else
	{
		$script:allperms | Group-Object -Property UserLogin | Format-Table -Property @{l="User Login";e={$_.Name}}, 
			@{l="User Name";e={Get-UserName $_.Group}}, @{l="Permissions";e={Expand-Permissions $_.Group}} -Wrap -AutoSize;
	}
}
elseif($outcsv)
{
	$script:allperms |
		ForEach-Object `
		{
			Write-Output ("`"{0}`",`"{1}`",`"{2}`",`"{3}`",`"{4}`",`"{5}`",`"{6}`",`"{7}`",`"{8}`"" -f $_.UserLogin,$_.UserName,$_.UserEmail,$_.ItemUrl,$_.ItemName,$_.ItemType,$_.AsMemberOf,$_.Permissions,$_.InheritedFrom)
		}
}
## Send the 'raw' array of results to the output
else
{
	$script:allperms
}
Write-Debug ("Execution finished: {0}" -f (Get-Date));