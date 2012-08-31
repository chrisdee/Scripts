Function Add-FTPItem
{
    <#
	.SYNOPSIS
	    Send file to specific ftp location.

	.DESCRIPTION
	    The Add-FTPItem cmdlet send file to specific location on ftp server.
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER LocalPath
	    Specifies a local path. 

	.PARAMETER BufferSize
	    Specifies size of buffer. Default is 20KB. 		
			
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
		
	.PARAMETER Overwrite
	    Overwrite item on remote location. 		
	
	.EXAMPLE
		PS> Add-FTPItem -Path "/myfolder" -LocalPath "C:\myFile.txt"

		Dir          : -
		Right        : rw-r--r--
		Ln           : 1
		User         : ftp
		Group        : ftp
		Size         : 82033
		ModifiedDate : Aug 17 12:27
		Name         : myFile.txt

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
		[String]$Path = "",
		[parameter(Mandatory=$true)]
		[String]$LocalPath,
		[Int]$BufferSize = 20KB,
		[String]$Session = "DefaultFTPSession",
		[Switch]$Overwrite = $false
	)
	
	Begin{}
	
	Process
	{
        $CurrentSession = Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue -ValueOnly
		
		if(Test-Path $LocalPath)
		{
			if($Path -match "ftp://")
			{
				$RequestUri = $Path+"/"+(Get-Item $LocalPath).Name
			}
			else
			{
				$RequestUri = $CurrentSession.RequestUri.OriginalString+"/"+$Path+"/"+(Get-Item $LocalPath).Name
			}
			$RequestUri = [regex]::Replace($RequestUri, '/+', '/')
			$RequestUri = [regex]::Replace($RequestUri, '^ftp:/', 'ftp://')
			
			if ($pscmdlet.ShouldProcess($RequestUri,"Send item: '$LocalPath' in ftp location")) 
			{	
				if($CurrentSession -ne $null)
				{
					[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
					$Request.Credentials = $CurrentSession.Credentials
					$Request.EnableSsl = $CurrentSession.EnableSsl
					$Request.KeepAlive = $CurrentSession.KeepAlive
					$Request.UseBinary = $CurrentSession.UseBinary
					$Request.UsePassive = $CurrentSession.UsePassive

					Try
					{
						[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
						
						$SendFlag = 1
						if($Overwrite -eq $false)
						{
							if((Get-FTPChildItem -Path $RequestUri).Name)
							{
								$FileSize = Get-FTPItemSize -Path $RequestUri -Silent
								
								$Title = "A File name already exists in this location."
								$Message = "What do you want to do?"

								$ChoiceOverwrite = New-Object System.Management.Automation.Host.ChoiceDescription "&Overwrite"
								$ChoiceCancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel"
								if($FileSize -lt (Get-Item -Path $LocalPath).Length)
								{
									$ChoiceResume = New-Object System.Management.Automation.Host.ChoiceDescription "&Resume"
									$Options = [System.Management.Automation.Host.ChoiceDescription[]]($ChoiceCancel, $ChoiceOverwrite, $ChoiceResume)
									$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 2) 
								}
								else
								{
									$Options = [System.Management.Automation.Host.ChoiceDescription[]]($ChoiceCancel, $ChoiceOverwrite)		
									$SendFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 1) 
								}	
							}
						}
						
						if($SendFlag -eq 2)
						{
							$Request.Method = [System.Net.WebRequestMethods+FTP]::AppendFile
						}
						else
						{
							$Request.Method = [System.Net.WebRequestMethods+FTP]::UploadFile
						}
						
						if($SendFlag)
						{
							$File = [IO.File]::OpenRead( (Convert-Path $LocalPath) )
							
		           			$Response = $Request.GetRequestStream()
	            			[Byte[]]$Buffer = New-Object Byte[] $BufferSize
							
							$ReadedData = 0
							$AllReadedData = 0
							$TotalData = (Get-Item $LocalPath).Length
							
							if($SendFlag -eq 2)
							{
								$SeekOrigin = [System.IO.SeekOrigin]::Begin
								$File.Seek($FileSize,$SeekOrigin) | Out-Null
								$AllReadedData = $FileSize
							}
							
							if($TotalData -eq 0)
							{
								$TotalData = 1
							}
							
						    Do {
	               				$ReadedData = $File.Read($Buffer, 0, $Buffer.Length)
	               				$AllReadedData += $ReadedData
	               				$Response.Write($Buffer, 0, $ReadedData);
	               				Write-Progress -Activity "Upload File: $Path" -Status "Uploading:" -Percentcomplete ([int]($AllReadedData/$TotalData * 100))
	            			} While($ReadedData -gt 0)
				
				            $File.Close()
	            			$Response.Close()
							
							Return Get-FTPChildItem -Path $RequestUri
						}
						
					}
					Catch
					{
						$Error = $_.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
						Write-Error $Error -ErrorAction Stop
					}
				}
				else
				{
					Write-Warning "First use Set-FTPConnection to config FTP connection."
				}
			}
		}
		else
		{
			Write-Error "Cannot find local path '$LocalPath' because it does not exist." -ErrorAction Stop 
		}
	}
	
	End{}				
}