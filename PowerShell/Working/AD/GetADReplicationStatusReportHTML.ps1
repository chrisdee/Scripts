## Active Directory: PowerShell Script to check the Status of AD Replication across a Forest. Includes HTML report and Email Functionality ##

<#

Overview:

This script uses the output of the repadmin command (repadmin /showrepl) to check the AD replication on all the domain controllers and naming contexts all over an Active Directory forest.
 
If errors are found, a HTML report is sent by email. A full HTML report is also created in a shared folder

Resource: https://www.shellandco.net/check-the-ad-replication-status-forest-wide-and-send-html-report

Usage: Edit the 'Variables' below, along with the mail details in the 'Function send_mail' function and run the script

#>

#Variables
$report_path = "C:\install"
$date = Get-Date -Format "yyyy-MM-dd"
$array = @()
 
#Powershell Function to delete files older than a certain age
$intFileAge = 8  #age of files in days
$strFilePath = $report_path #path to clean up
 
#create filter to exclude folders and files newer than specified age
Filter Select-FileAge {
param($days)
If ($_.PSisContainer) {}
# Exclude folders from result set
ElseIf ($_.LastWriteTime -lt (Get-Date).AddDays($days * -1))
{$_}
}
get-Childitem -recurse $strFilePath | Select-FileAge $intFileAge 'CreationTime' |Remove-Item
 
Function send_mail([string]$message,[string]$subject) {
$emailFrom = "sender@mail.com"
$emailTo = "to@mail.com"
$emailCC = "cc@mail.com"
$smtpServer = "smtp.mail.com"
Send-MailMessage -SmtpServer $smtpServer -To $emailTo -Cc $emailCC -From $emailFrom -Subject $subject -Body $message -BodyAsHtml
}
 
$myForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
$dclist = $myforest.Sites | % { $_.Servers }
 
$html_head = "<style type='text/css'>
table {font-family:verdana,arial,sans-serif;font-size:12px;color:#333333;border-width: 1px;border-color: #729ea5;border-collapse: collapse;}
th {font-family:verdana,arial,sans-serif;font-size:12px;background-color:#acc8cc;border-width: 1px;padding: 8px;border-style: solid;border-color: #729ea5;text-align:left;}
tr {font-family:verdana,arial,sans-serif;background-color:#d4e3e5;}
td {font-family:verdana,arial,sans-serif;font-size:12px;border-width: 1px;padding: 8px;border-style: solid;border-color: #729ea5;}
</style>"
 
foreach ($dcname in $dclist){
$source_dc_fqdn = ($dcname.Name).tolower()
$ad_partition_list = repadmin /showrepl $source_dc_fqdn | select-string "dc="
foreach ($ad_partition in $ad_partition_list) {
[Array]$NewArray=$NULL
$result = repadmin /showrepl $source_dc_fqdn $ad_partition
$result = $result | where { ([string]::IsNullOrEmpty(($result[$_]))) }
$index_array_dst = 0..($result.Count - 1) | Where { $result[$_] -like "*via RPC" }
foreach ($index in $index_array_dst){
$dst_dc = ($result[$index]).trim()
$next_index = [array]::IndexOf($index_array_dst,$index) + 1
$next_index_msg = $index_array_dst[$next_index]
$msg = ""
if ($index -lt $index_array_dst[-1]){
$last_index = $index_array_dst[$next_index]
}
else {
$last_index = $result.Count
}
 
for ($i=$index+1;$i -lt $last_index; $i++){
if (($msg -eq "") -and ($result[$i])) {
$msg += ($result[$i]).trim()
}
else {
$msg += " / " + ($result[$i]).trim()
}
}
$Properties = @{source_dc=$source_dc_fqdn;NC=$ad_partition;destination_dc=$dst_dc;repl_status=$msg}
$Newobject = New-Object PSObject -Property $Properties
$array +=$newobject
}
}
}
 
$status_repl_ko = "<br><br><font face='Calibri' color='black'><i><b>Active Directory Replication Problem :</b></i><br>"
$status_repl_ok = "<br><br><font face='Calibri' color='black'><i><b>Active Directory Replication OK :</b></i><br>"
$subject = "Active Directory Replication status : "+$date
$message = "<br><br><font face='Calibri' color='black'><i>The full Active Directory Replication report is available <a href=" + $report_path + "\ad_repl_status_$date.html>here</a></i><br>"
$message += $status_repl_ko
 
if ($array | where {$_.repl_status -notlike "*successful*"}){
$message += $array | where {$_.repl_status -notlike "*successful*"} | select source_dc,nc,destination_dc,repl_status |ConvertTo-Html -Head $html_head -Property source_dc,nc,destination_dc,repl_status
send_mail $message $subject
}
else {
$message += "<table style='color:gray;font-family:verdana,arial,sans-serif;font-size:11px;'>No problem detected</table>"
}
 
$message += $status_repl_ok
$message += $array | where {$_.repl_status -like "*successful*"} | select source_dc,nc,destination_dc,repl_status |ConvertTo-Html -Head $html_head -Property source_dc,nc,destination_dc,repl_status
$message | Out-File "$report_path\ad_repl_status_$date.html"