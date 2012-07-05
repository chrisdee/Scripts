##===========================================================================================##
## SharePoint Server 2010: PowerShell Recycle Bin Status Report With Email Functionality
## Version: 1.0
## Resource: http://sharepoint4newbie.blogspot.com/2011/12/monitor-sharepoint-recycle-bin.html
## Description: This script will perform the following
## 1) List recent deletion (from recent x number of day)
## 2) List deleted documents that will be removed from first-stage recycle bin
## 3) List deleted documents was removed from user recycle bin.
## 4) Send out status email
##===========================================================================================##

#$snapin = Get-PSSnapIn -name "Microsoft.SharePoint.PowerShell" -registered
#if(!$snapin)
#{
Add-PSSnapIn Microsoft.SharePoint.PowerShell
#}

$today = (Get-Date -Format yyyy-MM-dd)

# Host
$url = "http://SP2010/"; #Change this to suit your environment

#Variables for Email
$emailFrom = "SP2010@SharePoint4Newbie.com"
$emailTo = "administrator@SharePoint4Newbie.com"
$smtpServer = "MailServer.SharePoint4Newbie.com"
$emailSubject = "SharePoint Recycle Bin Report - ($today)"

# Number of day in Recycle Bin
$RecentDeletionDay = 7 #Change this to how many days back you want to report on

# Warning Item in recycle bin that is older then x day.
$WarningDay = 30;

$siteCollection = New-Object Microsoft.SharePoint.SPSite($url);

# First lets create a temp text file, where we will later save the recycle bin info
$recycleBinTmpFile = "Recyclebin.htm" #Change this path to suit your environment



#Create a Temp File
New-Item -ItemType file $recycleBinTmpFile -Force

# Function to write the HTML Header to the file
Function writeHtmlHeader
{
param($fileName)
$date = ( get-date ).ToString('yyyy/MM/dd')
Add-Content $fileName "<html>"
Add-Content $fileName "<head>"
Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
Add-Content $fileName '<title>$emailSubject</title>'
Add-Content $fileName '<STYLE TYPE="text/css">'
Add-Content $fileName "<!--"
Add-Content $fileName "td {"
Add-Content $fileName "font-family: Tahoma;"
Add-Content $fileName "font-size: 11px;"
Add-Content $fileName "border-top: 1px solid #F0F0F0;"
Add-Content $fileName "border-right: 1px solid #F0F0F0;"
Add-Content $fileName "border-bottom: 1px solid #F0F0F0;"
Add-Content $fileName "border-left: 1px solid #F0F0F0;"
Add-Content $fileName "padding-top: 0px;"
Add-Content $fileName "padding-right: 0px;"
Add-Content $fileName "padding-bottom: 0px;"
Add-Content $fileName "padding-left: 0px;"
Add-Content $fileName "}"
Add-Content $fileName "body {"
Add-Content $fileName "margin-left: 5px;"
Add-Content $fileName "margin-top: 5px;"
Add-Content $fileName "margin-right: 0px;"
Add-Content $fileName "margin-bottom: 10px;"
Add-Content $fileName ""
Add-Content $fileName "table {"
Add-Content $fileName "border: thin solid #000000;"
Add-Content $fileName "}"
Add-Content $fileName "-->"
Add-Content $fileName "</style>"
Add-Content $fileName "</head>"
Add-Content $fileName "<body>"
Add-Content $fileName "<table width='100%' cellspacing='0' cellpadding='2' >"
Add-Content $fileName "<tr bgcolor='#F0F0F0'>"
Add-Content $fileName "<td colspan='7' height='25' align='center'>"
Add-Content $fileName "<font face='tahoma' color='#003399' size='3'><strong>Site Collection Recycle Bin as of $date</strong></font>"
Add-Content $fileName "</td>"
Add-Content $fileName "</tr>"
Add-Content $fileName "</table>"
}

# Function to write the HTML Header to the file
Function writeTableHeader
{
param($fileName, $groupHeader)
Add-Content $fileName "<table cellspacing='0' cellpadding='2' width='100%'><tr bgcolor=#F0F0F0>"
Add-Content $fileName "<td colspan=6><b>$groupHeader</b></td>"
Add-Content $fileName "</tr>"
Add-Content $fileName "<tr bgcolor=#F0F0F0>"
Add-Content $fileName "<td>Deleted Date</td>"
Add-Content $fileName "<td>Deleted By</td>"
Add-Content $fileName "<td>Type</td>"
Add-Content $fileName "<td>Name</td>"
Add-Content $fileName "<td>Original Path</td>"
Add-Content $fileName "<td>Owner</td>"
Add-Content $fileName "</tr>"
}

# Function to write the Table Footer
Function writeTableFooter
{
param($fileName, $groupFooter)
Add-Content $fileName "<tr>"
Add-Content $fileName "<td colspan=6><b>$groupFooter</b></td>"
Add-Content $fileName "</tr>"
Add-Content $fileName "</table></br>"
}

# Function to write the HTML Footer to the file
Function writeHtmlFooter
{
param($fileName)
Add-Content $fileName "</body>"
Add-Content $fileName "</html>"
}

# Function to write the Recycle Bin Item
Function writeRecycleBinItem
{
param($fileName, $deletedDate, $deletedBy, $itemType, $itemName, $OriginalPath, $itemOwner)
Add-Content $fileName "<tr>"
Add-Content $fileName "<td>$deletedDate</td>"
Add-Content $fileName "<td>$deletedBy</td>"
Add-Content $fileName "<td>$itemType</td>"
Add-Content $fileName "<td>$itemName</td>"
Add-Content $fileName "<td>$OriginalPath</td>"
Add-Content $fileName "<td>$itemOwner</td>"
Add-Content $fileName "</tr>"
}


# Function to send email
Function sendEmail
{
param($from,$to,$subject,$smtphost,$htmlFileName)
$body = Get-Content $htmlFileName
$smtp= New-Object System.Net.Mail.SmtpClient $smtphost
$msg = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body
$msg.isBodyhtml = $true
$smtp.send($msg)
}

writeHtmlHeader $recycleBinTmpFile

#Querying First Stage recyle bin
$recycleQuery = New-Object Microsoft.SharePoint.SPRecycleBinQuery;
$recycleQuery.OrderBy = [Microsoft.SharePoint.SPRecycleBinOrderBy]::DeletedDate;
$firstStageRecycledItems = $siteCollection.GetRecycleBinItems($recycleQuery);

$count = $firstStageRecycledItems.Count;
write-host "Total item after query: $count";

$LastWeek = [DateTime]::Now.AddDays(-$RecentDeletionDay);
$y = 0;

writeTableHeader $recycleBinTmpFile "<a href='http://SP2010/_layouts/AdminRecycleBin.aspx'>First Stage Recycle Bin </a>since last week ($LastWeek)"

for($x = $count; $x -ge 0; $x--)
{
if ( $firstStageRecycledItems[$x].DeletedDate -ge $LastWeek)
{
writeRecycleBinItem $recycleBinTmpFile $firstStageRecycledItems[$x].DeletedDate.ToString() $firstStageRecycledItems[$x].DeletedByName $firstStageRecycledItems[$x].ItemType $firstStageRecycledItems[$x].Title $firstStageRecycledItems[$x].DirName $firstStageRecycledItems[$x].AuthorName;
$y++
}
}
writeTableFooter $recycleBinTmpFile "Total $y items"



$WarningDate = [DateTime]::Now.AddDays(-$WarningDay);
$j = 0;

writeTableHeader $recycleBinTmpFile "First Stage Recycle Bin - These items has been deleted for longer than $WarningDay days ($WarningDate)";

for($i = 0; $i -lt $count; $i++)
{
if ( $firstStageRecycledItems[$i].DeletedDate -le $WarningDate)
{
writeRecycleBinItem $recycleBinTmpFile $firstStageRecycledItems[$i].DeletedDate.ToString() $firstStageRecycledItems[$i].DeletedByName $firstStageRecycledItems[$i].ItemType $firstStageRecycledItems[$i].Title $firstStageRecycledItems[$i].DirName $firstStageRecycledItems[$i].AuthorName;
$j++
}
}
writeTableFooter $recycleBinTmpFile "Total $j items"

#querying second stage recyle bin
$recycleQuery.ItemState = [Microsoft.SharePoint.SPRecycleBinItemState]::SecondStageRecycleBin;
$secondStageRecycledItems = $siteCollection.GetRecycleBinItems($recycleQuery);

$count = $secondStageRecycledItems.Count;
write-host "Total item after query: $count";

$LastWeek = [DateTime]::Now.AddDays(-$RecentDeletionDay);
$y = 0;


writeTableHeader $recycleBinTmpFile "<font color='Red'><a href='http://SP2010/_layouts/AdminRecycleBin.aspx?View=2'>Deleted from end user Recycle Bin </a> since last week </font>($LastWeek)"

for($x = $count; $x -ge 0; $x--)
{
if ( $secondStageRecycledItems[$x].DeletedDate -ge $LastWeek)
{
writeRecycleBinItem $recycleBinTmpFile $secondStageRecycledItems[$x].DeletedDate.ToString() $secondStageRecycledItems[$x].DeletedByName $secondStageRecycledItems[$x].ItemType $secondStageRecycledItems[$x].Title $secondStageRecycledItems[$x].DirName $secondStageRecycledItems[$x].AuthorName;
$y++
}
}
writeTableFooter $recycleBinTmpFile "Total $y items"

writeHtmlFooter $recycleBinTmpFile

#send out email
sendEmail $emailFrom $emailTo $emailSubject $smtpServer $recycleBinTmpFile

$siteCollection.Dispose();

##===========================================================================================##