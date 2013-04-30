########################################################### 
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl  
# DATE    : 05-07-2012  
# COMMENT : Scan for *.txt files recursively in the root
#           directory of the script. Compare the contents
#           of these files to an array of strings, which
#           are listed in the control file. Output the
#           successful results to the output file.
###########################################################

#ERROR REPORTING ALL
Set-StrictMode -Version latest

$path     = Split-Path -parent $MyInvocation.MyCommand.Definition
$files    = Get-Childitem $path *.txt -Recurse | Where-Object { !($_.psiscontainer) } #Change the file format in the $path variable if needed
$controls = Get-Content ($path + "\control_file.txt") #Change this to suit your environment
$output   = $path + "\output.log" #Change this to suit your environment

Function getStringMatch
{
  # Loop through all *.txt files in the $path directory
  Foreach ($file In $files)
  {
    # Loop through the search strings in the control file
    ForEach ($control In $controls)
    {
      $result = Get-Content $file.FullName | Select-String $control -quiet -casesensitive
      If ($result -eq $True)
      {
        $match = $file.FullName
        "Match on string :  $control  in file :  $match" | Out-File $output -Append
      }
    }
  }
}

getStringMatch