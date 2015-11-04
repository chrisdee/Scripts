## SharePoint Server: PowerShell Script to Enumerate all Permissions throughout a Farm with XML output ##

<#

Overview: Script enumerates SharePoint 2010 / 2013 permissions across the entire farm down to the site (SPWeb) level. It also recursively expands the membership of any AD group and lists the assignment role binding on the permission. The output is an XML format.

Resource: http://gallery.technet.microsoft.com/scriptcenter/Enumerate-SharePoint-2010-35976bdb

Environments: SP2010 / 2013 Farms

Usage Examples: 

./SP2010EnumWebUsersGroups.ps1 | Out-File SPWebApppsPermissions.xml
./SP2013EnumWebUsersGroups.ps1 | Out-File SPWebApppsPermissions.xml

#>


function Expand-ADGroupMembership
{
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [string]
        $ADGroupName,
        [Parameter(Position=1)]
        [string]
        $RoleBinding
    )
    Process
    {
        $roleBindingText = ""
        if(-not [string]::IsNullOrEmpty($RoleBinding))
        {
            $roleBindingText = " RoleBindings=`"$roleBindings`""
        }

        Write-Output "<ADGroup Name=`"$($ADGroupName)`"$roleBindingText>"

        $domain = $ADGroupName.substring(0, $ADGroupName.IndexOf("\") + 1)
        $groupName = $ADGroupName.Remove(0, $ADGroupName.IndexOf("\") + 1)
                            
        #BEGIN - CODE ADAPTED FROM SCRIPT CENTER SAMPLE CODE REPOSITORY
        #http://www.microsoft.com/technet/scriptcenter/scripts/powershell/search/users/srch106.mspx

        #GET AD GROUP FROM DIRECTORY SERVICES SEARCH
        $strFilter = "(&(objectCategory=Group)(name="+($groupName)+"))"
        $objDomain = New-Object System.DirectoryServices.DirectoryEntry
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
        $objSearcher.SearchRoot = $objDomain
        $objSearcher.Filter = $strFilter

        # specify properties to be returned
        $colProplist = ("name","member","objectclass")
        foreach ($i in $colPropList)
        {
            $catcher = $objSearcher.PropertiesToLoad.Add($i)
        }
        $colResults = $objSearcher.FindAll()
        #END - CODE ADAPTED FROM SCRIPT CENTER SAMPLE CODE REPOSITORY

        foreach ($objResult in $colResults)
        {
            if($objResult.Properties["Member"] -ne $null)
            {
                foreach ($member in $objResult.Properties["Member"])
                {
                    $indMember = [adsi] "LDAP://$member"
                    $fullMemberName = $domain + ($indMember.Name)
                    
                    #if($indMember["objectclass"]
                        # if child AD group continue down chain
                        if(($indMember | Select-Object -ExpandProperty objectclass) -contains "group")
                        {
                            Expand-ADGroupMembership -ADGroupName $fullMemberName
                        }
                        elseif(($indMember | Select-Object -ExpandProperty objectclass) -contains "user")
                        {
                            Write-Output "<ADUser>$fullMemberName</ADUser>"
                        }
                }
            }
        }
        
        Write-Output "</ADGroup>"
    }
} #end Expand-ADGroupMembership

# main portion of script
if((Get-PSSnapin -Name microsoft.sharepoint.powershell) -eq $null)
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell
}

$farm = Get-SPFarm
Write-Output "<Farm Guid=`"$($farm.Id)`">"

$webApps = Get-SPWebApplication
foreach($webApp in $webApps)
{
    Write-Output "<WebApplication URL=`"$($webApp.URL)`" Name=`"$($webApp.Name)`">"

    foreach($site in $webApp.Sites)
    {
        Write-Output "<SiteCollection URL=`"$($site.URL)`">"
        
        foreach($web in $site.AllWebs)
        {
            Write-Output "<Site URL=`"$($web.URL)`">"

            # if site inherits permissions from parent then stop processing
            if($web.HasUniqueRoleAssignments -eq $false)
            {
                Write-Output "<!-- Inherits role assignments from parent -->"
            }
            # else site has unique permissions
            else
            {
                foreach($assignment in $web.RoleAssignments)
                {
                    if(-not [string]::IsNullOrEmpty($assignment.Member.Xml))
                    {
                        $roleBindings = ($assignment.RoleDefinitionBindings | Select-Object -ExpandProperty name) -join ","

                        # check if assignment is SharePoint Group
                        if($assignment.Member.XML.StartsWith('<Group') -eq "True")
                        {
                            Write-Output "<SPGroup Name=`"$($assignment.Member.Name)`" RoleBindings=`"$roleBindings`">"
                            foreach($SPGroupMember in $assignment.Member.Users)
                            {
                                # if SharePoint group member is an AD Group
                                if($SPGroupMember.IsDomainGroup)
                                {
                                    Expand-ADGroupMembership -ADGroupName $SPGroupMember.Name
                                }
                                # else SharePoint group member is an AD User
                                else
                                {
                                    # remove claim portion of user login
                                    #Write-Output "<ADUser>$($SPGroupMember.UserLogin.Remove(0,$SPGroupMember.UserLogin.IndexOf("|") + 1))</ADUser>"

                                    Write-Output "<ADUser>$($SPGroupMember.UserLogin)</ADUser>"

                                }
                            }
                            Write-Output "</SPGroup>"
                        }
                        # else an indivdually listed AD group or user
                        else
                        {
                            if($assignment.Member.IsDomainGroup)
                            {
                                Expand-ADGroupMembership -ADGroupName $assignment.Member.Name -RoleBinding $roleBindings
                            }
                            else
                            {
                                # remove claim portion of user login
                                #Write-Output "<ADUser>$($assignment.Member.UserLogin.Remove(0,$assignment.Member.UserLogin.IndexOf("|") + 1))</ADUser>"
                                
                                Write-Output "<ADUser RoleBindings=`"$roleBindings`">$($assignment.Member.UserLogin)</ADUser>"
                            }
                        }
                    }
                }
            }
            Write-Output "</Site>"
            $web.Dispose()
        }
        Write-Output "</SiteCollection>"
        $site.Dispose()
    }
    Write-Output "</WebApplication>"
}
Write-Output "</Farm>"