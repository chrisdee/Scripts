## MSOnline: PowerShell Script that uses the O365ServiceCommunications module to send a HTML Email Report on Incidents in the o365 Message Center ##

<#
    .DESCRIPTION
    This sample script demonstrates using the O365ServiceCommunications module to alert on incidents posted in the Office 365 
    Message Center (https://portal.office.com/adminportal/home#/servicehealth). It gathers information from the Service Communications API and builds custom HTML tables which are then 
    added to an email message body. This script can be set to run on a schedule using the Windows Task Scheduler to make sure 
    you are aware that an incident has been generated.

    Don't forget to save a credential object to file with 'Get-Credential'. This is required for 
    authentication to the API.

    You'll need to change the values of the $Splat variable below to something that will work in your environment to successfully
    send and email message.

    Usage: Uncomment the 'Get-Credential' command if not already run to store the o365 session credentials, and change the email properties in the ' $Splat' variable before running

    Requires: O365ServiceCommunications PowerShell Module

    Resource: https://github.com/mattmcnabb/O365ServiceCommunications/tree/master/Sample
#>

Import-Module O365ServiceCommunications

# Import a credential object to use against the Service Communications API
# this needs to be a global admin for your Office 365 tenant
# To save a credential, uncomment the line below and run Get-Credential
#Get-Credential | Export-CliXml -Path "C:\temp\0365Reports\cred.xml"
$Credential = Import-Clixml -Path "C:\temp\0365Reports\cred.xml"

# gather events from the Service Communications API
$MySession = New-SCSession -Credential $Credential
$Events = Get-SCEvent -EventTypes Incident -PastDays 1 -SCSession $MySession |
    Select-Object Id, Status, StartTime,
    @{n='ServiceName'; e={$_.AffectedServiceHealthStatus.servicename}},
    @{n='Message';e={$_.messages[0].messagetext}}


if ($Events)
{
    $Tables = foreach ($Event in $Events)
    {
        @"
        <table>
            <tr>
                <th>Id</th>
                <th>ServiceName</th>
                <th>Status</th>
                <th>StartTime</th>
            </tr>
			
            <tr>
                <td>$($Event.Id)</td>
                <td>$($Event.ServiceName)</td>
                <td>$($Event.Status)</td>
                <td>$($Event.StartTime)</td>
            </tr>
        </table>

        <table>
            <tr>
                <td>$($Event.Message)</td>
            </tr>
        </table>
"@
        
    }

    $Html = @"
    <!DOCTYPE HTML>
    <html>
        <Head>
            <style>
                body {}
				table {width: 100%; }
                table, th, td  {
                    font-family: calibri,arial,verdana;
                    border: 2px solid white;
                    border-collapse: collapse;
                    background-color: #daeded;
                }
            </style>
        </head>

        <body>
            $Tables
        </body>
    </html>
"@

    $Splat = @{
        SmtpServer  = 'smtp.YourCompany.com'
        Body        = $Html
        BodyAsHtml  = $true
        To          = 'Your.User@YourDomain.com'
        From        = 'O365Events@YourDomain.com'
        Subject     = 'Office 365 Service Health Alerts'
        Priority    = 'High'
    }
    Send-MailMessage @Splat
}