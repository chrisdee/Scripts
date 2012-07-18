## SharePoint Server: PowerShell Function To Hide And Unhide SharePoint List Fields ##
## Resource: http://www.powershell.nu/2009/01/13/hiding-a-listfield-in-newformeditform-in-sharepoint
## Usage: Works on both MOSS 2007 and SharePoint Server 2010 Farms

function Hide-SPField([string]$url, [string]$List, [string]$Field) {
  [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

  $SPSite = New-Object Microsoft.SharePoint.SPSite($url)
  $OpenWeb = $SPSite.OpenWeb()

  $OpenList = $OpenWeb.Lists[$List]

  $OpenField = $OpenList.Fields[$Field]
  $OpenField.ShowInNewForm = $False #Change this value to '$True' if you want the field to be visible again
  $OpenField.ShowInEditForm = $False #Change this value to '$True' if you want the field to be visible again
  $OpenField.Update()

  $SPSite.Dispose()
  $OpenWeb.Dispose()
}

#Example:

#Hide-SPField -url "http://moss/site" -List "My Custom List" -Field "UserField"