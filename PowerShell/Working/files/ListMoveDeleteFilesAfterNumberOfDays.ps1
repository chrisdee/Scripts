## PowerShell: Script with a Function to Move Files Older than a number of days to a Destination Folder before Deleting them from the Source Folder ##

<#
.Synopsis
   Searches for files with last write time and xdays old. Then copies them to a Destination folder prior to deleting the files from the Source folder

.Resource
    http://powershell.com/cs/media/p/47260.aspx
   
.Usage Example
   PS C:\> Archive-SomeFiles -Source C:\Source -Destination C:\Destination  -Days -151 -LogFolder C:\logs

   #>

function Archive-SomeFiles
{
	[CmdletBinding()]
	[OutputType([int])]
	Param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		$Source,
		[Parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		$Destination,
		[Parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		$LogFolder,
		[Parameter(Mandatory = $true,
				   ValueFromPipelineByPropertyName = $true,
				   Position = 0)]
		[int]$Days
		
	)
	
	
	try
	{
		$F = get-childitem -Path $Source -ErrorAction Stop -Recurse | where-object { $_.LastWriteTime -lt (get-date).AddDays($days).Date }
        $C = $F.count 
        if ($C -ge 1)
		{
            $F | Copy-Item -Destination $Destination -ErrorAction Stop -Force -Verbose
            $F | Remove-Item -ErrorAction Stop -Force -Verbose
        }
		
	}
	
	Catch
	{
		$ErrorMessage = $_.Exception.Message
		
	}
	Finally
	{
		$Time = Get-date
		$File = "$LogFolder\File_Archive_Job.log"
		if (Test-Path -Path $File)
		{
			"Time: $Time Total files: $C were counted and moved from $Source to $Destination if no error occured. Error (if any): $ErrorMessage" | out-file $File -ErrorAction SilentlyContinue -append
		}
		else
		{
			$Dir = New-Item -Path $LogFolder -ItemType Directory -Force
			$Log = New-Item -Path $Dir\Script.log -ItemTyp File -Force
			"Time: $Time Total files: $C were counted and moved from $Source to $Destination if no error occured. Error (if any): $ErrorMessage" | out-file $File -ErrorAction SilentlyContinue -append
		}
		
		
		
	}
	
	
}

Archive-SomeFiles -Source C:\ztemp\zzSource -Destination \\gf\Common\ITOperations\zzDestination -Days -10 -LogFolder \\gf\Common\ITOperations\zzDestination\logs