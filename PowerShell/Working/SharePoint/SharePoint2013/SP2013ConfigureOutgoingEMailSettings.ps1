############################################################################################################################################ 
# SharePoint: PowerShell Script to configure Outgoing E-Mail Settings
# Environments: SharePoint Server 2010 / 2013 Farms
# Resource: https://gallery.technet.microsoft.com/office/Script-to-configure-b420245a
# Required Parameters:  
#    ->$sSMTPServer: SMTP Server. 
#    ->$sFromEMail: From Address. 
#    ->$sReplyEMail: To Address. 
#    ->$sChartSet: Character Set.
# Usage Example: Configure-OutGoingEMail "email.yourdomain.com" "sp@yourdomain.com" "sp@yourdomain.com" "65001"
############################################################################################################################################ 
 
If ((Get-PSSnapIn -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null )  
{ Add-PSSnapIn -Name Microsoft.SharePoint.PowerShell } 
 
 
$host.Runspace.ThreadOptions = "ReuseThread" 
 
#Definition of the function that configures outgoing e-mail in SharePoint 
function Configure-OutGoingEMail 
{ 
    param ($sSMTPServer,$sFromEMail,$sReplyEmail,$sCharSet) 
    try 
    {    
        $CAWebApp = Get-SPWebApplication -IncludeCentralAdministration | Where { $_.IsAdministrationWebApplication } 
        $CAWebApp.UpdateMailSettings($sSMTPServer, $sFromEMail, $sReplyEmail, $sCharSet) 
        write-host -f Blue "Outgoing e-mail configured"                
    } 
    catch [System.Exception] 
    { 
        write-host -f red $_.Exception.ToString() 
    } 
} 
 
Start-SPAssignment –Global 
 
#Required Objects 
$sSMTPServer='<SMTP_Server>' 
$sFromEMail='<From_EMail>' 
$sReplyEmail='<Reply_EMail>' 
$sChartSet=65001 
 
#Calling the function 
Configure-OutGoingEMail -sSMTPServer $sSMTPServer -sFromEMail $sFromEMail -sReplyEmail $sReplyEmail -sCharSet $sChartSet 
 
Stop-SPAssignment –Global