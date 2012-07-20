## PowerShell: Function To Run a SQL Query From A Text File And Output The Results To HTML ##

function SQLQueryHTMLOutput 
{
  $sqlConnection = new-object System.Data.SqlClient.SqlConnection "server=YourInstance;database=msdb;Integrated Security=sspi" #Change the SQL Instance to suit your environment
  $sqlConnection.Open()
  $sqlCommand = New-object system.data.sqlclient.SqlCommand   
  $sqlCommand.CommandTimeout = 30 
  $sqlCommand.Connection = $sqlConnection
  $sqlCommand.CommandText = get-content "C:\Scripts\PowerShell\SQL_Query.txt" # Change your path and file name details here 
  $sqlDataAdapter = new-object System.Data.SqlClient.SQLDataAdapter($sqlCommand) 
  $sqlDataSet = new-object System.Data.dataset 
  $sqlDataAdapter.fill($sqlDataSet)
  $sqlDataSet.tables[0].select()
}

#Example:
SQLQueryHTMLOutput | ConvertTo-HTML -title "Your Title here" -head "<style type='text/css'> body {font-family: sans-serif; font-size: 10pt;} td {vertical-align: top; color: blue;} </style>" | Out-File "C:\Scripts\PowerShell\QueryReport.html" # Change your path and file name details here
