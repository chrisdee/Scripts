## PowerShell: Useful function to Search a File Path Location for Phrase Key Words ##

## Overview: PowerShell function that parses through a file path location to locate any files that match a search phrase. The results output to the Grid View window

## Usage: Run the function with the '-SearchPhrase' and '-Path' parameters (optional - otherwise the location set under '$Path' is used)

## Resource: http://www.asifsaif.com/2015/08/quickly-finding-scripts.html

#requires -Version 3
function Find-Script
{
  param
  (
    [Parameter(Mandatory = $true)]
    $SearchPhrase,
    $Path = [Environment]::GetFolderPath('MyDocuments')
  )

  Get-ChildItem -Path $Path  -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue |
  Select-String -Pattern $SearchPhrase -List |
  Select-Object -Property Path, Line |
  Out-GridView -Title "All Scripts containing $SearchPhrase" -PassThru |
  ForEach-Object -Process {
    ise $_.Path
  }
}

#Example
#Find-Script -SearchPhrase "Content Type Hub" -Path "C:\BoxBuild\GitHub\Scripts\PowerShell\Working"