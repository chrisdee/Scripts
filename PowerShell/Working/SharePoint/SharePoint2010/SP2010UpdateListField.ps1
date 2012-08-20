## SharePoint Server: PowerShell Script To Update Site Column Field Properties ##

<# 

Overview: Script that uses the Object Model to update the Title property for SharePoint Columns, this is especially
useful for resolving the common issue where the 'hard coded' Title column is accidently renamed. This script can be
used for updating other Field columns too. You will just need to place these under the '$spfield.Title' variable

SharePoint Manager (http://spm.codeplex.com) is a great tool for exploring the SharePoint Object Model

Environments: Works on MOSS 2007 and SharePoint Server 2010 Farms

Resource: http://sharepointkb.wordpress.com/2009/02/12/renaming-root-title-site-column-powershell-example

Usage: If not resolving the accidental change to the 'hard coded' Title column, change the following other variables
apart from '$siteurl'; '$spfield=$spweb' and '$spfield.Title'. Run the script and then check your changes under
the Site Column Gallery of your Site URL (_layouts/mngfield.aspx)

Important: If you want your changes to replicate across all list columns that reference this column go to your column 
under content types and under 'Update List and Site Content Types':
select 'Yes' for 'Update all content types inheriting from this type?'

#>

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

#Replace the siteurl with your targeted site collection url.
$siteurl = "http://YourWebAppName.com"

$spsite=new-object Microsoft.SharePoint.SPSite($siteurl)
$spweb=$spsite.OpenWeb()
$spfield=$spweb.Fields.GetFieldByInternalName("Title") #Change this field 'InternalName' if needed
$spfield.Title = "Title" #Change this 'Title' field if needed
#Add additional field properties below here if you want to update other properties - example:
#$spfield.Description = "Add Your Description Here"
$spfield.Update()
$spweb.Dispose()
$spsite.Dispose()