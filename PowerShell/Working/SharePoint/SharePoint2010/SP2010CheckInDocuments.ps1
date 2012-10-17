## SharePoint Server: PowerShell Script To Automatically Check In Documents Across A Document Library ##

<#

Overview: Useful script that loops through a SharePoint document folder and checks in all documents that have a version count of zero.
This can be beneficial when a user has added documents to a SharePoint document library through 'Windows Explorer' and the document library
has kept them in 'Checked Out' status. The version count setting of zero '0' can be changed if needed lower down in the script, but keeping
it to this ensures that only new documents that don't have a version history associated with them and could be in the process of been edited
are not checked in losing the users edits.

Environments: MOSS 2007 and SharePoint Server 2010 Farms

Usage: Edit the following variables before running the script: '$site'; '$folder'

Resource: http://blogs.msdn.com/b/paulking/archive/2011/10/14/using-powershell-to-clean-up-sharepoint-document-library-files-with-no-versions.aspx

#>

[system.reflection.assembly]::LoadWithPartialName("Microsoft.Sharepoint") 
$site = New-Object Microsoft.SharePoint.SPSite("http://YourSiteURL.com") #Change this to suit your environment
$root = $site.allwebs[0] 
$folder = $root.GetFolder("Your Document Library") #Change this to suit your environment

#============================================================
# Function Set-CheckInFolderItems is a recursive function that will CheckIn all items in a list recursively 
#============================================================
function Set-CheckInFolderItems([Microsoft.SharePoint.SPFolder]$folder) 
{
    # Create query object
    $query = New-Object Microsoft.SharePoint.SPQuery
    $query.Folder = $folder
 
    # Get SPWeb object
    $web = $folder.ParentWeb
 
    # Get SPList 
    $list = $web.Lists[$folder.ParentListId]

    # Get a collection of items in the specified $folder
    $itemCollection = $list.GetItems($query)

    # If the folder is the root of the list, display information
    if ($folder.ParentListID -ne $folder.ParentFolder.ParentListID) 
    {
        Write-Host("Recursively checking in all files in " + $folder.Name)
    }

    # Iterate through each item in the $folder - Note sub folders and list items are both considered items
    foreach ($item in $itemCollection) 
    {
        # If the item is a folder
        if ($item.Folder -ne $null) 
        {
            # Write the Subfolder information 
            Write-Host("Folder: " + $item.Name + " Parent Folder: " + $folder.Name) 
 
            # Call the Get-Items function recursively for the found sub-solder
            Set-CheckInFolderItems $item.Folder 
        }
 
        # If the item is not a folder
        if ($item.Folder -eq $null) 
        {
            if ($item.File.CheckOutType -ne "None")
            {
                if ($item.File.Versions.Count -eq 0) #This is set to check for any files that currently have a Version Count of 0
                {
                    # Check in the file
                    Write-Host "Check in File: "$item.Name" Version count " $item.File.Versions.Count -foregroundcolor Green
                    $item.File.CheckIn("Checked in By Administrator")
                }
            }
        }
    }

    $web.dispose()
    $web = $null
}


Set-CheckInFolderItems $folder