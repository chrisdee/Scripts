######################################################################################################################
##     Name        : RestartWindowsServices.ps1
##     Function    : Restart the service/s on any given server/s
##    Version      : 1.0
##    Resource     : http://www.sqlservercentral.com/scripts/powershell/87230 
##    Usage        : Admin/Advanced only
##    Notes        : Call in order the server/service you want to restart e.g. FuncRestartService "Server1" "MSSQLSRV01",
##                 ensure that the SMTP/email settings are correct. 
######################################################################################################################

##################
## FUNCTIONS
##################
function FuncMail 
    {#param ($strTo, $strFrom, $strSubject, $strBody, $smtpServer)
    param($To, $From, $Subject, $Body, $smtpServer)
    $msg = new-object Net.Mail.MailMessage
    $smtp = new-object Net.Mail.SmtpClient($smtpServer)
    $msg.From = $From
    $msg.To.Add($To)
    $msg.Subject = $Subject
    $msg.IsBodyHtml = 1
    $msg.Body = $Body
    $smtp.Send($msg)
    }
    
function FuncRestartService ($server, $service) 
{
    $intPingError = 0 
    $intError = 0
    
    $ping = new-object System.Net.NetworkInformation.Ping
    try
        {
            $rslt = $ping.send($server)
        }
    catch
        {
            $intPingError = 1
            $strError = $Error
        }
    if ($intPingError –eq 0) #sucess: ping
        {
     write-host “...ping returned, running service restart”
            try
                {
                    restart-Service -InputObject $(Get-Service -Computer $server -Name $service ) -force
                }
            catch
                {
                    $intError = 1
                    $strError = $Error
                }
            if ($intError -eq 1) #failure: restart - fully exit program
                {
                    Write-Host "...an error occured, notifing by email"
                    FuncMail -To $emTo -From $emFrom -Subject "Server: $server - Error" -Body "$server\$service restart was attempted but failed. Details: $strError" -smtpServer $emSMTP
                    break
                }
            else #success: restart 
                {
                    write-host “...finshed restarting service email sent”
                    FuncMail -To $emTo -From $emFrom -Subject "Server: $server - Restart" -Body "$server\$service has been restarted" -smtpServer $emSMTP
                }
        }
    else #failure: ping - fully exit program
        {
            Write-Host "...ping failed, notifying via email"
            FuncMail -To $emTo -From $emFrom -Subject "Server: $server - Status" -Body "$server is not responding to ping, please investigate. Details: $strError" -smtpServer $emSMTP
            break
        }
}
##################
## EMAIL Variables
##################
$emTo         = 'To@Domain.com'
$emFrom        = 'From@Domain.com'
$emSMTP        = 'domain.com'

##################
## RUN Program
##################
Write-Host "Starting Program..."

##################
## Example
##################

FuncRestartService "Server1" "ServiceName1"
FuncRestartService "Server2" "ServiceName2"

Write-Host "...program complete"

