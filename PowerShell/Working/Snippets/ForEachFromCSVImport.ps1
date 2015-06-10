## PowerShell: Script showing how to use a 'ForEach' loop for importing data from a CSV File ##

$InputFilePath = "C:\BoxBuild\Scripts\SPSitesReport.csv" #Change this to match your environment

$CsvFile = Import-Csv $InputFilePath

ForEach ($line in $CsvFile)

{ 

#Add your command syntax here like the example below

Write-Host $line.URL #In this example we display / write the value for a column called 'URL' in the CSV input file 

}