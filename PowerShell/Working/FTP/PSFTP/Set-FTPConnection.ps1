Function Set-FTPConnection
{
    <#
	.SYNOPSIS
	    Set config to ftp Connection.

	.DESCRIPTION
	    The Set-FTPConnection cmdlet creates a Windows PowerShell configuration to ftp server. When you create a ftp connection, you may run multiple commands that use this config.
		
	.PARAMETER Credentials
	    Specifies a user account that has permission to access to ftp location.
			
	.PARAMETER Server
	    Specifies the ftp server you want to connect. 
			
	.PARAMETER EnableSsl
	    Specifies that an SSL connection should be used. 
			
	.PARAMETER ignoreCert
	    If you use SSL connection you may ignore certificate error. 
			
	.PARAMETER KeepAlive
	    Specifies whether the control connection to the ftp server is closed after the request completes.  
			
	.PARAMETER UseBinary
	    Specifies the data type for file transfers.  
			
	.PARAMETER UsePassive
	    Behavior of a client application's data transfer process. 

	.PARAMETER Session
	    Specifies a friendly name for the ftp session. Default session name is 'DefaultFTPSession'.
	
	.EXAMPLE

		$Credentials = Get-Credential
		Set-FTPConnection -Credentials $Credentials -Server ftp://myftpserver.com -EnableSsl -ignoreCert -UsePassive
        
        ContentLength           : -1
		Headers                 : {}
		ResponseUri             : ftp://myftpserver.com/
		StatusCode              : ClosingData
		StatusDescription       : 226 Directory send OK.

		LastModified            : 0001-01-01 00:00:00
		BannerMessage           : 220 Welcome to FTP service.

		WelcomeMessage          : 230 Login successful.

		ExitMessage             : 221 Goodbye.

		IsFromCache             : False
		IsMutuallyAuthenticated : False
		ContentType             :

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
		[System.Net.NetworkCredential]$Credentials,
		[parameter(Mandatory=$true)]
		[String]$Server,
		[Switch]$EnableSsl = $False,
		[Switch]$ignoreCert = $False,
		[Switch]$KeepAlive = $False,
		[Switch]$UseBinary = $False,
		[Switch]$UsePassive = $False,
		[String]$Session = "DefaultFTPSession"
	)
	
	Begin{}
	
	Process
	{
        if ($pscmdlet.ShouldProcess($Server,"Connect to FTP Server")) 
		{	
			if(!($Server -match "ftp://"))
			{
				$Server = "ftp://"+$Server	
			}
			
			[System.Net.FtpWebRequest]$Request = [System.Net.WebRequest]::Create($Server)
			$Request.Credentials = $Credentials
			$Request.EnableSsl = $EnableSsl
			$Request.KeepAlive = $KeepAlive
			$Request.UseBinary = $UseBinary
			$Request.UsePassive = $UsePassive
			$Request | Add-Member -MemberType NoteProperty -Name ignoreCert -Value $ignoreCert

			$Request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectoryDetails
			Try
			{
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$ignoreCert}
				$Response = $Request.GetResponse()
				$Response.Close()
				
				if((Get-Variable -Scope Global -Name $Session -ErrorAction SilentlyContinue) -eq $null)
				{
					New-Variable -Scope Global -Name $Session -Value $Request
				}
				else
				{
					Set-Variable -Scope Global -Name $Session -Value $Request
				}
				
				Return $Response
			}
			Catch
			{
				$Error = $_.Exception.Message.Substring(($_.Exception.Message.IndexOf(":")+3),($_.Exception.Message.Length-($_.Exception.Message.IndexOf(":")+5)))
				Write-Error $Error -ErrorAction Stop 
			}
		}
	}
	
	End{}				
}