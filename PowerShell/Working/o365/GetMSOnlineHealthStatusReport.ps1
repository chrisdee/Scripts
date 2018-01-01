## MSOnline: PowerShell Script to Produce an Office 365 (o365) Tenant Health Report with Email Functionality ##

<#
.SYNOPSIS
Office365DailyCheck.ps1 - Generate an Office 365 daily check HTML file and send output via email.

.DESCRIPTION 
This script provides an email and HTML report of total EXO mailboxes, remaining licenses, DirSync last sync and the last 24 hours
from the Service Health Dashboard, Message Center and IP/Subnet changes RSS feed.

.OUTPUTS
HTML file saved for archiving purposes.
Email to defined recipient(s).

.NOTES
Written by Dale Morson

Run as a scheduled task calling a .bat file. For example:
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -noexit -command "C:\Scripts\Office365DailyChecks\Office365DailyCheck.ps1"

Version history:
V1.00, 08/06/2017 - Initial version | 

Resources: 

https://github.com/dalemorson/Office365DailyChecks

https://github.com/mattmcnabb/O365ServiceCommunications (O365ServiceCommunications PowerShell Module)

https://www.cogmotive.com/blog/office-365-tips/guest-blog-office-365-health-monitoring-with-powershell

License:

The MIT License (MIT)

Copyright (c) 2017 Dale Morson

Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.
#>

#requires -Modules O365ServiceCommunications

#region Variables

$scriptLoc = "C:\temp\0365Reports\"
$date = get-date -format dd-MM-yyyy

# SMTP details
$SmtpServer  = ''
[string[]] $To = ""
$From        = ''
$Subject     = "Office 365 Daily Check for $date"

# Office 365 SkuID
# Example COMPANYNAME:ENTERPRISEPACK
# Use Get-MsolAccountSku to get a list of AccountSkuId's
$TenantPrefix = "YourTenant" #Change this prefix property to match your tenant name
$AccountSkuId = "$TenantPrefix"+":ENTERPRISEPACK"

#endregion

#region Script Configuration

### IMPORTANT ###

# This script requires a credential object. Run the below to create a new credential object. The creds provided must be a Global Admin.
# Get-Credential | Export-CliXml -path "$scriptLoc\cred.xml"

# If the server running this script doesn't use ExpressRoute connectivity, set the Windows OS proxy.
# netsh winhttp set proxy proxy-server="http=<ip>:<port>;https=<ip>:<port>" bypass-list="*.domain.local;10.*"

# This sets the PowerShell session to use the credentials of the user running the session to authenticate against the proxy.
# Uncheck if there is no proxy server. 
# (New-Object System.Net.WebClient).Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

### END IMPORTANT ###

# Check if the script location path exists, if not create it.
if(!(Test-Path -Path $scriptLoc )){
    New-Item -ItemType directory -Path $scriptLoc
}

# Check if the Checks and Logs sub-folders exist, if not create it.
$checksLoc = "$scriptLoc\Checks"
if(!(Test-Path -Path "$checksLoc" )){
    New-Item -ItemType directory -Path $checksLoc
}

$logsLoc = "$scriptLoc\Logs"
if(!(Test-Path -Path "$logsLoc" )){
    New-Item -ItemType directory -Path $logsLoc
}

# Start transcript
Start-Transcript "$scriptLoc\Logs\log-$date.txt"

# Check if O365ServiceCommunications module is available, if not, install.
if (Get-Module -ListAvailable -Name O365ServiceCommunications) {
} else {
Find-Module O365ServiceCommunications | Install-Module
}

# Import the O365ServiceCommunications module.
Import-Module O365ServiceCommunications

# Import the credential object to use against the Service Communications API.
$Credential = Import-Clixml -Path "$scriptLoc\cred.xml"

# Connect to the Office 365 tenant.
Connect-MsolService -Credential $Credential

# Connect to Exchange Online.
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $Credential -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber

#endregion

#region Get Information Last 24 Hours

### SERVICE HEALTH

# Gather events from the past 24 hours from the Service Communications API.
$MySession = New-SCSession -Credential $Credential
$Incidents = Get-SCEvent -EventTypes Incident -SCSession $MySession |  Where-Object { $_.StartTime -gt (Get-Date).AddDays(-1) } | Select-Object Id, Status, StartTime, @{n='ServiceName'; e={$_.AffectedServiceHealthStatus.servicename}}, @{n='Message';e={$_.messages[0].messagetext}}

# Build $HTML file of incidents
if ($Incidents)
{
    $IncidentTables = foreach ($Event in $Incidents)
    {
        $u = switch ($Event.Status){
        'Normal Service' {' style="color:#000000;background-color:#98FB98;font-weight:bold"'}  #green
        'Investigating' {' style="color:#000000;background-color:#98FB98;font-weight:bold"'} #green
        'Service interruption' {' style="color:#ffffff;background-color:#ffbf00;font-weight:bold"'} #amber
        'Service degradation'  {' style="color:#ffffff;background-color:#ff0000;font-weight:bold"'} #red
        'Restoring service' {' style="color:#ffffff;background-color:#ffbf00;font-weight:bold"'} #amber
        'Extended recovery' {' style="color:#ffffff;background-color:#ffbf00;font-weight:bold"'} #amber
        'Service restored' {' style="color:#000000;background-color:#98FB98;font-weight:bold"'} #green
        'Additional information' {' style="color:#000000;background-color:#98FB98;font-weight:bold"'} #green
        Default {' style="color:#000080;font-weight:bold"'} 
}
        @"
<p></p>
        <table>
            <tr>
                <th>Id</th>
                <th>Service Name</th>
                <th>Status</th>
                <th>Start Time</th>
            </tr>
                      
            <tr>
                <td>$($Event.Id)</td>
                <td>$($Event.ServiceName)</td>
                <td$u>$($Event.Status)</td>
                <td>$($Event.StartTime)</td>
            </tr>
        </table>
        <table>
            <tr>
                <td>$($Event.Message -replace("`n",'<br>') -replace([char]8217,"'") -replace([char]8220,'"') -replace([char]8221,'"') -replace('\[','<b><i>') -replace('\]','</i></b>'))</td>
            </tr>
        </table>
 <table><tr></tr></table>
"@
        
    }

}
else
{
# Write to HTML there have been no incidents in the last 24 hours
$incidentTables = "There are no new O365 Service Health incidents reported in the past 24 hours."
}

### MESSAGE CENTER

# Get past 24 hours of items from Message Center
$Messages = Get-SCEvent -EventTypes message -SCSession $MySession | Where-Object { $_.StartTime -gt (Get-Date).AddDays(-1) } | Select-Object Title, Category, UrgencyLevel, ActionType, Id, ExternalLink, StartTime, Messages | Sort-Object -Property StartTime

# Build $HTML file of incidents
if ($Messages)
{
    $MessageTables = foreach ($Message in $Messages)
    {

    $u = switch ($Message.UrgencyLevel){
        'Critical' {' style="color:#ffffff;background-color:#ff0000;font-weight:bold"'} #red backgound/white text/bold
        'High' {' style="color:#ffffff;background-color:#ffbf00;font-weight:bold"'} #amber background/white text/bold
        'Normal' {' style="color:#000000;background-color:#98FB98;font-weight:bold"'} #black text
        Default {' style="color:#000080;font-weight:bold"'} 
}

        @"
       <p></p>
        <table>
            <tr>
                <th>Id</th>
                <th>Title</th>
                <th>Urgency Level</th>
                <th>Action Type</th>
                <th>Category</th>
                <th>External Link</th>
                <th>Start Time</th>
            </tr>
                      
            <tr>
                <td>$($Message.Id)</td>
                <td>$($Message.Title)</td>
                <td$u>$($Message.UrgencyLevel)</td>
                <td>$($Message.ActionType)</td>
                <td>$($Message.Category)</td>
                <td>$($Message.ExternalLink)</td>
                <td>$($Message.StartTime)</td>
            </tr>
        </table>
        <table>
            <tr>
                <td>$($Message.Messages -replace("`n",'<br>') -replace([char]8217,"'") -replace([char]8220,'"') -replace([char]8221,'"') -replace('\[','<b><i>') -replace('\]','</i></b>'))</td>
            </tr>
        </table><p></p>
 <table><tr></tr></table>
"@
       
    }
}
else
{
$MessageTables = "There are no new Office 365 messages from the Message Center in the past 24 hours."
}

### EXPRESSROUTE IP CHANGES

# Parse the IP and subnet change RSS feed
$webclient = new-object system.net.webclient
$rssFeed = [xml]$webclient.DownloadString('https://support.office.com/en-us/o365ip/rss')
$feed = $rssFeed.rss.channel.item | select title,description,link, @{LABEL=”Published”; EXPRESSION={[datetime]$_.pubDate} }
$feed = $feed | Where-Object { $_.Published -gt (Get-Date).AddDays(-1) }

# Build $HTML for IP and subnet changes
if ($feed)
{
    $ipChangeTables = foreach ($ipChange in $feed)
    {
        @"
        <p></p>
        <table>
            <tr>
                <th>Title</th>
                <th>Link</th>
                <th>Published Date</th>

            </tr>
                      
            <tr>
                <td>$($ipChange.Title)</td>
                <td>$($ipChange.Link)</td>
                <td>$($ipChange.Published)</td>
            </tr>
        </table>
        <table>
            <tr>
                <td>$($ipChange.Description)</td>
            </tr>
        </table>
 <table><tr></tr></table>
"@
       
    }
}
else
{
$ipChangeTables = "There are no reported IP or subnet changes in the past 24 hours."
}

### TENANT STATS

# Get dirsync status.
$dirSyncStatus = Get-MsolCompanyInformation | select -ExpandProperty LastDirSyncTime

# Get the total amount of mailboxes in Exchange Online.
$totalO365Mailboxes = (get-mailbox -ResultSize Unlimited).count

# Get the remaining amount of licenses.
$activeUnitsObj = Get-MsolAccountSku | ? { $_.AccountSkuId -eq $AccountSkuId } | select ActiveUnits
$activeUnitsStr = $activeUnitsObj | select -ExpandProperty ActiveUnits
[int]$activeUnitsInt = $activeUnitsStr
$consumedUnitsObj = Get-MsolAccountSku | ? { $_.AccountSkuId -eq $AccountSkuId } | select ConsumedUnits
$consumedUnitsStr = $consumedUnitsObj | select -ExpandProperty ConsumedUnits
[int]$consumedUnitsInt = $consumedUnitsStr
[int]$remainingUnitsInt = $activeUnitsInt - $consumedUnitsInt

#endregion 

#region Build HTML Output

$Html = @"
<!DOCTYPE HTML>
    <html>
    <head>
    <style>
        table, th, td { border: 1px solid #C3C3C3; padding: 4px 4px; border-collapse: collapse;}
        th { text-align: left; }
        h2 { text-decoration: underline; }
    </style>
    </head>
    <body>
        <h2>Tenant Stats</h2>
            <table>
                <tr>
                <th>Total Migrated/Remote Mailboxes:</th>
                <th>$totalO365Mailboxes</th>
                </tr>
                <tr>
                <th>Remaining Enterprise E3 Licenses:</th>
                <th>$remainingUnitsInt</th>
                </tr>
                <tr>
                <th>DirSync Last Sync:</th>
                <th>$dirSyncStatus</th>
                </tr>
            </table>
        <h2>Service Health Incidents</h2>
            $IncidentTables
        <h2>Message Center Alerts</h2>
            $messageTables
        <h2>IP and Subnet Changes</h2>
            $ipChangeTables          
        <p></p>
    </body>
</html>
"@

#endregion

#region Archive HTML and Email Recipient(s)

# Save output to a HTML file to the Checks folder for archiving.
$html | Out-File $scriptLoc\Checks\$date.html

# Build email splat
    $Splat = @{
        SmtpServer  = $SmtpServer
        Body        = $Html
        BodyAsHtml  = $true
        To          = $To
        From        = $From
        Subject     = $Subject
    }

# Send email
Send-MailMessage @Splat

#endregion

# Destroy session
Remove-PSSession $Session