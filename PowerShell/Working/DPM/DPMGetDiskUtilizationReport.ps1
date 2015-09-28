## DPM Server: Get Protection Groups Disk Utilization and Write this to Email / HTML Report ##
 
 <#
 
 Overview: This script finds Protection Groups Replica Sizes and Recovery Point Sizes to produce a Disk Utilization Email / HTML report
 
 Usage: Provide parameters to match your environment like the 'usage example' below and run the script. The report is written to the same directory the script is run from

 Usage Example: .\DPMGetDiskUtilizationReport.ps1 -DPMServer "YourDPMServerName" -SendEmailTo "YourToAddress@YourDomain.com" -SMTPServer "YourSMTPServerName.com"
 
 Resource: https://geekeefy.wordpress.com/2015/09/22/powershell-get-disk-utilization-of-dpm-2010-server
 
 #>
 

# Parameter Definition
Param
(
    [Parameter(mandatory = $true)] [String] $DPMServer,
    [String] $SendEmailTo,
    [String] $OutputDirectory,
    [String] $SMTPServer
)

# HTML Body Definition Start

$a = "<html><head><style>"
$a = $a + "BODY{font-family: Calibri;font-size:14;font-color: #000000}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 4px;border-style: solid;border-color: black;background-color: #BDBDBD}"
$a = $a + "TD{border-width: 1px;padding: 4px;border-style: solid;border-color: black;background-color: #ffffff	}"
$a = $a + "</style></head><body>"

# HTML Body Definition End

$b = "</body></html>"

# Import Data Protection Module. 

Import-Module DataProtectionManager -ErrorAction SilentlyContinue

# Connecting to DPM Server

$DataSources = Get-ProtectionGroup -DPMServerName $DPMServer| %{Get-Datasource -ProtectionGroup $_} 

$Out = @()

$Heading = "<bR><H1>DPM Resource Utilization</h1><br><br>"

Foreach($D in $DataSources)
{

$RecoveryStr = ($d.diskallocation).split('|')[1]

#DPM Resource Utlization Calculations
$RecoveryAllocated, $RecoveryUsed  = $RecoveryStr -split "allocated,"
$RecoveryAllocated = [int](($RecoveryAllocated -split ": ")[1] -split " ")[0]
$RecoveryUsed = [int]((($RecoveryUsed -split " used")[0]) -split " ")[1]
$RecoveryPointVolUtilization =[int]("{0:N2}" -f (($RecoveryUsed/$RecoveryAllocated)*100))

$ReplicaSize = "{0:N2}" -f $($d.ReplicaSize/1gb)
$ReplicaSpaceUsed = "{0:N2}" -f ($d.ReplicaUsedSpace/1gb)
$ReplicaUtilization =[int]("{0:N2}" -f (($ReplicaSpaceUsed/$ReplicaSize)*100))

$NumOfRecoveryPoint = ($d | get-recoverypoint).count

$Out += $d|select ProtectionGroupName, Name, @{name='Replica Size (In GB)';expression={$ReplicaSize}}, @{name='Replica Used Space (In GB)';expression={$ReplicaSpaceUsed}} , @{name='RecoveryPointVolume Allocated (In GB)';expression={$RecoveryAllocated}}, @{name='RecoveryPoint Used Space (In GB)';expression={$RecoveryUsed}},@{name='Total Recovery Points';expression ={$NumOfRecoveryPoint}} , @{name='Replica Utilization %';expression={$ReplicaUtilization}}, @{name='RecoveryPoint Volume Utilization %';expression={$RecoveryPointVolUtilization}}
}
    
# Closing the Connection with DPM server
disconnect-dpmserver -dpmservername $DPMServer

$ResourceUtil = $Out | Sort -property name -descending | convertto-html -fragment

# Adding all HTML data

$html = $a + $heading + $ResourceUtil + $b

If(-not $OutputDirectory)
{
$FilePath = "$((Get-Location).path)\DPM_ResourceUtlization_Report.html"
}
else
{ 
    If($OutputDirectory[-1] -ne '\')
    {
    
        $FilePath = "$OutputDirectory\DPM_ResourceUtlization_Report.html"
    }
    else
    {
        $FilePath = $OutputDirectory+"DPM_ResourceUtlization_Report.html"
    }
}

#Writing the HTML File
$html | set-content $FilePath -confirm:$false
Write-Host "A DPM Resource Utilization Report has been generated on Location : $filePath" -ForegroundColor Yellow

#Sending Email
If($SendEmailTo -and $SMTPServer)
{
Send-MailMessage -To $SendEmailTo -From "DPMMonitor@YourDomain.com" -Subject "DPM Space Utilization Report" -SmtpServer $SMTPServer -Body ($html| Out-String) -BodyAsHtml 
Write-Host "DPM Resource Utilization Report has been sent to email $SendEmailTo" -ForegroundColor Yellow
}






