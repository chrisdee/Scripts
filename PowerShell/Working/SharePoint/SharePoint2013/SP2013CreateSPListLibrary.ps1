## SharePoint Server: PowerShell Function to Create List Libraries from the SPList Template Types ##

<#

Overview: PowerShell function to create List Libraries from SPList Templates

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Provide a web site URL for the '$web' variable and call the function like the example below

Create-ListLibrary $web "YourListName" "Your List Description"

Note: If you want to use this function to create other SPList templates, change the '$ListTemplate' variable to match the template type

Resources:

https://msdn.microsoft.com/en-us/library/microsoft.sharepoint.splisttemplatetype.aspx
http://www.sharepointdiary.com/2013/04/create-form-library-in-sharepoint-using-powershell.html

#>

Add-PSSnapin "Microsoft.SharePoint.Powershell" -ErrorAction SilentlyContinue
 
Function Create-ListLibrary
{
 Param
 ( 
  [Microsoft.SharePoint.SPWeb]$Web,
  [String] $ListName,
  [String] $Description
 )
 #Get the List Library template
 $ListTemplate = [Microsoft.Sharepoint.SPListTemplateType]::XMLForm #Change the 'SPListTemplateType' here if you want to provision another type of list template
  
 #Check if the list already exists
 if( ($web.Lists.TryGetList($ListName)) -eq $null)
 {
  #Create the list
     $Web.Lists.Add($ListName,$Description,$ListTemplate) 
   
  #You can Set Properties of Library such as OnQuickLaunch, etc
  $ListLib = $Web.Lists[$ListName] 
  $ListLib.OnQuickLaunch = $true
  $ListLib.Update()
   
  Write-Host "'$ListName' library created successfully!"
 }
 else
 {
  Write-Host "'$ListName' library already exists!"
 }
 #Dispose web object
    $Web.Dispose()    
}
 
#Get the Web
$web = Get-SPWeb "https://yoursharepointwebsite" #Change this path to match your SharePoint web site
 
#Example Call the function to create the library
Create-ListLibrary $web "YourListName" "Your List Description"
