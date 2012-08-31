Function Remove-FTPItem
{
    <#
	.SYNOPSIS
	    Remove specific item from ftp server.

	.DESCRIPTION
	    The Remove-FTPItem cmdlet remove item from specific location on ftp server.
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER Recurse
	    Remove items recursively.		
			
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'. 
	
	.EXAMPLE
		PS> Remove-FTPItem -Path "/myFolder" -Recurse
		->Remove Dir: /myFolder/mySubFolder
		250 Remove directory operation successful.

		->Remove Dir: /myFolder
		250 Remove directory operation successful.

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
		[parameter(Mandatory=$true)]
		[String]$Path = "",
		[Switch]$Recurse = $False,
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
		
		if ($pscmdlet.ShouldProcess($RequestUri,"Remove item from ftp location")) 
		{	
			if($CurrentSession -ne $null)
			{
				[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
				$Request.Credentials = $CurrentSession.Credentials
				$Request.EnableSsl = $CurrentSession.EnableSsl
				$Request.KeepAlive = $CurrentSession.KeepAlive
				$Request.UseBinary = $CurrentSession.UseBinary
				$Request.UsePassive = $CurrentSession.UsePassive
				
				if((Get-FTPItemSize -Path $RequestUri -Silent) -ge 0)
				{
					$Request.Method = [System.Net.WebRequestMethods+FTP]::DeleteFile
					"->Remove File: $RequestUri"
				}
				else
				{
					$Request.Method = [System.Net.WebRequestMethods+FTP]::RemoveDirectory
					
					$SubItems = Get-FTPChildItem -Path $RequestUri
					if($SubItems)
					{
						$RemoveFlag = 0
						if(!$Recurse)
						{
							$Title = "Remove recurse"
							$Message = "Do you want to recurse remove items from location?"

							$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes"
							$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No"
							$Options = [System.Management.Automation.Host.ChoiceDescription[]]($No, $Yes)

							$RemoveFlag = $host.ui.PromptForChoice($Title, $Message, $Options, 0) 
						}
						else
						{
							$RemoveFlag = 1
						}
						
						if($RemoveFlag)
						{
							Foreach($SubItem in $SubItems)
							{
								Remove-FTPItem -Path ($RequestUri+"/"+$SubItem.Name.Trim()) -Recurse
							}
						}
						else
						{
							Return
						}
					}
					"->Remove Dir: $RequestUri"
				}
				
				Try
				{
					[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
					$Response = $Request.GetResponse()

					$Status = $Response.StatusDescription
					$Response.Close()
					Return $Status
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
	
	End{}				
}