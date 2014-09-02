## SharePoint Server: PowerShell Function to 'resolve' the Edit vs. Contribute Role Permissions Change ##

<#

Overview: In some SharePoint 2013 Farms there is new permission level called Edit, and it is assigned to the Members group by default. The Edit permission level states: Can add, edit and delete lists; can view, add, update and delete list items and documents.

The function below can be used at Web Application and Site Collection level to enumerate all web applications, site collections, and webs to change the setting back from 'Edit' to 'Contribute'

Environments: SharePoint Server 2013 Farms

Resource: http://paulliebrand.com/2014/04/18/sharepoint-2013-edit-vs-contribute-solution

Usage Examples:

Example to process all web applications, sites, and webs
 
Measure-Command {
    Get-SPWebApplication  | Fix-PLEditContribute
}
 
Example to process a specific site collection and webs
 
Measure-Command {
    Get-SPSite http://test/sites/site | Fix-PLEditContributeSite
}
 
#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue
 
function Fix-PLEditContribute {
    param (
    [Parameter(Mandatory=$true, HelpMessage="Please provide SPWebApplication object", ValueFromPipeline=$true)]
    $webApplication)
 
    BEGIN {}
 
    PROCESS {
 
        Write-Verbose "Process $($webApplication.DisplayName)"
 
        $webApplication.Sites | Fix-PLEditContributeSite
 
    }
 
    END {}
 
}
 
function Fix-PLEditContributeSite {
    param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true,HelpMessage="Please provide an SPSite object")]
    [Microsoft.SharePoint.SPSite] $site
    )
 
    BEGIN {}
 
    PROCESS {
 
        foreach ($web in $site.AllWebs)
        {
            Write-Verbose "`t$($web.Url)"
            try
            {
                if (!$web.HasUniquePerm)
                {
                    Write-Verbose "Web is inheriting permissions, skipping..."
                    continue;
                }
 
                $editRole = $web.RoleDefinitions["Edit"]
                $contributeRole = $web.RoleDefinitions["Contribute"]
 
                $roleAssignments = $web.RoleAssignments | ? {$_.RoleDefinitionBindings -eq $editRole}
 
                foreach ($roleAssignment in $roleAssignments)
                {
                    if ($roleAssignment.RoleDefinitionBindings.Contains($contributeRole))
                    {
                        Write-Verbose "Already contains Contribute, skipping..."
                        continue;
                    }
 
                    $roleAssignment.RoleDefinitionBindings.Add($contributeRole);
                    $roleAssignment.RoleDefinitionBindings.Remove($editRole);
 
                    $roleAssignment.Update()
                }
 
                $web.Update()
            }
            finally
            {
                if ($web)
                {
                    $web.Dispose()
                }
            }
        }
 
        $rootWeb = $site.RootWeb
        $editRole = $web.RoleDefinitions["Edit"]
        if ($editRole)
        {
            Write-Verbose "Removing Edit Permission"
            $rootWeb.RoleDefinitions.Delete("Edit")
        }  
 
        $site.Dispose()
 
    }
 
    END {}
}