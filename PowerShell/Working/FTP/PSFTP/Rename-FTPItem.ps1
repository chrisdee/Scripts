Function Rename-FTPItem
{
    <#
	.SYNOPSIS
	    Renames an item in ftp session.

	.DESCRIPTION
	    The Rename-FTPItem cmdlet changes the name of a specified item. This cmdlet does not affect the content of the item being renamed.
		
	.PARAMETER Path
	    Specifies a path to ftp item. 
		
	.PARAMETER NewName
		Specifies a new name of ftp item.
		
	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
	
	.EXAMPLE
        PS> Rename-FTPItem -Path "/myfolder" -NewName "myNewFolder"
		250 Rename successful.

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
		[String]$NewName,
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

		if ($pscmdlet.ShouldProcess($RequestUri,"Rename item to: '$NewName' in ftp location")) 
		{	
			if($CurrentSession -ne $null)
			{
				[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($RequestUri)
				$Request.Credentials = $CurrentSession.Credentials
				$Request.EnableSsl = $CurrentSession.EnableSsl
				$Request.KeepAlive = $CurrentSession.KeepAlive
				$Request.UseBinary = $CurrentSession.UseBinary
				$Request.UsePassive = $CurrentSession.UsePassive
				$Request.RenameTo = $NewName

				$Request.Method = [System.Net.WebRequestMethods+FTP]::Rename
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