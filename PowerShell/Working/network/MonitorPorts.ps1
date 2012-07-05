## PowerShell: Port Monitoring Script for Devices And Also Includes HTML Email Functionality ##
# 
# Resource: http://www.corelan.be/index.php/2009/01/28/monitoring-your-network-with-powershell
# Version : 1.0
#
# This script will attempt to connect to remote hosts/ports and report whether the port is reachable or not
# 
# Parameters :
#    Parameter 1 : the name of the file that contains the hosts and ports that need to be checked
#         Format of each entry in this file is
#            host:port:open    (do not alert if the port is open)
#            host:port:closed  (do not alert if the port is closed)
#    You can only define one entry/host per line
#    You can group hosts by adding a line that has a group name between square brackets
#      example :   [Mailservers]
#
# In the folder where this script is located, you need to create another file called smtp.cfg
# This file needs to contain the settings that will be used to send alerts to :
#   smtpserver=<ip address or hostname of the smtpserver>
#   smtpserverport=<smtp port> (default would be 25)
#   subject=<String that will be used as subject in each email.>
#           You can use the following variables in the subject :
#			%hostname% :  the hostname of the server where the script is running
#           %timestamp% : the timestamp of when the report was created
#           %events% : the number of logged events that need to be looked at
#   from=<email address to be used as 'From' address>
#   to=<email address or addresses, comma separated>
#   alertmode=<1 or 2>
#        1 : only send report when something is wrong
#        2 : always send report
#   reportmode=<1 or 2>  
#        1 : only show alerts in report
#        2 : show all hosts in report
#
# Functions
function Test-TcpPort([string]$dhost, [string]$dport)
{
	$ErrorActionPreference = “SilentlyContinue”
	$socket = new-object Net.Sockets.TcpClient
	$socket.Connect($dhost, $dport)

	if ($dhost -and $socket.Connected) {
	$status = "open"
	$socket.Close()
	}
	else {
	$status = "closed"
	}
	$socket = $null
	return $status
}

function Get-ReportOption([string]$option)
{
  $valuetoreturn=""
  #open smtp.cfg
  Get-Content "smtp.cfg" | ForEach-Object {
  $cfgData = $_.split('=')
  $param = $cfgData[0]
  $pvalue = $cfgData[1]
  
  if ($param.ToLower().Trim() -eq $option.ToLower().Trim())
  {
  	$valuetoreturn = $pvalue.Trim()
  }
  }
  return $valuetoreturn
}

#
# Main application
#
# Declare variables
$timestamp=[string]((Get-Date).day) +"/" + [string]((Get-Date).month)+"/"+[string]((Get-Date).year)+", "+[string]((Get-Date).hour)+":"+[string]((Get-Date).minute)+":"+[string]((Get-Date).second)
$htmlheader = "<html><head><title>PVE Port Monitor Report</title></head><body>"
$htmlbody = "<body link='#000000' vlink='#000000' alink='#00000F' text='#000000' bgcolor='#888888'>"
$htmlbody = $htmlbody+"<div align='center'><center>"
$htmlbody = $htmlbody+"<table border='1' cellpadding='0' cellspacing='0' style='border-collapse: collapse' "
$htmlbody = $htmlbody+"bordercolor='#CCCCCC' width='38%' id='AutoNumber1' bordercolorlight='#CCCCCC' bordercolordark='#CCCCCC'><tr>`n"
$htmlbody = $htmlbody+"<td width='100%'><p align='center'><font face='Arial' size='3'><b>PVE Port Monitor Report</b></font></td></tr>`n"
$htmlbody = $htmlbody+"</table></center></div><br>"
$htmlbody = $htmlbody+"<div align='center'><center>"
$htmlbody = $htmlbody + "<font face='Arial' size='2'>"
$htmlbody = $htmlbody + "Current date/time : $timestamp </font><br><br>`n"
$htmlbody = $htmlbody + "<table border='2' cellpadding='0' cellspacing='0' style='border-collapse: collapse' bordercolor='#111111'"
$htmlbody = $htmlbody + " width='49%' id='AutoNumber2' bordercolordark='#CCCCCC' bordercolorlight='#CCCCCC'>`n"
$htmlbody = $htmlbody + "<tr>"
$htmlbody = $htmlbody + "<td width='63%' align='center' bgcolor='#11AAEF'><b><font face='Arial' size='2'>Host</font></b></td>"
$htmlbody = $htmlbody + "<td width='19%' align='center' bgcolor='#11AAEF'><b><font face='Arial' size='2'>Port</font></b></td>"
$htmlbody = $htmlbody + "<td width='38%' align='center' bgcolor='#11AAEF'><b><font face='Arial' size='2'>Event</font></b></td>`n"
$htmlbody = $htmlbody + "</tr>"
#
$htmlfooter = "</table><br><font face='Arial' size='-1'><a href='http://www.corelan.be:8800'>PVE Port Monitor - Peter Van Eeckhoutte - http://www.corelan.be:8800</font>`n"
$htmlfooter  = $htmlfooter + "</center></div>"
$htmlfooter  = $htmlfooter +  "</body>"
$htmlfooter  = $htmlfooter + "</html>";
#
$nrofevents=0
#
$hname = $env:computername
#
# Show application banner
cls
Write-Host "---------------------------------"
Write-Host " pve_portmonitor.ps1"
Write-Host " Written by Peter Van Eeckhoutte"
Write-Host " http://www.corelan.be:8800"
Write-Host "---------------------------------`n"
# See if smtp.cfg exists
$smtpfileExists = Test-Path("smtp.cfg")
if ($smtpfileExists -eq $false)
{
  Write-Host "`n *** smtp.cfg config file not found *** `n"
}
else
{
	# Get parameters
	$alertmode=Get-ReportOption("alertmode")
	$reportmode=Get-ReportOption("reportmode")
	#
	#
	if ($args.Count -gt 0)
	{
		# If there is at least one parameter 
		# See if file exists
		$fileExists = Test-Path($args[0])
		if ($fileExists -eq $true)
		{
			Write-Host "[+] Reading input file"
			
			Get-Content $args[0] | ForEach-Object {
			#see if string starts with square brackets
			if ($_.StartsWith("[") -eq $true)
			{
			    #write new table header to HTML
			    $htmlbody = $htmlbody + "<tr><td width='100%' colspan='3' bgcolor='#66FFFF'><b><font face='Arial' size='2'>$_</font></b></td></tr>"
			}
			else
			{
			    #host entry ?
			    if (($_.Startswith("#") -eq $false) -and ($_.length -gt 0))
			    {
			    	$thishost=$_.split(":")
			    	$targethost=$thishost[0]
			    	$targetport=$thishost[1]
			    	$expectedstatus=$thishost[2]
					Write-Host "  - Connecting to host $targethost to verify that port tcp $targetport is $expectedstatus"
					$currentstatus=Test-TcpPort $targethost $targetport
					Write-Host "    Result : port is $currentstatus"
					#is this what we had expected ?
					$reportstatus=$currentstatus.ToUpper()
					if ($currentstatus.ToLower().Trim() -eq $expectedstatus.ToLower().Trim())
					{
						#yes. Only add to html if reportmode is 2
						if ($reportmode -eq "2")
						{
							$htmlbody = $htmlbody + "<tr><td width='63%' align='center' bgcolor='#00FF00'><b><font face='Arial' size='2'>$targethost</font></b></td>`n"
							$htmlbody = $htmlbody + "<td width='19%' align='center' bgcolor='#00FF00'><b><font face='Arial' size='2'>$targetport</font></b></td>`n"
							$htmlbody = $htmlbody + "<td width='38%' align='center' bgcolor='#00FF00'><font face='Arial' size='2'>$reportstatus</font></td></tr>`n"
						}
					}
					else
					{
						
						$nrofevents++
						# no. Add to html
						$htmlbody = $htmlbody + "<tr><td width='63%' align='center' bgcolor='#FF0000'><b><font face='Arial' size='2'>$targethost</font></b></td>`n"
						$htmlbody = $htmlbody + "<td width='19%' align='center' bgcolor='#FF0000'><b><font face='Arial' size='2'>$targetport</font></b></td>`n"
						$htmlbody = $htmlbody + "<td width='38%' align='center' bgcolor='#FF0000'><font face='Arial' size='2'>$reportstatus</font></td></tr>`n"
					}
			    }
			  }	  
			}
		    #done - save to report.html and send email if necessary
		    Write-Host "`n[+] Writing report to report.html`n"
		    $htmlreport = $htmlheader + $htmlbody + $htmlfooter
		    $htmlreport | Out-File "report.html"
		    if (($nrofevents -gt 0) -or ($alertmode -eq "2"))
		    {
				#send email
				$rcptto=Get-ReportOption("to")
				$smtpServer = Get-ReportOption("smtpserver")
				$smtpPort = Get-ReportOption("smtpserverport")
				$mailfrom = Get-ReportOption("from")
				$subject = Get-ReportOption("subject")
				$subject=$subject.replace("%timestamp%",$timestamp)
				$subject=$subject.replace("%events%",$nrofevents)
				$subject=$subject.replace("%hostname%",$hname)
				Write-Host "[+] Sending email to $rcptto"
				$smtp = new-object Net.Mail.SmtpClient($smtpServer,$smtpPort)
				$mailmsg = New-Object net.Mail.MailMessage($mailfrom,$rcptto,$subject,$htmlreport)
				$mailmsg.IsBodyHTML = $true
				$smtp.Send($mailmsg)
				Write-Host "    Done.`n"
			}
		}
		else
		{
		 Write-Host "`n*** Input hosts/ports file could not be found *** `n" 
		}
	  }
	  else
	  {
	   Write-Host "`n*** You must specify the path/filename of the file that contains the hosts/ports to check ***`n"
	  }
}




