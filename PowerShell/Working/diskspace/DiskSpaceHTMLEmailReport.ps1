## PowerShell: Script To Show HTML Email Report Of Disk Space Used For Each Drive On A List Of Machines ##

<#
 .SYNOPSIS
    List for several machines the drives with size, free size and the percentage of free space (E-Mail).
 .DESCRIPTION
    An important duty of a DBA is to check frequently the free space of the drives the SQL Server is using to avoid a database crash if a drive is full.    
    With this PowerShell script you can easily check all drives for all servers in the given list. You can configure threshold value for Warning & Alarm level.
    Requires permission to connect to and fetch WMI data from the machine(s).
    The report is then send as an e-mail, eighter as plain text or as html content.
 .PARAMETERS
   $servers: A list of server names.
   $levelWarn: Warn-level in percent.
   $levelAlarm: Alarm-level in percent.
   $smtpServer: The name of your SMTP mail server.
   $sender: The e-mail address of the sender.
   $receiver: The e-mail address of the receiver of the e-mail.
   $subject: The subject line for the e-mail.
   $asHtml: If set to $true, the content is formatted as Html, otherwise as plain text.
 .NOTES
    Author  : Olaf Helper
    Requires: PowerShell Version 1.0
 .LINK
    TechNet Get-WmiObject
        http://technet.microsoft.com/en-us/library/dd315295.aspx
    MSDN SmtpClient
        http://msdn.microsoft.com/en-us/library/system.net.mail.smtpclient.aspx
    MSDN MailMessage
        http://msdn.microsoft.com/en-us/library/system.net.mail.mailmessage.aspx
#>

# Configuration data.
# Add your machine names to check for to the list:
[String[]] $servers   = @("Server1" `
                         ,"Server2" `
                         ,"Server3");
[float]  $levelWarn   = 20.0;
[float]  $levelAlarm  = 10.0;
[string] $smtpServer  = "YouSmtpServerName";
[string] $sender      = "sender@emailaddress.com";
[string] $receiver    = "receiver@emailaddress.com";
[string] $subject     = "Disk usage report";
[bool]   $asHtml      = $true; #Change this valur to false if you don't want the email report as HTML

[string] $body = [String]::Empty;

if ($asHtml)
{
	$body += "<head><title>Disk usage report</title>
              .table {border-collapse: collapse;  border: 1px solid #808080;}
			  .paragraph  {font-family: Arial;font-size:large;text-align: left;border}
			  .boldLeft   {font-family: Arial;font-size:large;text-align: left;border: 1px solid #808080;}
			  .boldRight  {font-family: Arial;font-size:large;text-align: right;border: 1px solid #808080;}
              .smallLeft  {font-family: Arial;text-align: left;border: 1px solid #808080;}
			  .smallRight {font-family: Arial;text-align: right;border: 1px solid #808080;}
              </head><body>";
}
else
{
	$body += "Disk usage report`n`n";
}

Clear-Host;
Write-Host "Started";
### Functions.
function getTextTableHeader
{
    [String] $textHeader = [String]::Empty;
	$textHeader += "Drv ";
	$textHeader += "Vol Name        ";
	$textHeader += "     Size MB ";
	$textHeader += "     Free MB ";
	$textHeader += "    Free % ";
	$textHeader += "Message      `n";
	$textHeader += "--- ";
	$textHeader += "--------------- ";
	$textHeader += "------------ ";
	$textHeader += "------------ ";
	$textHeader += "---------- ";
	$textHeader += "------------ `n";
	
	return $textHeader;
}

function getTextTableRow
{
    param([object[]] $rowData)
    [String] $textRow = [String]::Empty;

    $textRow += $rowData[0].ToString().PadRight(4);
	$textRow += $rowData[1].ToString().PadRight(16);
	$textRow += $rowData[2].ToString("N0").PadLeft(12) + " ";
	$textRow += $rowData[3].ToString("N0").PadLeft(12) + " ";
	$textRow += $rowData[4].ToString("N1").PadLeft(10) + " ";
	$textRow += $rowData[5].ToString().PadRight(13);
	return $textRow;
}

function getHtmlTableHeader
{
	[String] $header = [String]::Empty;
	$header += "<table style=""width: 100%"" class=""table""><tr class=""boldLeft"">
		        <th class=""boldLeft"">Drv</th>
		        <th class=""boldLeft"">Vol Name</th>
		        <th class=""boldRight"">Size MB</th>
		        <th class=""boldRight"">Free MB</th>
		        <th class=""boldRight"">Free %</th>
		        <th class=""boldLeft"">Message</th></tr>";
	return $header;
}

function getHtmlTableRow
{
    param([object[]] $rowData)
    [String] $textRow = [String]::Empty;
    $textRow += "<tr class=""smallLeft"">
		<td class=""smallLeft"">"  + $rowData[0].ToString()     + "</td>
		<td class=""smallLeft"">"  + $rowData[1].ToString()     + "</td>
		<td class=""smallRight"">" + $rowData[2].ToString("N0") + "</td>
		<td class=""smallRight"">" + $rowData[3].ToString("N0") + "</td>
		<td class=""smallRight"">" + $rowData[4].ToString("N1") + "</td>
		<td class=""smallLeft"">"  + $rowData[5].ToString()     + "</td></tr>";
	return $textRow;
}

foreach($server in $servers)
{
    $disks = Get-WmiObject -ComputerName $server -Class Win32_LogicalDisk -Filter "DriveType = 3";

	if ($asHtml)
	{   $body += ("<p class=""paragraph"">Server: {0}`tDrives #: {1}</p>`n" -f $server, $disks.Count);
	 	$body += getHtmlTableHeader;
	}
	else
	{	$body += ("Server: {0}`tDrives #: {1}`n" -f $server, $disks.Count);
		$body += getTextTableHeader;
	}

	foreach ($disk in $disks)
	{
		[String] $message = [String]::Empty;
		if (100.0 * $disk.FreeSpace / $disk.Size -le $levelAlarm)
		{   $message = "Alarm !!!";   }
		elseif (100.0 * $disk.FreeSpace / $disk.Size -le $levelWarn)
		{   $message = "Warning !";   }
		
		[Object[]] $data = @($disk.DeviceID, `
			                 $disk.VolumeName, `
			                 [Math]::Round(($disk.Size / 1048576), 0), `
							 [Math]::Round(($disk.FreeSpace / 1048576), 0), `
							 [Math]::Round((100.0 * $disk.FreeSpace / $disk.Size), 1), `
							 $message)
		if ($asHtml)
		{	$body += getHtmlTableRow -rowData $data;    }
		else
		{	$body += getTextTableRow -rowData $data;	}
		
	    $body += "`n";
	}
	
	if ($asHtml)
	{   $body += "</table>`n";	}
	else
	{	$body += "`n";	}
}

if ($asHtml)
{   $body += "</body>";	}

# Init Mail address objects
$smtpClient = New-Object Net.Mail.SmtpClient($smtpServer);
$emailFrom  = New-Object Net.Mail.MailAddress $sender, $sender;
$emailTo    = New-Object Net.Mail.MailAddress $receiver , $receiver;
$mailMsg    = New-Object Net.Mail.MailMessage($emailFrom, $emailTo, $subject, $body);

$mailMsg.IsBodyHtml = $asHtml;
$smtpClient.Send($mailMsg)

Write-Host "Finished";