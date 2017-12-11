## Exchange Online: PowerShell Script to Get Mail Traffic Reports from an o365 Tenant (includes Malware and Spam reports) using Exchange Online Protection PowerShell ##

<#

Overview: PowerShell Script that connects to Exchange Online and produces Mail Traffic reports using the Exchange Online Protection PowerShell Reports Cmdlets

Resources: http://www.checkyourlogs.net/?p=43563; https://technet.microsoft.com/EN-US/library/dn621038(v=exchg.160).aspx

#>

#Connect to Office 365
$usercredential = get-credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session
 
#Run the Sample Reports 
Get-MailTrafficATPReport | Out-GridView
 
Get-MailDetailMalwareReport | Select-Object Date,Domain,Subject,Direction,SenderAddress,RecipientAddress,EventType,Action,FileName,MalwareName | Out-GridView
 
Get-MailDetailSpamReport |Select-Object Date,Domain,Subject,Direction,SenderAddress,RecipientAddress,EventType | Out-GridView
 
Get-MailFilterListReport | Out-GridView
 
Get-MailTrafficReport | Out-GridView
Get-MailTrafficSummaryReport -Category TopMailSender | Select-Object C1,C2,C3 | Out-GridView
Get-MailTrafficSummaryReport -Category TopMailRecipient | Select-Object C1,C2,C3 | Out-GridView
Get-MailTrafficSummaryReport -Category TopMalWare | Select-Object C1,C2,C3 | Out-GridView
Get-MailTrafficSummaryReport -Category TopMalWareRecipient | Select-Object C1,C2,C3 | Out-GridView
Get-MailTrafficSummaryReport -Category TopSpamRecipient | Select-Object C1,C2,C3 | Out-GridView
 
 
Get-MailTrafficTopReport | Out-GridView
Get-UrlTrace | Select-Object Clicked,Workload,AppName,ReceipientAddress,URL,URLBlocked,URLClicked | Out-GridView
Get-MessageTrace -PageSize 2500 | Where-Object {$_.Status -ne "Delivered"} | Out-GridView