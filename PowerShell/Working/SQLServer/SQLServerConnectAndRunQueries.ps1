## PowerShell Script that queries SQL server and outputs the results to be imported for other commands ##
## PowerShell Script creates a function to connect to and query a SQL Server ##

function ConnectSQL {
    Param ($server, $query, $database)
    $conn = new-object ('System.Data.SqlClient.SqlConnection')
    $connString = "Server=$server;Integrated Security=SSPI;Database=$database"
    $conn.ConnectionString = $connString
    $conn.Open()
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.CommandText = $query
    $sqlCmd.Connection = $conn
    $Rset = $sqlCmd.ExecuteReader()
    ,$Rset ## The comma is used to create an outer array, which PS strips off automatically when returning the $Rset
}

function QuerySQL {
    Param ($server, $query, $database = "master") ## Change your database here
    $data = ConnectSQL $server $query $database
    while ($data.read() -eq $true) {
        $max = $data.FieldCount -1
        $obj = New-Object Object
        For ($i = 0; $i -le $max; $i++) {
            $name = $data.GetName($i)
            $obj | Add-Member Noteproperty $name -value $data.GetValue($i)
     }
     $obj
    }
}

## Example: Connects to a SQL Instance and outputs results to a text file to be imported to make directories from these

# Set your PowerShell Variables here

$FolderLocation = "C:\temp"
$SQLInstance = "D05479"
$QueryResults = "QueryResults.txt"

$Query1 = QuerySQL $SQLInstance "USE WebDeploy SELECT MachineName FROM ApplicationDetails Where Environment ='SAT'" | Out-File "$FolderLocation\$QueryResults"

$FolderName = Get-Content "$FolderLocation\$QueryResults" | Select-String 'SAT'

ForEach ($folder in $FolderName)
{
New-Item -Path $FolderLocation -Name $folder -ItemType directory
}