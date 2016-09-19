## Active Directory: PowerShell Script To Query DCs in a Domain to Report on Users SIDs and SIDHistory to Estimate their Token Size  ##

<#

Overview:

This script will query for the items which make up the token and then calculate the token size based on that dynamic result using the formula in KB327825. It will also give you a total of how many SIDs are in the SIDHistory for the user, how many of each group scope the user has, and whether the account is trusted for delegation or not (if it is the token size may be much larger).

The script has had a major rewrite and now can be ran against a single user or a collection of users to gauge their estimate token size and provide information about where the "bloat" or size is coming from-specific groups, types of groups, group SIDHistory SIDs, user SIDHistory SIDs or Windows Kerberos claims (for Windows 8/Server 2012 or later computers).

Requires: ActiveDirectory PowerShell Module

Usage Example:

.\CheckMaxTokenSize.ps1 -Principals @('FirstName.LastName@YourOrganization.com', 'FirstName1.LastName1@YourOrganization.com') $OSEmulation $false -Details $true

Resources:

https://gallery.technet.microsoft.com/scriptcenter/Check-for-MaxTokenSize-520e51e5#content

http://support.microsoft.com/kb/327825

#>

PARAM ([array]$Principals = ($env:USERNAME), $OSEmulation = $false, $Details = $false)

cls

Import-Module ActiveDirectory

Trap [Exception] 
      {
      $Script:ExceptionMessage = $_
      $Error.Clear()
     continue
      }

$ExportFile = $pwd.Path + "\" + $env:username + "_TokenSizeDetails.txt"
$global:FormatEnumerationLimit = -1

"Token Details for all Users" | Out-File -FilePath $ExportFile 
"********************" | Out-File -FilePath $ExportFile -Append
"`n"  | Out-File $ExportFile -Append

#If OS is not specified to hypothesize token size let's find the local OS and computer role
if ($OSEmulation -eq $false)
      {
      $OS = Get-WmiObject -Class Win32_OperatingSystem
      $cs =  gwmi -Namespace "root\cimv2" -class win32_computersystem
      $DomainRole = $cs.domainrole
      switch -regex ($DomainRole) {
            [0-1]{
                  #Workstation.
                  $RoleString = "client"
                  if ($OS.BuildNumber -eq 3790)                                                 
                  	{
                 	$OperatingSystem = "Windows XP"
                 	$OSBuild = $OS.BuildNumber
                 	}
                        elseif (($OS.BuildNumber -eq 6001) -or ($OS.BuildNumber -eq 6002))
                              {
                              $OperatingSystem = "Windows Vista"
                              $OSBuild = $OS.BuildNumber
                              }
                                    elseif (($OS.BuildNumber -eq 7600) -or ($OS.BuildNumber -eq 7601))
                                                {
                                                $OperatingSystem = "Windows 7"
                                                $OSBuild = $OS.BuildNumber
                                                }
                                          elseif ($OS.BuildNumber -eq 9200)
                                                {
                                                $OperatingSystem =  "Windows 8"
                                                $OSBuild = $OS.BuildNumber
                                                }
                                                elseif ($OS.BuildNumber -eq 9600)
                                                      {
                                                      $OperatingSystem = "Windows 8.1"
                                                      $OSBuild = $OS.BuildNumber
                                                      }
												elseif ($OS.BuildNumber -eq 10586)
                                                	{
                                                	$OperatingSystem = "Windows 10"
                                                	$OSBuild = $OS.BuildNumber
                                                	}
                  }
            [2-3]{
                  #Member server.
                  $RoleString = "member server"
                  if ($OS.BuildNumber -eq 3790)
                       {
                        $OperatingSystem =  "Windows Server 2003"
                        $OSBuild = $OS.BuildNumber
                        }
                        elseif (($OS.BuildNumber -eq 6001) -or ($OS.BuildNumber -eq 6002))
                              {
                              $OperatingSystem =  "Windows Server 2008 RTM"
                              $OSBuild = $OS.BuildNumber
                              }
                              elseif (($OS.BuildNumber -eq 7600) -or ($OS.BuildNumber -eq 7601))
                                    {
                                    $OperatingSystem =  "Windows Server 2008 R2"
                                    $OSBuild = $OS.BuildNumber
                                    }
                                    elseif ($OS.BuildNumber -eq 9200)
                                          {
                                          $OperatingSystem = "Windows Server 2012"
                                          $OSBuild = $OS.BuildNumber
                                          }
                                          elseif ($OS.BuildNumber -eq 9600)
                                                {
                                                $OperatingSystem = "Windows Server 2012 R2"
                                                $OSBuild = $OS.BuildNumber
                                                }
                  }
            [4-5]{
                  #Domain Controller
                  $RoleString = "domain controller"
                  if ($OS.BuildNumber -eq 3790)
                       {
                        $OperatingSystem =  "Windows Server 2003"
                        $OSBuild = $OS.BuildNumber
                        }
                        elseif (($OS.BuildNumber -eq 6001) -or ($OS.BuildNumber -eq 6002))
                              {
                              $OperatingSystem =  "Windows Server 2008"
                              $OSBuild = $OS.BuildNumber
                              }
                              elseif (($OS.BuildNumber -eq 7600) -or ($OS.BuildNumber -eq 7601))
                                    {
                                    $OperatingSystem =  "Windows Server 2008 R2"
                                    $OSBuild = $OS.BuildNumber
                                    }
                                    elseif ($OS.BuildNumber -eq 9200)
                                          {
                                          $OperatingSystem = "Windows Server 2012"
                                          $OSBuild = $OS.BuildNumber}
                                          elseif ($OS.BuildNumber -eq 9600)
                                          {
                                          $OperatingSystem = "Windows Server 2012 R2"
                                          $OSBuild = $OS.BuildNumber
                                          }
                  }
            }
      }

if ($OSEmulation -eq $true)
      {
      #Prompt user to choose which OS since they chose to emulate.
      $PromptTitle= "Operating System"
      $Message = "Select which operating system to emulate for token sizing (size tolerance is and configuration OS dependant)."
      $12K = New-Object System.Management.Automation.Host.ChoiceDescription "Gauge Kerberos token size using the Windows 7/Windows Server 2008 R2 and earlier default token size of &12K."
      $48K = New-Object System.Management.Automation.Host.ChoiceDescription "Gauge Kerberos token size using the Windows 8/Windows Server 2012 default token size of &48K. Note: The &48K setting is optionally configurable for many earlier Windows versions."
	  $65K = New-Object System.Management.Automation.Host.ChoiceDescription "Gauge Kerberos token size using the Windows 10 and later default token size of &65K. Note: The &65K setting is optionally configurable for many earlier Windows versions."
      $OSOptions = [System.Management.Automation.Host.ChoiceDescription[]]($12K,$48K,$65K)
      $Result = $Host.UI.PromptForChoice($PromptTitle,$Message,$OSOptions,0)
      switch ($Result)
            {
            0     {
                  $OSBuild = "7600"
                  "Gauging Kerberos token size using the Windows 7/Windows Server 2008 R2 and earlier default token size of 12K." | Out-File $ExportFile -Append
                  Write-host "Gauging Kerberos token size using the Windows 7/Windows Server 2008 R2 and earlier default token size of 12K." 
                  }
            1     {
                  $OSBuild = "9200"
                  "Gauging Kerberos token size using the Windows 8/Windows Server 2012 and later default token size of 48K. Note: The 48K setting is optionally configurable for many earlier Windows versions." | Out-File $ExportFile -Append
                  Write-host "Gauging Kerberos token size using the Windows 8/Windows Server 2012 and later default token size of 48K. Note: The 48K setting is optionally configurable for many earlier Windows versions."
                  }
			2     {
                  $OSBuild = "10586"
                  "Gauging Kerberos token size using the Windows 10 default token size of 65K. Note: The 65K setting is optionally configurable for many earlier Windows versions." | Out-File $ExportFile -Append
                  Write-host "Gauging Kerberos token size using the Windows 8/Windows Server 2012 and later default token size of 65K. Note: The 65K setting is optionally configurable for many earlier Windows versions."
                  }
            }
      }
      else
            {
            Write-Host "The computer is $OperatingSystem and is a $RoleString."
            "The computer is $OperatingSystem and is a $RoleString." | Out-File $ExportFile -Append
            }

function GetSIDHistorySIDs
      {     param ([string]$objectname)
      Trap [Exception] 
      {$Script:ExceptionMessage = $_
      $Error.Clear()
     continue}
     $DomainInfo = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
      $RootString = "LDAP://" + $DomainInfo.Name
      $Root = New-Object  System.DirectoryServices.DirectoryEntry($RootString)
      $searcher = New-Object DirectoryServices.DirectorySearcher($Root)
	  $searcher.Filter="(|(userprincipalname=$objectname)(name=$objectname))"
      $results=$searcher.findone()
      if ($results -ne $null)
            {
            $SIDHistoryResults = $results.properties.sidhistory
            }
      #Clean up the SIDs so they are formatted correctly
      $SIDHistorySids = @()
      foreach ($SIDHistorySid in $SIDHistoryResults)
            {
            $SIDString = (New-Object System.Security.Principal.SecurityIdentifier($SIDHistorySid,0)).Value
            $SIDHistorySids += $SIDString
            }
      return $SIDHistorySids
}

foreach ($Principal in $Principals)
  {
  #Obtain domain SID for group SID comparisons.
  $UserIdentity = New-Object System.Security.Principal.WindowsIdentity($Principal)
  $Groups = $UserIdentity.get_Groups()
  $DomainSID = $UserIdentity.User.AccountDomainSid
  $GroupCount = $Groups.Count
  if ($Details -eq $true)
    {
    $GroupDetails = New-Object PSObject
    Write-Progress -Activity "Getting SIDHistory, and group details for review."  -Status "Detailed results requested. This may take awhile." -ErrorAction SilentlyContinue
    }
  
  $AllGroupSIDHistories = @()
  $SecurityGlobalScope  = 0
  $SecurityDomainLocalScope = 0
  $SecurityUniversalInternalScope = 0
  $SecurityUniversalExternalScope = 0
  
  foreach ($GroupSid in $Groups) 
        {     
        $Group = [adsi]"LDAP://<SID=$GroupSid>"
        $GroupType = $Group.groupType
	if ($Group.name -ne $null)
		{
	    $SIDHistorySids = GetSIDHistorySIDs $Group.name
	    If (($SIDHistorySids | Measure-Object).Count -gt 0) 
	  		{$AllGroupSIDHistories += $SIDHistorySids}
	 		 $GroupName = $Group.name.ToString()
	  
	 	#Resolve SIDHistories if possible to give more detail.
	  	if (($Details -eq $true) -and ($SIDHistorySids -ne $null))
	        {
	        $GroupSIDHistoryDetails = New-Object PSObject
	        foreach ($GroupSIDHistory in $AllGroupSIDHistories)
	              {
	              $SIDHistGroup = New-Object System.Security.Principal.SecurityIdentifier($GroupSIDHistory)
	              $SIDHistGroupName = $SIDHistGroup.Translate([System.Security.Principal.NTAccount])
	              $GroupSIDHISTString = $GroupName + "--> " + $SIDHistGroupName
	              add-Member -InputObject $GroupSIDHistoryDetails -MemberType NoteProperty -Name $GroupSIDHistory  -Value $GroupSIDHISTString -force
	              }
	        }
	  	}
	              
            #Count number of security groups in different scopes.
            switch -exact ($GroupType)
                  {"-2147483646"    {
                                    #Domain Global scope
                                    $SecurityGlobalScope++
                                    if ($Details -eq $true)
                                          {
										  #Domain Global scope
                        				  $GroupNameString = $GroupName + " (" + ($GroupSID.ToString()) + ")"
                        				  add-Member -InputObject $GroupDetails -MemberType NoteProperty -Name $GroupNameString  -Value "Domain Global Group"
                          				  $GroupNameString = $null
                                          }
                                    }
                  "-2147483644"     {
                                    #Domain Local scope
                                    $SecurityDomainLocalScope++
                                    if ($Details -eq $true)
                                          {
                        				  $GroupNameString = $GroupName + " (" + ($GroupSID.ToString()) + ")"
                        				  Add-Member -InputObject $GroupDetails -MemberType NoteProperty -Name $GroupNameString  -Value "Domain Local Group"
                       					  $GroupNameString = $null
                                          }
                                  }
                  "-2147483640"   {
                                  #Universal scope; must separate local
                                  #domain universal groups from others.
                                  if ($GroupSid -match $DomainSID)
                          		  	{
                                    $SecurityUniversalInternalScope++
                                    if ($Details -eq $true)
                                        {
                         				$GroupNameString = $GroupName + " (" + ($GroupSID.ToString()) + ")"
                        				Add-Member -InputObject $GroupDetails -MemberType NoteProperty -Name  $GroupNameString -Value "Local Universal Group"
                          				$GroupNameString = $null
                                        }
                                    }
                                    else
                                        {
                                        $SecurityUniversalExternalScope++
                                        if ($Details -eq $true)
                                           {
                           				   $GroupNameString =  $GroupName + " (" + ($GroupSID.ToString()) + ")"
                           				   Add-Member -InputObject $GroupDetails -MemberType NoteProperty -Name  $GroupNameString -Value "External Universal Group"
                        				   $GroupNameString = $null
                                           }
                                        }
                                  }
                  }

            }

      #Get user object SIDHistories
      $SIDHistoryResults = GetSIDHistorySIDs $Principal
      $SIDCounter = $SIDHistoryResults.count
      
      #Resolve SIDHistories if possible to give more detail.
      if (($Details -eq $true) -and ($SIDHistoryResults -ne $null))
            {
            $UserSIDHistoryDetails = New-Object PSObject
            foreach ($SIDHistory in $SIDHistoryResults)
                  {
                  $SIDHist = New-Object System.Security.Principal.SecurityIdentifier($SIDHistory)
                  $SIDHistName = $SIDHist.Translate([System.Security.Principal.NTAccount])
                  add-Member -InputObject $UserSIDHistoryDetails -MemberType NoteProperty -Name $SIDHistName  -Value $SIDHistory -force
                  }
            }
                        
      $GroupSidHistoryCounter = $AllGroupSIDHistories.Count 
      $AllSIDHistories = $SIDCounter  + $GroupSidHistoryCounter
 
 	  #Calculate the current token size.
      $TokenSize = 0 #Set to zero in case the script is *gasp* ran twice in the same PS.
      $TokenSize = 1200 + (40 * ($SecurityDomainLocalScope + $SecurityUniversalExternalScope + $GroupSidHistoryCounter)) + (8 * ($SecurityGlobalScope  + $SecurityUniversalInternalScope))
      $DelegatedTokenSize = 2 * (1200 + (40 * ($SecurityDomainLocalScope + $SecurityUniversalExternalScope + $GroupSidHistoryCounter)) + (8 * ($SecurityGlobalScope  + $SecurityUniversalInternalScope)))     
	  #Begin output of details regarding the user into prompt and outfile.
      "`n"  | Out-File $ExportFile -Append
      Write-Host " "
      Write-host  "Token Details for user $Principal" 
      "Token Details for user $Principal"  | Out-File $ExportFile -Append
      Write-host  "**********************************" 
      "**********************************"  | Out-File $ExportFile -Append
      $Username = $UserIdentity.name
      $PrincipalsDomain = $Username.Split('\')[0]
      Write-Host "User's domain is $PrincipalsDomain."
      "User's domain is $PrincipalsDomain." | Out-File $ExportFile -Append
      
      Write-Host "Total estimated token size is $Tokensize."
      "Total estimated token size is $Tokensize." | Out-File $ExportFile -Append

      Write-Host "For access to DCs and delegatable resources the total estimated token delegation size is $DelegatedTokenSize."
      "For access to DCs and delegatable resources the total estimated token delegation size is $DelegatedTokenSize." | Out-File $ExportFile -Append
	  
      $KerbKey = get-item -Path Registry::HKLM\SYSTEM\CurrentControlSet\Control\LSA\Kerberos\Parameters
      $MaxTokenSizeValue = $KerbKey.GetValue('MaxTokenSize')
	  if ($MaxTokenSizeValue -eq $null)
	  	{
		if ($OSBuild -lt 9200)
			{$MaxTokenSizeValue = 12000}
		if ($OSBuild -ge 9200)
			{$MaxTokenSizeValue = 48000}
		}
        Write-Host "Effective MaxTokenSize value is: $Maxtokensizevalue"
        "Effective MaxTokenSize value is: $Maxtokensizevalue" | Out-File $ExportFile -Append

      #Assess OS so we can alert based on default for proper OS version. Windows 8 and Server 2012 allow for a larger token size safely.
      $ProblemDetected = $false
      if (($OSBuild -lt 9200) -and (($Tokensize -ge 12000) -or ((($Tokensize -gt $MaxTokenSizeValue) -or ($DelegatedTokenSize -gt $MaxTokenSizeValue)) -and ($MaxTokenSizeValue -ne $null))))
            {
            Write-Host "Problem detected. The token was too large for consistent authorization. Alter the maximum size per KB http://support.microsoft.com/kb/327825 and consider reducing direct and transitive group memberships." -ForegroundColor "red"
            }
      elseif ((($OSBuild -eq 9200) -or ($OSBuild -eq 9600)) -and (($Tokensize -ge 48000) -or ((($Tokensize -gt $MaxTokenSizeValue) -or ($DelegatedTokenSize -gt $MaxTokenSizeValue)) -and ($MaxTokenSizeValue -ne $null))))
            {
            Write-Host "Problem detected. The token was too large for consistent authorization. Alter the maximum size per KB http://support.microsoft.com/kb/327825 and consider reducing direct and transitive group memberships." -ForegroundColor "red"
            }
      elseif (($OSBuild -eq 10586) -and (($Tokensize -ge 65535) -or ((($Tokensize -gt $MaxTokenSizeValue) -or ($DelegatedTokenSize -gt $MaxTokenSizeValue)) -and ($MaxTokenSizeValue -ne $null))))
            {
            Write-Host "WARNING: The token was large enough that it may have problems when being used for Kerberos delegation or for access to Active Directory domain controller services. Alter the maximum size per KB http://support.microsoft.com/kb/327825 and consider reducing direct and transitive group memberships." -ForegroundColor "yellow"
            }
	      else
                  {
                  Write-Host "Problem not detected." -backgroundcolor "green"

                  }
      
      if ($Details -eq $true)
            {
            "`n"  | Out-File $ExportFile -Append
            Write-Host " "    
            Write-Host "*Token Details for $principal*"
            "*Token Details*" | Out-File $ExportFile -Append
            Write-Host "There are $GroupCount groups in the token."
            "There are $GroupCount groups in the token." | Out-File $ExportFile -Append
            Write-host "There are $SIDCounter SIDs in the users SIDHistory."
            "There are $SIDCounter SIDs in the users SIDHistory."  | Out-File $ExportFile -Append
            Write-host "There are $GroupSidHistoryCounter SIDs in the users groups SIDHistory attributes."
            "There are $GroupSidHistoryCounter SIDs in the users groups SIDHistory attributes."  | Out-File $ExportFile -Append
            Write-host "There are $AllSIDHistories total SIDHistories for user and groups user is a member of."
            "There are $AllSIDHistories total SIDHistories for user and groups user is a member of."  | Out-File $ExportFile -Append
            Write-Host "$SecurityGlobalScope are domain global scope security groups."
            "$SecurityDomainLocalScope are domain local security groups." | Out-File $ExportFile -Append
            Write-Host "$SecurityDomainLocalScope are domain local security groups."
            "$SecurityUniversalInternalScope are universal security groups inside of the users domain." | Out-File $ExportFile -Append
            Write-Host "$SecurityUniversalInternalScope are universal security groups inside of the users domain."
            "$SecurityUniversalExternalScope are universal security groups outside of the users domain." | Out-File $ExportFile -Append
            Write-Host "$SecurityUniversalExternalScope are universal security groups outside of the users domain."

			Write-Host "Summary and all other token content details can be found in the output file at $ExportFile"
            "`n"  | Out-File $ExportFile -Append
            "Group Details" | Out-File $ExportFile  -Append 
            $GroupDetails | FL * | Out-File -FilePath $ExportFile  -width 500 -Append
            "`n"  | Out-File $ExportFile -Append
            
            "Group SIDHistory Details" | Out-File $ExportFile -Append
            if ($GroupSIDHistoryDetails -eq $null)
                  {"[NONE FOUND]" | Out-File $ExportFile -Append}
                  else
                  {$GroupSIDHistoryDetails | FL * | Out-File -FilePath $ExportFile  -width 500 -Append}
            "`n"  | Out-File $ExportFile -Append
            "User SIDHistory Details" | Out-File $ExportFile -Append
            if ($UserSIDHistoryDetails -eq $null)
                  {"[NONE FOUND]" | Out-File $ExportFile -Append}
                  else
                  {$UserSIDHistoryDetails | FL * | Out-File -FilePath $ExportFile  -width 500 -Append}
            "`n"  | Out-File $ExportFile -Append
            
            }

      }
