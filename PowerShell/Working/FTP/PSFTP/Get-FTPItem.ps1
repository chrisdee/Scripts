Function Get-FTPItem
{
    <#
	.SYNOPSIS
	    Send specific file from ftop server to location disk.

	.DESCRIPTION
	    The Get-FTPItem cmdlet download file to specific location on local machine.
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER LocalPath
	    Specifies a local path. 
		
	.PARAMETER RecreateFolders
		Recreate locally folders structure from ftp server.

	.PARAMETER BufferSize
	    Specifies size of buffer. Default is 20KB. 
		
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
	
	.EXAMPLE
		PS P:\> Get-FTPItem -Path ftp://ftp.contoso.com/folder/subfolder1/test.xlsx -LocalPath P:\test
		226 File send OK.

		PS P:\> Get-FTPItem -Path ftp://ftp.contoso.com/folder/subfolder1/test.xlsx -LocalPath P:\test

		A File name already exists in location: P:\test
		What do you want to do?
		[C] Cancel  [O] Overwrite  [?] Help (default is "O"): O
		226 File send OK.

	.EXAMPLE	
		PS P:\> Get-FTPChildItem -path folder/subfolder1 -Recurse | Get-FTPItem -localpath p:\test -RecreateFolders -Verbose
		VERBOSE: Performing operation "Download item: 'ftp://ftp.contoso.com/folder/subfolder1/test.xlsx'" on Target "p:\test\folder\subfolder1".
		VERBOSE: Creating folder: folder\subfolder1
		226 File send OK.

		VERBOSE: Performing operation "Download item: 'ftp://ftp.contoso.com/folder/subfolder1/ziped.zip'" on Target "p:\test\folder\subfolder1".
		226 File send OK.

		VERBOSE: Performing operation "Download item: 'ftp://ftp.contoso.com/folder/subfolder1/subfolder11/ziped.zip'" on Target "p:\test\folder\subfolder1\subfolder11".
		VERBOSE: Creating folder: folder\subfolder1\subfolder11
		226 File send OK.

	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/

	.LINK
        Get-FTPChildItem
	#>    

	[CmdletBinding(
    	SupportsShouldProcess=$True,
        ConfirmImpact="Low"
    )]
    Param(
		[parameter(Mandatory=$true,
			ValueFromPipelineByPropertyName=$true,
			ValueFromPipeline=$true)]
		[Alias("FullName")]
		[String]$Path = "",
		[String]$LocalPath = (Get-Location).Path,
		[Switch]$RecreateFolders,
		[Int]$BufferSize = 20KB,
		[String]$Session = "DefaultFTPSession"
	)
	
	Begin{}
	
	Process
	{
		$CurrentSession = Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue -ValueOnly
		if($Path -match "ftp://")
		{
			$RequestUri = $Path
		}
		else
		{
			$RequestUri = $CurrentSession.RequestUri.OriginalString+"/"+$Path
		}
		$RequestUri = [regex]::Replace($RequestUri, '/+', '/')
		$RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')

		$TotalData = Get-FTPItemSize $RequestUri -Silent
		if($TotalData -eq -1) { Return }
		if($TotalData -eq 0) { $TotalData = 1 }

		$AbsolutePath = ($RequestUri -split $CurrentSession.ServicePoint.Address.AbsoluteUri)[1]
		$LastIndex = $AbsolutePath.LastIndexOf("/")
		$ServerPath = $CurrentSession.ServicePoint.Address.AbsoluteUri
		if($LastIndex -eq -1)
		{
			$FolderPath = "\"
		}
		else
		{
			$FolderPath = $AbsolutePath.SubString(0,$LastIndex) -replace "/","\"
		}	
		$FileName = $AbsolutePath.SubString($LastIndex+1)
					
		if($RecreateFolders)
		{
			if(!(Test-Path (Join-Path -Path $LocalPath -ChildPath $FolderPath)))
			{
				Write-Verbose "Creating folder: $FolderPath"
				New-Item -Type Directory -Path $LocalPath -Name $FolderPath | Out-Null
			}
			$LocalDir = Join-Path -Path $LocalPath -ChildPath $FolderPath
		}
		else
		{
			$LocalDir = $LocalPath
		}
					
		if ($pscmdlet.ShouldProcess($LocalDir,"Download item: '$RequestUri'")) 
		{	
			if($CurrentSession -ne $null)
			{
				[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
				$Request.Credentials = $CurrentSession.Credentials
				$Request.EnableSsl = $CurrentSession.EnableSsl
				$Request.KeepAlive = $CurrentSession.KeepAlive
				$Request.UseBinary = $CurrentSession.UseBinary
				$Request.UsePassive = $CurrentSession.UsePassive

				$Request.Method = [System.Net.WebRequestMethods+FTP]::DownloadFile  
				Try
				{
					[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
					$SendFlag = 1
					
					if((Get-ItemProperty $LocalDir -ErrorAction SilentlyContinue).Attributes -match "Directory")
					{
						$LocalDir = Join-Path -Path $LocalDir -ChildPath $FileName
					}
					
					if(Test-Path ($LocalDir))
					{
						$FileSize = (Get-Item $LocalDir).Length
						
						$Title = "A file ($RequestUri) already exists in location: $LocalDir"
						$Message = "What do you want to do?"

						$Overwrite = New-Object System.Management.Automation.Host.ChoiceDescription "&Overwrite"
						$Cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel"
						if($FileSize -lt $TotalData)
						{
							$Resume = New-Object System.Management.Automation.Host.ChoiceDescription "&Resume"
							$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Cancel, $Overwrite, $Resume)
							$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 2) 
						}
						else
						{
							$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Cancel, $Overwrite)
							$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 1)
						}
					}

					if($SendFlag)
					{
						[Byte[]]$Buffer = New-Object Byte[] $BufferSize

						$ReadedData = 0
						$AllReadedData = 0
						
						if($SendFlag -eq 2)
						{      
							$File = New-Object IO.FileStream ($LocalDir,[IO.FileMode]::Append)
							$Request.UseBinary = $True
							$Request.ContentOffset  = $FileSize 
							$AllReadedData = $FileSize
						}
						else
						{
							$File = New-Object IO.FileStream ($LocalDir,[IO.FileMode]::Create)
						}
						
						$Response = $Request.GetResponse()
						$Stream  = $Response.GetResponseStream()
						
						Do{
							$ReadedData=$Stream.Read($Buffer,0,$Buffer.Length)
							$AllReadedData +=$ReadedData
							$File.Write($Buffer,0,$ReadedData)
							Write-Progress -Activity "Download File: $Path" -Status "Downloading:" -Percentcomplete ([int]($AllReadedData/$TotalData * 100))
						}
						While ($ReadedData -ne 0)
						$File.Close()

						$Status = $Response.StatusDescription
						$Response.Close()
						Return $Status
					}
				}
				Catch
				{
					$Error = $_#.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
					Write-Error $Error -ErrorAction Stop 
				}
			}
			else
			{
				Write-Warning "First use Set-FTPConnection to config FTP connection."
			}
		}
	}
	
	End{}
}