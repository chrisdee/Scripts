<# SharePoint Server: PowerShell Script To Monitor And Email Alerts On Lists with Large Numbers Of Items

Overview: PowerShell script that checks for list libraries with more items than specified, and emails a summary of these.
Also has an 'Exclude' array to exclude reporting on specified list libraries.

Usage: Edit the following variables '$site'; '$limit'; '$exclude'; '$smtpServer'; and '$smtp' to suit your requirements

Environments: SharePoint Server 2010 / 2013 Farms

Resource: http://kowalski.ms/2012/07/25/sharepoint-large-list-notifier

#>
 
# Add PowerShell Snapin
Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue
 
# Host site
$site = Get-SPSite "http://portal.domain.local" #Change this to suit your environment
 
# List Limit
$limit = 5000 #Change this item limit variable to match your environment requirements
# Exlude
$exclude = @("TaxonomyHiddenList",
    "User Information List",
    "Accepted List 01",
    "Accepted List 02"
    )
 
# Create Data Table
$table = New-Object System.Data.DataTable "Large Lists"
# Create Columns
$col1 = New-Object system.Data.DataColumn Title,([string])
$col2 = New-Object system.Data.DataColumn Url,([string])
$col3 = New-Object system.Data.DataColumn Items,([int])
# Add Columns
#Add the Columns
$table.Columns.Add($col1)
$table.Columns.Add($col2)
$table.Columns.Add($col3)
 
foreach ($web in $site.AllWebs   ) {
    foreach ($list in $web.Lists  ) {
        if ($list.ItemCount -gt $limit) {
                # Uncomment if you want to see the results on the console
                # Write-Host "Title:" -ForegroundColor Black -BackgroundColor Cyan -NoNewline
                # Write-Host " " -NoNewline
                # Write-Host $list.Title -ForegroundColor White
                # Write-Host "  URL: " -ForegroundColor DarkCyan -NoNewline
                # Write-Host $list.DefaultViewUrl -ForegroundColor Gray
                # Write-Host "Items: " -ForegroundColor DarkCyan -NoNewline
                # Write-Host $list.ItemCount -ForegroundColor Gray
 
                # Exclude sites that can have more items
                if ($exclude -contains $list.Title) {
                    # Ignore
                }
                else {
                    # Add into table
                    $row = $table.NewRow()
                    $row.Title = $list.Title
                    $row.Url = $list.DefaultViewUrl
                    $row.Items = $list.ItemCount
                    $table.Rows.Add($row)
                }
 
            }
 
            else {
                # Ignore
            }
 
    }
}
 
if ($table.Rows.Count -eq 0) {
    # Do nothing
}
else {
    $tableSites = $table | Format-Table -AutoSize | Out-String
    # Send email containing large lists
    # SMTP Server
    $smtpServer = "smtp.domain.local"
    # Net Mail Object
    $msg = New-Object Net.Mail.MailMessage
    # SMTP Server Object
    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    # Email
    $msg.From = "Large.Lists@domain.local"
    $msg.ReplyTo = "Large.Lists@domain.local"
    $msg.To.Add("Recipient.One@domain.local")
    $msg.To.Add("Recipient.Two@domain.local")
    $msg.CC.Add("Recipient.Three@domain.local")
    $msg.Subject = "[WARNING] The following list/s are above $limit items."
    $msg.Body =
"Greetings,
 
The following lists have more items then the recommended limit;
 
$tableSites
Regards,`n
 
--
Large List Notifier
"
    # Send Message
    $smtp.Send($msg)
}
 
# Clear and Dispose Table
#$table
$table.Clear()
$table.Dispose()