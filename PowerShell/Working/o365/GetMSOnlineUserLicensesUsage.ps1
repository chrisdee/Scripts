######## 
#LicReport365 v0.5 
#Copyright:     Free to use, please leave this header intact 
#Author:        Jos Lieben (OGD) 
#Company:       OGD (http://www.ogd.nl) 
#Script help:   http://www.liebensraum.nl 
#Purpose:       Create a CSV report detailing license usage in your tenant
#Resources: http://www.lieben.nu/liebensraum/2015/10/licreport365/; https://gallery.technet.microsoft.com/scriptcenter/Office-365-License-User-8336dc24   
######## 
#Requirements: 
######## 
#MS Online Services Signin Assistant: 
#https://www.microsoft.com/en-us/download/details.aspx?id=41950 
#Azure AD Module (x64): 
#http://social.technet.microsoft.com/wiki/contents/articles/28552.microsoft-azure-active-directory-powershell-module-version-release-history.aspx 
######## 
#Changes: 
######## 
#v0.3: changed all variables to objects in a collection, added auto detection of list seperator 
#v0.4: added ActualUse column (licensed users that actually logged in) and mailbox size to the report 
#v0.5: added a time remaining calculation 
 
[cmdletbinding()] 
Param() 
 
$o365login     = $Null           #Username of O365 Admin, will prompt if left empty 
$o365pw        = $Null           #Password of O365 Admin, will prompt if left empty 
$report_folder = "C:\BoxBuild\Scripts\TGFMSOnlineLicenses\"      #don't forget the trailing \ 
$delimiter     = $Null           #CSV column delimiter, uses your local settings if not configured 
$version       = "v0.5" 
$report_file   = Join-Path -path $report_folder -childpath "LicReport365_$($version)_$(Get-Date -format dd_MM_yyyy).csv" 
 
#Set delimiter based on user localized settings if not configured 
if($delimiter -eq $Null) { 
    $delimiter = (Get-Culture).TextInfo.ListSeparator 
} 
 
#A nice pause function that works in any PS version 
function Pause{ 
   Read-Host 'Press any key to continue...' | Out-Null 
} 
 
#Start script 
Write-Host "-----$(Get-Date) LicReport365 $version running on $($env:COMPUTERNAME) as $($env:USERNAME)-----`n" -ForegroundColor Green 
 
#Prompt for login if not defined 
if($o365login -eq $Null -or $o365pw -eq $Null){ 
    $o365Cred = Get-Credential -Message "Please enter your Office 365 credentials" 
}else{ 
    $o365Cred = New-Object System.Management.Automation.PSCredential ($o365login, (ConvertTo-SecureString $o365pw -AsPlainText -Force)) 
} 
 
Write-Progress -Activity "Running report...." -PercentComplete 0 -Status "Loading modules..." 
#Load O365/Azure module 
$env:PSModulePath += ";C:\Windows\System32\WindowsPowerShell\v1.0\Modules\" 
try{ 
    Import-Module MSOnline 
}catch{ 
    Write-Error "CRITICAL ERROR: unable to load Azure AD module, please install the latest version:" 
    Write-Verbose "http://social.technet.microsoft.com/wiki/contents/articles/28552.microsoft-azure-active-directory-powershell-module-version-release-history.aspx" 
    Pause 
    Exit 
} 
 
Write-Progress -Activity "Running report...." -PercentComplete 0 -Status "Connecting to Office 365..." 
#connect to MSOL 
try{ 
    Connect-MsolService -Credential $o365Cred 
}catch{ 
    Write-Error "CRITICAL ERROR: unable to connect to O365, check your credentials" 
    Pause 
    Exit 
} 
 
Write-Progress -Activity "Running report...." -PercentComplete 0 -Status "Setting up remote session to Exchange Online..." 
#connect to Exchange Online 
$EOsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $o365Cred -Authentication Basic -AllowRedirection 
Import-PSSession $EOsession 
 
Write-Progress -Activity "Running report...." -PercentComplete 0 -Status "Fetching license information..." 
#store available licenses 
$licenses = Get-MsolAccountSku 
#add a property that will be incremented to count total usage of this license 
$licenses | Add-Member -MemberType NoteProperty -Name "ReallyUsed" -Value 0 
 
Write-Progress -Activity "Running report...." -PercentComplete 0 -Status "Beginning data collection..." 
$starttime = Get-Date 
#write header for report 
ac $report_file "Results" 
 
#Array that will hold the results 
$colUsers = @() 
 
$done = 0 
#loop over all Office 365 users 
$users = get-msoluser -All 
$totalUsers = $users.Count 
foreach ($user in $users) { 
    $done++ 
    #Build an object per user 
    $colUser = New-Object System.Object 
    if($done -eq 0 -or $totalUsers -eq 0 -or $pct_done -eq 0){ 
        $pct_done = 0.1 
    }else{ 
        $pct_done = ($done/$totalUsers)*100 
    } 
    $colUser | Add-Member -Type NoteProperty -Name UserPrincipalName -Value $user.UserPrincipalName 
    $runtime = ((Get-Date) - $starttime).TotalSeconds 
    $timeleft = ((100/$pct_done)*$runtime)-$runtime 
    Write-Progress -Activity "Running report...." -PercentComplete ($pct_done) -Status "Processing: $($colUser.UserPrincipalName)" -SecondsRemaining $timeleft 
    $colUser | Add-Member -Type NoteProperty -Name Name -Value $user.DisplayName.Replace($delimiter," ") 
    $colUser | Add-Member -Type NoteProperty -Name UserCreatedOn -Value $user.WhenCreated 
    $colUser | Add-Member -Type NoteProperty -Name UsageLocation -Value $user.UsageLocation 
    $last_logon = $Null 
    $mbx_info = get-mailboxstatistics -Identity $colUser.UserPrincipalName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Select LastLogonTime,TotalItemSize 
    if ($mbx_info.LastLogonTime -eq $null){  
        $last_logon = "Never"  
    }else{  
        $last_logon = $mbx_info.LastLogonTime  
    } 
    $colUser | Add-Member -Type NoteProperty -Name LastExchangeLogon -Value $last_logon 
    if($mbx_info.TotalItemSize -ne $Null){ 
        $colUser | Add-Member -Type NoteProperty -Name MailboxSize -Value ([math]::Round(($mbx_info.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1MB),0)) 
    }else{ 
        $colUser | Add-Member -Type NoteProperty -Name MailboxSize -Value $Null 
    } 
    $lic_string = $Null 
    #Convert all licenses this user has to one string (so it fits one cell) 
    foreach($license in $user.Licenses){ 
        if($lic_string -eq $Null) { 
            $lic_string = $license.AccountSkuId 
        }else{ 
            $lic_string = "$($lic_string) $($license.AccountSkuId)" 
        } 
        #increment really used property of this license 
        if($colUser.LastExchangeLogon -ne "Never"){ 
            ($licenses | where-object{$_.AccountSkuId -eq $license.AccountSkuId}).ReallyUsed++ 
        } 
    } 
    $colUser | Add-Member -Type NoteProperty -Name Licenses -Value $lic_string 
    $colUsers += $colUser 
} 
$EOsession | remove-pssession 
 
Write-Progress -Activity "Running report...." -PercentComplete 99 -Status "Writing results to output file...." 
 
#Write license overview to CSV 
try{ 
    ac $report_file "LicReport365 $version" 
    ac $report_file "" 
    ac $report_file "Overview of available licenses" 
}catch{ 
    Write-Error "CRITICAL ERROR: unable to write to $report_file" 
    Pause 
    Exit 
} 
ac $report_file "Type$($delimiter)Total$($delimiter)Assigned$($delimiter)ActualUse$($delimiter)Free" 
foreach($license in $licenses){ 
    ac $report_file "$($license.AccountSkuId)$($delimiter)$($license.ActiveUnits)$($delimiter)$($license.ConsumedUnits)$($delimiter)$($license.ReallyUsed)$($delimiter)$($license.ActiveUnits-$license.ConsumedUnits)" 
} 
 
ac $report_file "" 
#Build CSV header 
$header = $Null 
$colUsers | get-member -type NoteProperty | % { 
    $header += "$($_.Name)$delimiter" 
} 
ac $report_file $header 
 
#Build CSV results 
$colUsers | % { 
    $a = $_ 
    $line = $Null 
    $a | get-member -MemberType NoteProperty | % { 
        $line += "$($a.($_.Name))$delimiter" 
    } 
    ac $report_file $line 
 
} 
 
Write-Progress -Activity "Running report...." -PercentComplete 100 -Status "Task complete!" -Completed 
Write-Host "Report complete: $report_file" -ForegroundColor Green