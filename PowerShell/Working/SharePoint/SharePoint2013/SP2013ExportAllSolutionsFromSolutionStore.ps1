## SharePoint Server 2013: PowerShell Script To Export All WSP Solutions From The Farm Solution Store ##
## Resource: http://allaboutmoss.com/2011/10/16/export-wsp-from-farm-solution-store-using-powershell

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

foreach($solution in Get-SPSolution)
{
    try
        {
        $filename = $solution.Name;
        $solution.SolutionFile.SaveAs("C:\BoxBuild\Solutions\$filename") #Change this path to suit your environment
        }
    catch
        {
        Write-Host "-error:$_"-foreground red
        }
}
