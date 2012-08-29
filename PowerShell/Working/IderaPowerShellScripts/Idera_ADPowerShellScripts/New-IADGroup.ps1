## =====================================================================
## Title       : New-IADGroup 

## Description : Create a new group in Active Directory.
## Author      : Idera
## Date        : 8/11/2009
## Input       :  New-IADGroup [[-Name] <String>] [[-ParentContainer] <String>] [[-GroupScope] <String>] [[-GroupType] <String>] [[-Description] <String>]             
##                     
## Output      : System.DirectoryServices.DirectoryEntry
## Usage       :
##               1. Create universal security group TestGroup in Test OU
##               New-IADGroup -Name  TestGroup -GroupScope universal -GroupType security -ParentContainer  "OU=Test,DC=domain,DC=com"
##            
## Notes       :
## Tag         : group, activedirectory
## Change log  :
## =====================================================================

function New-IADGroup {
    param(
       [string]$Name = $(Throw "Please enter a group name."),
       [string]$ParentContainer = $(Throw "Please enter a parent container DN."),
       [string]$GroupScope,
       [string]$GroupType,
       [string]$Description
     ) 

  


    # validating existance of the parent container
    if( ![ADSI]::Exists("LDAP://$ParentContainer"))
    {
        Throw "Parent container could not be found, please check the value."
    }

    # validating group type values
    if($GroupType -ne "" -or $GroupType)
    {
        if($GroupType -notmatch '^(Security|Distribution)$')
        {
            Throw "GroupType Value must be one of: 'Security' or 'Distribution'"
        }
    }


    # validating group scope values
    if($GroupScope -ne "" -or $GroupScope)
    {
        if($GroupScope -notmatch '^(Universal|Global|DomainLocal)$')
        {
            Throw "GroupScope Value must be one of: 'Universal', 'Global' or 'DomainLocal'"
        }
    }


    switch ($GroupScope)
    {
        "Global" {$GroupTypeAttr = 2}
        "DomainLocal" {$GroupTypeAttr = 4}
        "Universal" {$GroupTypeAttr = 8}
    }


    # modify group type attribute if the group is security enabled
    if ($GroupType -eq 'Security')
    {
        $GroupTypeAttr = $GroupTypeAttr -bor 0x80000000
    }
     
  

    
        if( [ADSI]::Exists("LDAP://CN=$Name,$ParentContainer")) 
        {
            Write-Warning "The group $_ already exists in $ParentContainer."

         }
        else
       {  
           $Container = [ADSI]"LDAP://$ParentContainer"

            $group = $Container.Create("group","CN=$Name")
            $null = $group.put("sAMAccountname",$Name)
            $null = $group.put("grouptype",$GroupTypeAttr)

            if ($Description) {
                $null = $group.put("description",$Description)
            }

  
            # populate the Notes field
            $null = $group.put("info","Created $(Get-Date) by $env:userdomain\$env:username")
            $null = $group.SetInfo() 
            $group 
        }
    }