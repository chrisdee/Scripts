Function Get-FTPItemSize
{
    <#
	.SYNOPSIS
	    Gets the item size.

	.DESCRIPTION
	    The Get-FTPItemSize cmdlet gets the specific item size. 
		
	.PARAMETER Path
	    Specifies a path to ftp location. 

	.PARAMETER Silent
	    Hide warnings. 
		
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'. 
	
	.EXAMPLE
        PS> Get-FTPItemSize -Path "/myFolder/myFile.txt"
		82033

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
		[Switch]$Silent = $False,
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
		
		if ($pscmdlet.ShouldProcess($RequestUri,"Get item size")) 
		{	
			if($CurrentSession -ne $null)
			{
				[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
				$Request.Credentials = $CurrentSession.Credentials
				$Request.EnableSsl = $CurrentSession.EnableSsl
				$Request.KeepAlive = $CurrentSession.KeepAlive
				$Request.UseBinary = $CurrentSession.UseBinary
				$Request.UsePassive = $CurrentSession.UsePassive
				
				$Request.Method = [System.Net.WebRequestMethods+FTP]::GetFileSize 
				Try
				{
					[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$CurrentSession.ignoreCert}
					$Response = $Request.GetResponse()

					$Status = $Response.ContentLength
					$Response.Close()
					Return $Status
				}
				Catch
				{
					if(!$Silent)
					{
						$Error = $_.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
						Write-Error $Error -ErrorAction Stop 
					}	
					Return -1
				}
			}
			else
			{
				if(!$Silent)
				{
					Write-Warning "First use Set-FTPConnection to config FTP connection."
				}	
			}
		}
	}
	
	End{}				
}