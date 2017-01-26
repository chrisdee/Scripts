## MSOnline: PowerShell Script To Connect To MS Online (o365) To Get Individual CSV Reports On User License Plan Assignments Across a Tenant  ##

<#

    GetMSOnlineUserLicensePlansAssignment.ps1
    
    makes a report of license type and service plans per use , and saves one Excel-sheet (CSV) per uses license type.

    Resources: 
    
    https://gallery.technet.microsoft.com/scriptcenter/Export-a-Licence-b200ca2a?tduid=(26fc5a009171934296bd78c7f4dd6590)(256380)(2459594)(TnL5HPStwNw-0Z3.3otQ5VeALpBrI1CXBg)()

    http://sikkepitje.blogspot.ch/2016/10/get-msoluserlicense.html

    created by Alan Byrne
    modified 20161006 by p.wiegmans@bonhoeffer.nl/sikkepitje@hotmail.com

    Changed separator from comma to semi-comma, fixes formatting errors whene displayname contains comma (very common).
    Changed: separate output file , one for each license type.
    Changed: added timestamp to filename. 
    Changed: Fetching all users once, instead of every license type, givea huge speed boost.
#>

$VerbosePreference = 'Continue'    # Makes verbose meldingen zichtbaar : Modify to your needs
# The Reports will be written to files in the current working directory

# Connect to Microsoft Online IF NEEDED
#write-host "Connecting to Office 365..."
Import-Module MSOnline
Connect-MsolService -Credential $Office365credentials

# Get a list of all licences that exist within the tenant
$licensetype = Get-MsolAccountSku | Where {$_.ConsumedUnits -ge 1}

Write-Verbose "License types are:" 
$lts = $licensetype| select -expandproperty accountskuid | Format-Table -Autosize | Out-String
Write-Verbose $lts

Write-Verbose "Getting all users (may take a while) ..."
$allusers = Get-MsolUser -all 
Write-Verbose ("There are " + $allusers.count + " users in total")

# Loop through all licence types found in the tenant
foreach ($license in $licensetype) 
{ 
 # Build and write the Header for the CSV file
    $LicenseTypeReport = "Office365_" + ($license.accountskuid -replace ":","_") + "_" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".csv"
    Write-Verbose ("New file: "+ $LicenseTypeReport)

 $headerstring = "DisplayName;UserPrincipalName;JobTitle;Office;AccountSku"
 
 foreach ($row in $($license.ServiceStatus)) 
 {
  $headerstring = ($headerstring + ";" + $row.ServicePlan.servicename)
 }
 
 Out-File -FilePath $LicenseTypeReport -InputObject $headerstring -Encoding UTF8 -append
 
 write-Verbose ("Gathering users with the following subscription: " + $license.accountskuid)

 # Gather users for this particular AccountSku
 $users = $allusers | where {$_.isLicensed -eq "True" -and $_.licenses.accountskuid -contains $license.accountskuid}

 # Loop through all users and write them to the CSV file
 foreach ($user in $users) {
  
        $thislicense = $user.licenses | Where-Object {$_.accountskuid -eq $license.accountskuid}
        $datastring = (($user.displayname -replace ","," ") + ";" + $user.userprincipalname + ";" + $user.Title + ";" + $user.Office + ";" + $license.SkuPartNumber)
  
  foreach ($row in $($thislicense.servicestatus)) {   
   # Build data string
   $datastring = ($datastring + ";" + $($row.provisioningstatus))
  }  
  Out-File -FilePath $LicenseTypeReport -InputObject $datastring -Encoding UTF8 -append
 }
} 

write-Verbose ("Script Completed.")