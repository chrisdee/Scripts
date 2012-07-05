## SharePoint Server 2010: PowerShell Script To Deploy The SharePoint 2010 STSADM Commands and PowerShell Cmdlets WSP ##
## Resource: Gary Lapointe SharePoint Automation: http://blog.falchionconsulting.com/index.php/downloads
## Usage: Can effectively be used to add and install any SharePoint WSP that requires "GACDeployment"

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

# User-modifiable variables
$SolutionName = "Lapointe.SharePoint2010.Automation.wsp"
$SolutionLocation = "D:\BoxBuild\SharePointSolutions" #Change this path to suit your environment
# Non-modifiable variables
$caWebApp = [Microsoft.SharePoint.Administration.SPAdministrationWebApplication]::Local
$caWebApp.Sites[0].Url

Add-SPSolution -LiteralPath $SolutionLocation\$SolutionName
Write-Host -ForegroundColor Yellow "Added the solution: $SolutionName"
Install-SPSolution -Identity $SolutionName -GACDeployment
Write-Host -ForegroundColor Yellow "Check your solution status at:" ($caWebApp.Sites[0].Url + "/_admin/Solutions.aspx")