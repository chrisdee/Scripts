## PowerShell: Script to connect to SQL Server and run a Query with Different Outputs ##
## Source: http://mspowershell.blogspot.com/2009/02/t-sql-query-with-object-based-result.html ##

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

QuerySQL "YourDatabaseServer" "SELECT * FROM sysdatabases"

## Or To format the output into a Table View ##

#$data = QuerySQL "YourDatabaseServer" "SELECT * FROM sysdatabases"
#$data | Format-Table -AutoSize

## Or to use the PowerShell 2.0+ Grid View functionality ##

#QuerySQL "sp2010dev" "SELECT * FROM sysdatabases" | out-gridview