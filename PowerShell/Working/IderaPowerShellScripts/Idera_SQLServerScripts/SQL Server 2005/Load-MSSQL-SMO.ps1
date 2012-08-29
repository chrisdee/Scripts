# Load-MSSQL-SMO.ps1
#

[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.ConnectionInfo" );
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SqlEnum" );
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.SmoEnum" );
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );