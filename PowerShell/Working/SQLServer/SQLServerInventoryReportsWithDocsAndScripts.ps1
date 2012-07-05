################################################################################################################################
#
# Script Name : SQLServerInventoryReportsWithDocsAndScripts
# Version     : 1.0
# Author      : Shankar Krishnamoorthy
# Script Base : Base Code from http://gallery.technet.microsoft.com/scriptcenter/4187af0d-e82d-4615-b35d-a77aebcc7084/
# Base Author : reese12
# Purpose     :
#             This script generates HTML documentation or Scripts for all the accessible DBs in a SQL instance. The script          
#             takes two arguments in the form of a filename with full path info and usage-type which can be either of 
#             Scripts or Docs.The file identified by the first argument(filename) can contain a list of all SQL instances  
#             for which the documentation/script generation is sought. 
# Restriction : 
#             The script can be run with either windows or SQL authentication but not both simultaneously. In addition,
#             all servers for which documentation is sought and provided in the file, must be accessible from this 
#             windows or SQL authentication.
# Usage       : 
#	          .\SQLServerInventoryReportsWithDocsAndScripts.ps1 C:\ServerList.txt Scripts   (or)
#	          .\SQLServerInventoryReportsWithDocsAndScripts.ps1 C:\ServerList.txt Docs
# Note        :
#             In case of a windows authentication - please comment the following line numbers: 
#             SQL UserName and Password: 952,953
#             Server Connection        : 958-965
#             
#             Uncomment the following line numbers:
#             SQL Server                : 968
#
#             In case of SQL authentication - please do the reverse of the above. 
#
#             The documentation by default creates the output in the database_documentation folder underneath 
#             the profile's home directory. In case you want to change it, please make the change in the line number: 951
#                 
################################################################################################################################

#Note Starting Time
$startTime = Get-Date;
Write-Host "Starting script execution at : $startTime";

# Load needed assemblies 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null; 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMOExtended")| Out-Null; 
[System.Reflection.Assembly]::LoadWithPartialName("System.Data") | out-null

$colstylval = "<style> ";
$colstylval += " TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}" ;
$colstylval += " TH{background:#3b3131;color:snow;font-size:15px;border-width: 1px;padding: 10px;border-style: solid;border-color: black;}" ;
$colstylval += " TD{background:#736F6E;color:snow;font-size:13px;border-width: 1px;padding: 10px;border-style: solid;border-color: black;word-break:break-all}" ;
$colstylval += " </style>";	 

# Calculate script execution time and end scipt
function endExecution
{
	# Note End Time
	$endTime = Get-Date;
	Write-Host "Completed script execution at : $endTime";
	write-host -BackgroundColor Green -ForegroundColor Black "Script execution completed in "($endTime-$startTime).TotalSeconds " seconds.";
	exit;
}


# Simple to function to write html pages 
function writeHtmlPage 
{ 
    param ($title, $heading, $body, $filePath); 
    $html = "<html> 
             <head> 
                 <title>$title</title> 
             </head> 
             <body style='background-color:snow;font-family:courier new;color:black;font-size:15px;'> 
                 <h1>$heading</h1> 
                $body 
             </body> 
             </html>";
    $html | Out-File -FilePath $filePath; 
} 
 
# Return all user databases on a sql server 
function getDatabases 
{ 
    param ($sql_server); 
    $databases = $sql_server.Databases | Where-Object {$_.IsSystemObject -eq $false} | Where-Object {$_.IsDatabaseSnapshot -eq $false} | Where-Object {$_.IsAccessible -eq $true}; 
    return $databases; 
} 
 
# Get all schemata in a database 
function getDatabaseSchemata 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $schemata = $sql_server.Databases[$db_name].Schemas; 
    return $schemata; 
} 
 
# Get all tables in a database 
function getDatabaseTables 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $tables = $sql_server.Databases[$db_name].Tables | Where-Object {$_.IsSystemObject -eq $false}; 
    return $tables; 
} 
 
# Get all stored procedures in a database 
function getDatabaseStoredProcedures 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $procs = $sql_server.Databases[$db_name].StoredProcedures | Where-Object {$_.IsSystemObject -eq $false}; 
    return $procs; 
} 
 
# Get all user defined functions in a database 
function getDatabaseFunctions 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $functions = $sql_server.Databases[$db_name].UserDefinedFunctions | Where-Object {$_.IsSystemObject -eq $false}; 
    return $functions; 
} 
 
# Get all views in a database 
function getDatabaseViews 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $views = $sql_server.Databases[$db_name].Views | Where-Object {$_.IsSystemObject -eq $false}; 
    return $views; 
} 
 
# Get all table triggers in a database 
function getDatabaseTriggers 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $tables = $sql_server.Databases[$db_name].Tables | Where-Object {$_.IsSystemObject -eq $false}; 
    $triggers = $null; 
    foreach($table in $tables) 
    { 
        $triggers += $table.Triggers; 
    } 
    return $triggers; 
}

#
function getUDDTS 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $uddts = $sql_server.Databases[$db_name].UserDefinedDataTypes; 
    return $uddts; 
}


# Get all partition functions in a database 
function getDatabasePartitions 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $partitionfunctions = $sql_server.Databases[$db_name].PartitionFunctions;
    return $partitionfunctions; 
} 

# Get all users having access to database 
function getDBUsers 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    return $sql_server.Databases[$db_name].Users;
}

# Get all partition schemes in a database 
function getDatabasePartitionSchemes 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $partitionschemes = $sql_server.Databases[$db_name].PartitionSchemes; 
    return $partitionschemes; 
} 

# Get information for the database 
function getDatabaseInfo
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $page = $filePath + $($db.Name) + "\DBInfo.html";
    $description = getDescriptionExtendedProperty($database); 
    $body = "<h2 style='font-size:15px;text-decoration:underline'>DESCRIPTION</h2>$description"; 
    $title = $db_name; 
    $db_details = "Collation: "+$database.Collation+
			"<br><br>Compatibility Level: "+$database.CompatibilityLevel+
			"<br><br>FileGroups: "+$database.FileGroups+
			"<br><br>Default FileGroup: "+$database.DefaultFileGroup+
			"<br><br>Owner: "+$database.Owner+
			"<br><br>Recovery Model: "+$database.RecoveryModel+
			"<br><br>Properties: <br><br>"; 
    foreach($property in $database.Properties) 
    { 
        $db_details += "Property Name/Value: "+$property.Name+" / "+$property.Value+"<br>"; 
    } 
    $body += "<h2 style='font-size:15px;text-decoration:underline'>DETAILS</h2><p style='line-spacing:120%'>$db_details</p>"; 
    writeHtmlPage $title $title $body $page; 
} 


# Get information for the server 
function getServerInfo
{
	param($sql_server);
	$page = $filePath +"\SrvInfo.html";
	$title = $srv_path+" - Info"; 
	$srv_dtl = 
		"<br>"+
		"Product: "+$sql_server.Information.Product+
		"<br><br>Edition: "+$sql_server.Information.Edition+
		"<br><br>Platform: "+$sql_server.Platform+
		"<br><br>Version: "+$sql_server.Information.Version+
		"<br><br>ServiceAccount: "+$sql_server.ServiceAccount+
		"<br><br>OSVersion: "+$sql_server.Information.OSVersion+
		"<br><br>Processors: "+$sql_server.Information.Processors+
		"<br><br>PhysicalMemory: "+$sql_server.Information.PhysicalMemory+
		"<br><br>Collation: "+$sql_server.Information.Collation+
		"<br><br>LoginMode: "+$sql_server.Settings.LoginMode+
		"<br><br>AuditLevel: "+$sql_server.Settings.AuditLevel;
	$body = "<p style='line-spacing:120%'>$srv_dtl</p>";	
	writeHtmlPage $title $title $body $page;
}

 
function getObjectDependency
{
	param ($item, $db);

	$colstyl = $colstylval;

	$objs = @();

	if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.UserDefinedDataType") 
	{ 
	      $udt_name = $item.Name;	
	      $d_qry =
			"SELECT 
				O.NAME AS 'OBJECT_NAME', 
				O.TYPE_DESC AS 'OBJECT_TYPE',
				C.NAME AS 'COLUMN' 
			FROM 
				SYS.COLUMNS C
			JOIN 
				SYS.OBJECTS O 
			ON O.OBJECT_ID = C.OBJECT_ID
			JOIN 
				SYS.TYPES T 
			ON T.USER_TYPE_ID = C.USER_TYPE_ID
			WHERE 
				T.NAME = '$udt_name'";

		$ds = $db.ExecuteWithResults($d_qry).tables[0];

		Foreach ($r in $ds.Rows)
		{
			$obj = New-Object -TypeName Object; 
			Add-Member -Name "Dependent_Object_Name" -MemberType NoteProperty -Value  $r[0].ToString() -InputObject $obj; 
			Add-Member -Name "Dependent_Object_Type" -MemberType NoteProperty -Value $r[1].ToString() -InputObject $obj; 
			Add-Member -Name "Dependent_Object_ColumnName" -MemberType NoteProperty -Value $r[2].ToString() -InputObject $obj; 
			$objs = $objs + $obj; 
		}

		if ($ds -ne $null)
		{
			$output = $objs | convertTo-Html -Head $colstyl -Property Dependent_Object_Name,  Dependent_Object_Type, Dependent_Object_ColumnName;	
		}
		
	} 
	elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.PartitionScheme") 
	{
	      $ps_name = $item.Name;	
	      $d_qry =
			"SELECT 
				SO.[NAME] AS OBJ_NAME, 
				SO.[TYPE_DESC] AS OBJ_DESC, 
				ISNULL(SI.[NAME],'HEAP') AS INDEX_NAME, 
				SI.[INDEX_ID]
			FROM 
				SYS.INDEXES SI
			INNER JOIN 
				SYS.PARTITION_SCHEMES PS
			ON SI.DATA_SPACE_ID = PS.DATA_SPACE_ID
			INNER JOIN 
				SYS.ALL_OBJECTS SO
			ON SI.[OBJECT_ID] = SO.[OBJECT_ID]
			WHERE 
				PS.NAME='$ps_name'
			ORDER BY 1";

		$ds = $db.ExecuteWithResults($d_qry).tables[0];

		Foreach ($r in $ds.Rows)
		{
			$obj = New-Object -TypeName Object; 
			Add-Member -Name "Dependent_Object_Name" -MemberType NoteProperty -Value  $r[0].ToString() -InputObject $obj; 
			Add-Member -Name "Dependent_Object_Type" -MemberType NoteProperty -Value $r[1].ToString() -InputObject $obj; 
			Add-Member -Name "Dependent_Index_Name" -MemberType NoteProperty -Value $r[2].ToString() -InputObject $obj; 
			Add-Member -Name "Dependent_Index_ID" -MemberType NoteProperty -Value $r[3].ToString() -InputObject $obj; 
			$objs = $objs + $obj; 
		}

		if ($ds -ne $null)
		{
			$output = $objs | convertTo-Html -Head $colstyl -Property Dependent_Object_Name,  Dependent_Object_Type, Dependent_Index_Name, Dependent_Index_ID;	
		}

	}
	elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.PartitionFunction") 
	{
	      $pf_name = $item.Name;	
	      $d_qry =
			"SELECT 
				SO.[NAME] AS OBJ_NAME, 
				SO.[TYPE_DESC] AS OBJ_DESC, 
				ISNULL(SI.[NAME],'HEAP') AS INDEX_NAME, 
				SI.[INDEX_ID],
				PS.NAME AS PARTITION_SCHEME_NAME
			FROM 
				SYS.INDEXES SI
			INNER JOIN 
				SYS.PARTITION_SCHEMES PS
			ON SI.DATA_SPACE_ID = PS.DATA_SPACE_ID
			INNER JOIN 
				SYS.ALL_OBJECTS SO
			ON SI.[OBJECT_ID] = SO.[OBJECT_ID]
			INNER JOIN 
				SYS.PARTITION_FUNCTIONS PF
			ON	PS.FUNCTION_ID=PF.FUNCTION_ID	
			WHERE 
				PF.NAME='$pf_name'
			ORDER BY 1";

		$ds = $db.ExecuteWithResults($d_qry).tables[0];

		Foreach ($r in $ds.Rows)
		{
			$obj = New-Object -TypeName Object; 
			Add-Member -Name "Dependent_Object_Name" -MemberType NoteProperty -Value  $r[0].ToString() -InputObject $obj; 
			Add-Member -Name "Dependent_Object_Type" -MemberType NoteProperty -Value $r[1].ToString() -InputObject $obj; 
			Add-Member -Name "Dependent_Index_Name" -MemberType NoteProperty -Value $r[2].ToString() -InputObject $obj; 
			Add-Member -Name "Dependent_Index_ID" -MemberType NoteProperty -Value $r[3].ToString() -InputObject $obj; 
			Add-Member -Name "Dependent_Partition_Scheme" -MemberType NoteProperty -Value $r[4].ToString() -InputObject $obj; 
			$objs = $objs + $obj; 
		}

		if ($ds -ne $null)
		{
			$output = $objs | convertTo-Html -Head $colstyl -Property Dependent_Object_Name,  Dependent_Object_Type, Dependent_Index_Name, Dependent_Index_ID, Dependent_Partition_Scheme;	
		}

	}
	else
	{
		$d_qry = 
			"SELECT 
				REFERENCING_SCHEMA_NAME+'.'+REFERENCING_ENTITY_NAME AS DEPENDENT_OBJ,
				TYPE_DESC AS OBJECT_TYPE
			FROM
				SYS.DM_SQL_REFERENCING_ENTITIES ('$item', 'OBJECT') AS DMV_SRE
			INNER JOIN
				SYS.OBJECTS AS SO
			ON
				DMV_SRE.REFERENCING_ID = SO.OBJECT_ID";
	
		$ds = $db.ExecuteWithResults($d_qry).tables[0];

		Foreach ($r in $ds.Rows)
		{
			$obj = New-Object -TypeName Object; 
			Add-Member -Name "Dependent_Object_Name" -MemberType NoteProperty -Value  $r[0].ToString() -InputObject $obj; 
			Add-Member -Name "Dependent_Object_Type" -MemberType NoteProperty -Value $r[1].ToString() -InputObject $obj; 
			$objs = $objs + $obj; 
		}

		if ($ds -ne $null)
		{
			$output = $objs | convertTo-Html -Head $colstyl -Property Dependent_Object_Name,  Dependent_Object_Type;	
		}
	}

	return $output;
}


# This function buils a list of links for database object types 
function buildLinkList 
{ 
    param ($array, $path); 
    if($array) 
    { 
            $output = "<ol style='list-style-type:arabic-numbers'>"; 	
	    foreach($item in $array) 
	    { 
		if($item.IsSystemObject -eq $false) # Exclude system objects 
		{     
		    if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Schema") 
		    { 
			$output += "`n<li><a href=`"$path" + $item.Name + ".html`">" + $item.Name + "</a></li>"; 
		    } 
		    elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Trigger") 
		    { 
			$output += "`n<li><a href=`"$path" + $item.Parent.Schema + "." + $item.Name + ".html`">" + $item.Parent.Schema + "." + $item.Name + "</a></li>"; 
		    }
		    elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.User") 
		    { 
			if( $item.Name.indexOf('\') -ne $null)
			{
				$output += "`n<li><a href=`"$path" + $item.Name.replace('\','_') + ".html`">" + $item.Name + "</a></li>"; 
			}
			else
			{
				$output += "`n<li><a href=`"$path" + $item.Name + ".html`">" + $item.Name + "</a></li>"; 
			}
		    }
		    else 
		    { 
			$output += "`n<li><a href=`"$path" + $item.Schema + "." + $item.Name + ".html`">" + $item.Schema + "." + $item.Name + "</a></li>"; 
		    } 
		}
		else
		{

			if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.PartitionFunction") 
			{ 
			      $output += "`n<li><a href=`"$path" + $item.Name + ".html`">" + $item.Name + "</a></li>"; 
			} 
			elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.PartitionScheme") 
			{ 
			      $output += "`n<li><a href=`"$path" + $item.Name + ".html`">" + $item.Name + "</a></li>"; 
			} 
			elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.UserDefinedDataType") 
			{ 
			      $output += "`n<li><a href=`"$path" + $item.Name + ".html`">" + $item.Name + "</a></li>"; 
			} 
		}		
	    } 
	    $output += "</ol>"; 
    }
    else
    {
	$output = "";
    }
    return $output; 
} 
 
# Return the DDL for a given database object 
function getObjectDefinition 
{ 
    param ($item); 
    $definition = ""; 
    # Schemas don't like our scripting options 
    if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Schema") 
    { 
        $definition = $item.Script(); 
    } 
    else 
    { 
        $options = New-Object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions'); 
        $options.DriAll = $true; 
        $options.Indexes = $true; 
        $definition = $item.Script($options); 
    } 
    return "<pre style='background-color:#736F6E;font-family:courier new;color:snow;font-size:12px;'><br><br>$definition<br><br></pre>"; 
} 
 
# This function will get the comments on objects 
# MS calls these MS_Descriptionn when you add them through SSMS 
function getDescriptionExtendedProperty 
{ 
    param ($item); 
    $description = "No MS_Description property on object."; 
    foreach($property in $item.ExtendedProperties) 
    { 
        if($property.Name -eq "MS_Description") 
        { 
            $description = $property.Value; 
        } 
    } 
    return $description; 
} 
 
# Gets the parameters for a Stored Procedure 
function getProcParameterTable 
{ 
    param ($proc); 
    $proc_params = $proc.Parameters; 
    $colstyl = $colstylval;
    $prms = $proc_params | ConvertTo-Html -head $colstyl -Property Name, DataType, DefaultValue, IsOutputParameter; 
    return $prms; 
} 
 
# Returns a html table of column details for a db table 
function getTableColumnTable 
{ 
    param ($table); 
    $table_columns = $table.Columns; 
    $objs = @();
    $colstyl = $colstylval;
    foreach($column in $table_columns) 
    { 
        $obj = New-Object -TypeName Object; 
        $description = getDescriptionExtendedProperty $column; 
        Add-Member -Name "Name" -MemberType NoteProperty -Value $column.Name -InputObject $obj; 
        Add-Member -Name "DataType" -MemberType NoteProperty -Value $column.DataType -InputObject $obj; 
        Add-Member -Name "Default" -MemberType NoteProperty -Value $column.Default -InputObject $obj; 
        Add-Member -Name "Identity" -MemberType NoteProperty -Value $column.Identity -InputObject $obj; 
        Add-Member -Name "InPrimaryKey" -MemberType NoteProperty -Value $column.InPrimaryKey -InputObject $obj; 
        Add-Member -Name "IsForeignKey" -MemberType NoteProperty -Value $column.IsForeignKey -InputObject $obj; 
        Add-Member -Name "Description" -MemberType NoteProperty -Value $description -InputObject $obj; 
        $objs = $objs + $obj; 
    } 
    $cols = $objs | ConvertTo-Html -head $colstyl -Property Name, DataType, Default, Identity, InPrimaryKey, IsForeignKey, Description ; 
    return $cols; 
} 
 
# Returns a html table containing trigger details 
function getTriggerDetailsTable 
{ 
    param ($trigger); 
        $colstyl = $colstylval;
    $trigger_details = $trigger | ConvertTo-Html -head $colstyl -Property IsEnabled, CreateDate, DateLastModified, Delete, DeleteOrder, Insert, InsertOrder, Update, UpdateOrder; 
    return $trigger_details; 
} 

function getUsrRights
{
	param ($item, $db);
	$objs = @();
	
	$colstyl = $colstylval;

	foreach($db_perm in $db.EnumDatabasePermissions($item.Name))
	{
		$obj = New-Object -TypeName Object; 
		Add-Member -Name "DatabasePermission" -MemberType NoteProperty -Value $db_perm.PermissionType -InputObject $obj; 
		$objs = $objs + $obj; 
	}

	$usr_dbperm = $objs | ConvertTo-Html -head $colstyl -Property DatabasePermission ; 

	foreach($obj_perm in $db.EnumObjectPermissions($item.Name))
	{
		$obj = New-Object -TypeName Object; 
		Add-Member -Name "PermissionType" -MemberType NoteProperty -Value $obj_perm.PermissionType -InputObject $obj; 
		Add-Member -Name "ObjectName" -MemberType NoteProperty -Value $obj_perm.ObjectName -InputObject $obj; 
		$objs = $objs + $obj; 
	}

	$usr_objperm = $objs | ConvertTo-Html -head $colstyl -Property PermissionType, ObjectName  ;

	return ($usr_dbperm + "<br><br>" + $usr_objperm);
}
 
function getIndexInfo
{
	param($item);   	
	$idx_info = "";
	foreach($idx in $item.Indexes)
	{
		$idx_cat = "Non-Clustered";
		if ($idx.IsClustered -eq "False")
		{
			$idx_cat ="Clustered";
		}
			
		if ([String]$idx.IndexKeyType -eq "DriPrimaryKey")
		{
			$idx_type = $idx_cat+ " Primary Key";
		}
		elseif ([String]$idx.IndexKeyType -eq "DriPrimaryKey")
		{
			$idx_type = $idx_cat+ " Unique Key";
		}
		else
		{
			$idx_type = $idx_cat+ " Non-Unique";
		}
		$idx_info += "<br><b> Index Name:</b> "+ $idx.Name+ "<BR>";
		$idx_info += "<b>Index Type:</b> "+$idx_type+ "<br>";
		if($idx.IsPartitioned -eq "True")
		{
			$idx_info += "<b>Partition Scheme:</b> "+$idx.PartitionScheme+"<br>";
		}
		else
		{
			$idx_info += "<b>FileGroup:</b> "+$idx.FileGroup+"<br>";
		}		
		$idx_cols = "<br><b>Indexed On: </b><br>";
		$idx_inc_cols = "<br><b>With the included columns: </b><br>"
		foreach($idxcol in $idx.IndexedColumns)
		{
			if($idxcol.IsIncluded -eq $False)
			{
				$idx_cols += $idxcol.Name + "<br>";
			}
			else
			{
				$idx_inc_cols += $idxcol.Name + "<br>";
			}	
		}
		$idx_info += $idx_cols+$idx_inc_cols+"<br><br><hr/>";
	}

	if($idx_info -eq "")
	{
		$idx_info = "No index defined on $item";
	}
	return $idx_info;
}	


# This function creates all the html pages for our database objects 
function createObjectTypePages 
{ 
    param ($objectName, $objectArray, $filePath, $db); 
    New-Item -Path $($filePath + $db.Name + "\$objectName") -ItemType directory -Force | Out-Null; 
    # Create index page for object type 
    $page = $filePath + $($db.Name) + "\$objectName\index.html";
    $list = buildLinkList $objectArray ""; 
    if($objectArray -eq $null) 
    { 
        $list = "No $objectName in $db"; 
	writeHtmlPage $objectName $objectName $list $page; 
    } 
    else
    {
		writeHtmlPage $objectName $objectName $list $page;
		
		$SourceSysObjPage = $page;
	
		$chkSysObject = $True;

		$nonPFPS = $True;

		# Individual object pages
		
		foreach ($item in $objectArray) 
		{ 
			
		    if($item.IsSystemObject -eq $false) # Exclude system objects 
		    {
			$chkSysObject = $False;

			$description = getDescriptionExtendedProperty($item); 
			$body = "<h2 style='font-size:15px;text-decoration:underline'>DESCRIPTION</h2>$description"; 
			$definition = getObjectDefinition $item; 
			if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Schema") 
			{ 
			    $page = $filePath + $($db.Name + "\$objectName\" + $item.Name + ".html"); 
			} 
			elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Trigger") 
			{ 
			    $page = $filePath + $($db.Name + "\$objectName\" + $item.Parent.Schema + "." + $item.Name + ".html"); 
			    Write-Host $path; 
			} 
			else 
			{ 
			    $page = $filePath + $($db.Name + "\$objectName\" + $item.Schema + "." + $item.Name + ".html"); 
			} 
			$title = ""; 
			if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Schema") 
			{ 
			    $title = $item.Name; 
			    $body += "<h2 style='font-size:15px;text-decoration:underline'>OBJECT DEFINITION</h2>$definition"; 
			} 
			else 
			{ 
			    $title = $item.Schema + "." + $item.Name; 

			    if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.User") 
			    {
				if( $item.Name.indexOf('\') -ne $null)
				{
					$page = $filePath + $($db.Name + "\$objectName\" + $item.Name.replace('\','_') + ".html");  
				}
				else
				{
					$page = $filePath + $($db.Name + "\$objectName\" + $item.Name + ".html");  
				}

				$title = $item.Name; 
				$usr_perm = getUsrRights $item $db;
				$usr_props =
						"Created Date: "+$item.CreateDate.toString()+"<br>"+
						"Last Modified On: "+$item.DateLastModified.toString()+"<br>"+
						"Default Schema: "+$item.DefaultSchema+"<br>"+
						"Login: "+$item.Login+"<br>"+
						"LoginType :"+$item.LoginType+"<br>"; 
				$body += "<h2 style='font-size:15px;text-decoration:underline'>Properties</h2><p style='line-spacing:120%'>$usr_props</p>"; 					
				$body += "<h2 style='font-size:15px;text-decoration:underline'>Permissions and Grants</h2><p style='line-spacing:120%'>$usr_perm</p>"; 					
				$body += "<h2 style='font-size:15px;text-decoration:underline'>OBJECT DEFINITION</h2>$definition";
	
			    }
			    elseif(([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.StoredProcedure") -or ([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.UserDefinedFunction")) 
			    { 
				
				$sp_props =
						"Created Date: "+$item.CreateDate.toString()+"<br>"+
						"Last Modified On: "+$item.DateLastModified.toString()+"<br>"+
						"Implementation Type: "+$item.ImplementationType+"<br>"+
						"Schema: "+$item.Schema+"<br>"+
						"Owner :"+$item.Owner+"<br>"; 
				if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.UserDefinedFunction")
				{	
					$udf_props=
						"Return Data Type: "+$item.DataType+"<br>"+
						"Function Type: "+$item.FunctionType+"<br>"+
						"Is Function Deterministic : "+$item.IsDeterministic+"<br>"+
						"Is Function Schema Bound :"+$item.IsSchemaBound+"<br>"; 
					$udf_idx = getIndexInfo $item;
					$sp_props += $udf_props;
				}

				$dpncy_info = getObjectDependency $item $db;

				if ( $dpncy_info -eq $null)
				{
					$dpncy_info = "No dependency found !!!";
				}
				

				$body += "<h2 style='font-size:15px;text-decoration:underline'>Properties</h2><p style='line-spacing:120%'>$sp_props</p>"; 					
				$proc_params = getProcParameterTable $item; 
				$body += "<h2 style='font-size:15px;text-decoration:underline'>PARAMETERS</h2>$proc_params";

				if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.UserDefinedFunction")
				{	
					$body += "<h2 style='font-size:15px;text-decoration:underline'>Indexes</h2><p style='line-spacing:120%'>$udf_idx</p>"; 
				}

				$body += "<h2 style='font-size:15px;text-decoration:underline'>Dependency Info</h2><p style='line-spacing:120%'>$dpncy_info</p>"; 

				$body += "<h2 style='font-size:15px;text-decoration:underline'>OBJECT DEFINITION</h2>$definition"; 
			    } 
			    elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Table") 
			    { 
				$tbl_props = 
							"Created Date: "+$item.CreateDate.toString()+"<br>"+
							"Last Modified On: "+$item.DateLastModified.toString()+"<br>";
					if($item.IsPartitioned -eq "True")
					{
						$tbl_props += "Partition Scheme: "+$item.PartitionScheme+"<br>";
					}
					else
					{
						$tbl_props += "FileGroup: "+$item.FileGroup+"<br>";
					}		
						$tbl_props +=
							"Size: "+(($item.DataSpaceUsed+$item.IndexSpaceUsed)/1024)+" MB <br>"+
							"Table Paritioned: "+$item.IsPartitioned+"<br>"+
							"Schema: "+$item.Schema+"<br>"+
							"Row Count: "+$item.RowCount.toString()+"<br>";
					$body += "<h2 style='font-size:15px;text-decoration:underline'>Properties</h2><p style='line-spacing:120%'>$tbl_props</p>"; 

				$cols = getTableColumnTable $item; 

				$dpncy_info = getObjectDependency $item $db;

				if ( $dpncy_info -eq $null)
				{
					$dpncy_info = "No dependency found !!!";
				}

				$body += "<h2 style='font-size:15px;text-decoration:underline'>COLUMNS</h2><p style='font-size:10px'>$cols</p><br>";
				 
				$tbl_idx = getIndexInfo $item;
				
				$body += "<h2 style='font-size:15px;text-decoration:underline'>Indexes</h2><p style='line-spacing:120%'>$tbl_idx</p>"; 

				$body += "<h2 style='font-size:15px;text-decoration:underline'>Dependency Info</h2><p style='line-spacing:120%'>$dpncy_info</p>"; 

				$body += "<h2 style='font-size:15px;text-decoration:underline'>OBJECT DEFINITION</h2>$definition"; 

			    } 
			    elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.View") 
			    { 
				$vw_props = 
						"Created Date: "+$item.CreateDate.toString()+"<br>"+
						"Last Modified On: "+$item.DateLastModified.toString()+"<br>"+
						"Schema: "+$item.Schema+"<br>"+
						"Is View Schema Bound :"+$item.IsSchemaBound+"<br>"+ 
						"Owner :"+$item.Owner+"<br>"; 

				$body += "<h2 style='font-size:15px;text-decoration:underline'>Properties</h2><p style='line-spacing:120%'>$vw_props</p>"; 
						
				$cols = getTableColumnTable $item; 
				$body += "<h2 style='font-size:15px;text-decoration:underline'>COLUMNS</h2>$cols"; 

				$dpncy_info = getObjectDependency $item $db;

				if ( $dpncy_info -eq $null)
				{
					$dpncy_info = "No dependency found !!!";
				}

				if($item.HasIndex)
				{
					$vw_idx = getIndexInfo $item;
					$body += "<h2 style='font-size:15px;text-decoration:underline'>Indexes</h2><p style='line-spacing:120%'>$vw_idx</p>"; 
				}

				$body += "<h2 style='font-size:15px;text-decoration:underline'>Dependency Info</h2><p style='line-spacing:120%'>$dpncy_info</p>"; 
				
				$body += "<h2 style='font-size:15px;text-decoration:underline'>OBJECT DEFINITION</h2>$definition";			

			    } 
			    elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Trigger") 
			    { 
				$title = $item.Parent.Schema + "." + $item.Name;

				$trg_props = 
						"Implementation Type: "+$item.ImplementationType+"<br>"+
						"Trigger defined on: "+$item.Parent.Name+"<br>";

				$body += "<h2 style='font-size:15px;text-decoration:underline'>Properties</h2><p style='line-spacing:120%'>$trg_props</p>"; 

				$dpncy_info = getObjectDependency $item $db;

				if ( $dpncy_info -eq $null)
				{
					$dpncy_info = "No dependency found !!!";
				}

				$trigger_details = getTriggerDetailsTable $item;
				$body += "<h2 style='font-size:15px;text-decoration:underline'>DETAILS</h2>$trigger_details";

				$body += "<h2 style='font-size:15px;text-decoration:underline'>Dependency Info</h2><p style='line-spacing:120%'>$dpncy_info</p>"; 
				
				$body += "<h2 style='font-size:15px;text-decoration:underline'>OBJECT DEFINITION</h2>$definition"; 
			    }  
			} 
			writeHtmlPage $title $title $body $page; 
		    }
		    else
		    { 
		
			$page = $filePath + $($db.Name + "\$objectName\" + $item.Name + ".html"); 
			$description = getDescriptionExtendedProperty($item); 
			$body = "<h2 style='font-size:15px;text-decoration:underline'>DESCRIPTION</h2>$description"; 
			$definition = getObjectDefinition $item; 
			$title = $item.Name; 
			
			if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.PartitionFunction") 
			{	
				$nonPFPS = $False;
				$pf_details = "Partition Range Type: "+$item.RangeType+"<br>Partition Range Value: "+$item.RangeValues; 
				$body += "<h2 style='font-size:15px;text-decoration:underline'>DETAILS</h2>$pf_details";

				$dpncy_info = getObjectDependency $item $db;
				if ( $dpncy_info -eq $null)
				{
					$dpncy_info = "No dependency found !!!";
				}
				$body += "<h2 style='font-size:15px;text-decoration:underline'>Dependency Info</h2><p style='line-spacing:120%'>$dpncy_info</p>"; 
				
				$body += "<h2 style='font-size:15px;text-decoration:underline'>OBJECT DEFINITION</h2>$definition"; 	
				
				writeHtmlPage $title $title $body $page;
			}
			elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.PartitionScheme") 
			{
				$nonPFPS = $False;
				$pf_details = "Partition FileGroups: "+$item.FileGroups+"<br>Partition Function: "+$item.PartitionFunction; 
				$body += "<h2 style='font-size:15px;text-decoration:underline'>DETAILS</h2>$pf_details";

				$dpncy_info = getObjectDependency $item $db;
				if ( $dpncy_info -eq $null)
				{
					$dpncy_info = "No dependency found !!!";
				}
				$body += "<h2 style='font-size:15px;text-decoration:underline'>Dependency Info</h2><p style='line-spacing:120%'>$dpncy_info</p>"; 
				
				$body += "<h2 style='font-size:15px;text-decoration:underline'>OBJECT DEFINITION</h2>$definition"; 
				writeHtmlPage $title $title $body $page;
			}
		        elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.UserDefinedDataType") 
	                { 
				$nonPFPS = $False;
				$udt_props =
						"Nullable Data Type: "+$item.Nullable+"<br>"+
						"Base Data Type: "+$item.SystemType.toString()+"<br>"+
						"Schema: "+$item.Schema+"<br>"+
						"Length: "+$item.Length+"<br>"+
						"Max Length: "+$item.MaxLength+"<br>"+
						"Numeric Precision: "+$item.NumericPrecision+"<br>"+
						"Numeric Scale: "+$item.NumericScale+"<br>"+
						"Owner :"+$item.Owner+"<br>"; 

				$body += "<h2 style='font-size:15px;text-decoration:underline'>Properties</h2><p style='line-spacing:120%'>$udt_props</p>"; 

				$dpncy_info = getObjectDependency $item $db;

				if ( $dpncy_info -eq $null)
				{
					$dpncy_info = "No dependency found !!!";
				}

				$body += "<h2 style='font-size:15px;text-decoration:underline'>Dependency Info</h2><p style='line-spacing:120%'>$dpncy_info</p>"; 
				
				$body += "<h2 style='font-size:15px;text-decoration:underline'>OBJECT DEFINITION</h2>$definition";			
				writeHtmlPage $title $title $body $page;
		       }		
		    }   
		}
		
		if (( $chkSysObject -eq $True ) -and ( $nonPFPS -eq $True ))
		{
			$list = "No $objectName in $db"; 
			writeHtmlPage $objectName $objectName $list $SourceSysObjPage; 
		}

	}
} 

$srvlist = "";

if($args -ne $null)
{
	Write-Host "Attempting to retrieve list for processing !!! ";
	if((test-path $args[0]) -eq $false )
	{
		Write-Warning "Incorrect File Name or Path. Please verify !!! ";
		endExecution;	
	}
	else
	{
		$srvlist = get-content $args[0];
		write-host "Successfully retrieved list for processing !!!";
	}



	# Root directory where the html documentation will be generated 
	$filePath = "$env:USERPROFILE\database_documentation\"; 
	New-Item -Path $filePath -ItemType directory -Force | Out-Null; 
	Write-Host "Note: The generated documentation will be stored in $filepath folder.";

	# Uncomment for a SQL connection
	$uname = "username";
	$pwd   = "password";

	foreach ($srv in $srvlist)
	{
		# Use the below for SQL authentication
		$mySrvConn = new-object Microsoft.SqlServer.Management.Common.ServerConnection;
		$mySrvConn.ServerInstance= $srv;
		$mySrvConn.LoginSecure = $false;
		# Please change to appropriate credentials
		$mySrvConn.Login = $uname;
		$mySrvConn.Password = $pwd;
		
		$sql_server = New-Object Microsoft.SqlServer.Management.Smo.Server $mySrvConn; 

		# Uncomment below( and Comment Above) and use this block for trusted authentication
		#$sql_server = New-Object Microsoft.SqlServer.Management.Smo.Server $srv; 

		# Check Whether Connection is possible 
		if($sql_server.Version -eq $null)
		{
			Write-warning "No connection to the instance ! Please check the credentials !  ";
			continue;
		}

		if($sql_server.InstanceName -eq "")
		{
			$srv_path = $sql_server.Name+"_"+$sql_server.ServiceName;
		}
		else
		{
			$srv_path = $sql_server.ServiceName;
		}
		
		$filePath += $srv_path+"\";
		
		# IsSystemObject not returned by default so ask SMO for it 
		$sql_server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.Table], "IsSystemObject"); 
		$sql_server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject"); 
		$sql_server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.StoredProcedure], "IsSystemObject"); 
		$sql_server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.Trigger], "IsSystemObject"); 
		 
		# Get databases on our server 
		$databases = getDatabases $sql_server; 

		# Directory for instance level database to keep everything tidy 
		New-Item -Path $($filePath) -ItemType directory -Force | Out-Null;

		if($args[1] -eq "Scripts")
		{
			$rootdir = $filePath;

			foreach ($db in $databases) 
			{ 
			    Write-Host "Scripting " $db.Name; 
			    $dbName = $db.Name;

			    $filePath = $rootdir + $dbName + "\Script\";
			    $outfile  = $rootdir + $dbName + "\Script\$dbName.SQL"; 	
			    
			    # Directory for each database to keep everything tidy 
			    New-Item -Path $($filePath) -ItemType directory -Force | Out-Null; 

			    $scrp = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($db.Parent);
			    $optns = New-Object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions'); 
                            
			    $optns.ScriptSchema = $True;
			    $optns.ScriptDrops = $False;
			    $optns.NoCommandTerminator = $False;
			    $optns.IncludeIfNotExists = $True;
			    $optns.Default = $True;
			    $optns.WithDependencies = $False;
			    $optns.Indexes = $True;
			    $optns.FileName = $outfile;
			    $optns.AppendToFile = $True;
			    $optnsToFileOnly = $True;
			    $optns.BatchSize = 1;

			    $scrp.options = $optns;

			    $scrp.script($db) | out-Null;	

     			    $sql_server.Databases[$dbName].PartitionFunctions | ForEach{ $scrp.script($_)} | out-Null;
       			    $sql_server.Databases[$dbName].PartitionSchemes | ForEach{ $scrp.script($_)} | out-Null;
       			    $sql_server.Databases[$dbName].UserDefinedDataTypes | ForEach{ $scrp.script($_)} | out-Null;

    			    $all += $db.Schemas;
                            $all += $db.UserDefinedFunctions;
			    $all += $db.UserDefinedDataTypes;
			    $all = $db.Tables;
                            $all += $db.Views;
			    $all += $db.StoredProcedures;
			    $all += $db.Triggers;
			    $all += $db.Users;

			    $all | where {!($_.IsSystemObject)} | ForEach{ $scrp.script($_)} | out-Null ;

           		    foreach($user in $db.Users)
			    {
				foreach($databasePermission in $db.EnumDatabasePermissions($user.Name))
				{
					$dbperm = $databasePermission.PermissionState;
  					$permtype = $databasePermission.PermissionType;	
					$permgrnti = $databasePermission.Grantee;	
					out-file $outfile -Append -inputobject "$dbperm  $permtype TO $permgrnti;";
				}
				foreach($objectPermission in $db.EnumObjectPermissions($user.Name))
				{
					$objperm = $objectPermission.PermissionState;
					$permtype = $objectPermission.PermissionType;
					$permgrnti = $objectPermission.Grantee;
					$objName = $objectPermission.ObjectName;
					Out-File $outfile -Append -inputobject "$objperm $permtype ON $objName TO $permgrnti;";
				}
			    }

			}	 

		}
		elseif ($args[1] -eq "Docs")
		{

			$srv_page = $filePath + "\index.html";	
			
			$body = "<ul><li><a href='SrvInfo.html'>Server Info</a></li></ul>";
			
			$body += "<br><br><h1>Databases</h1><br><ol style='list-style-type:arabic-numbers'>"; 

			foreach ($db in $databases) 
			{ 
				$db_pg = $filePath + $($db.Name) + "\index.html";
				$body += "<li><a href='$($db.Name)/index.html'>$($db.Name)</a></li>";
			}
			   
			$body += "</ol>"; 

			writeHtmlPage $srv_path $srv_path $body $srv_page; 

			  # Get info for the current database 
			  getServerInfo $sql_server; 
			  Write-Host "Documented Server info";

			foreach ($db in $databases) 
			{ 
			    Write-Host "Started documenting " $db.Name; 
			    # Directory for each database to keep everything tidy 
			    New-Item -Path $($filePath + $db.Name) -ItemType directory -Force | Out-Null; 
			 
			    # Make a page for the database 
			    $db_page = $filePath + $($db.Name) + "\index.html"; 
			    $body = "<ol style='list-style-type:arabic-numbers'> 
					  <li><a href='DBInfo.html'>Database Info</a></li> 
					<li><a href='Schemata/index.html'>Schemata</a></li> 
					<li><a href='Tables/index.html'>Tables</a></li> 
					<li><a href='Views/index.html'>Views</a></li> 
					<li><a href='Stored Procedures/index.html'>Stored Procedures</a></li> 
					<li><a href='Functions/index.html'>Functions</a></li> 
					<li><a href='Triggers/index.html'>Triggers</a></li>
					<li><a href='UDDTs/index.html'>User Defined DataTypes</a></li>			
					<li><a href='Partition-Functions/index.html'>Partition Function</a></li>
					<li><a href='Partition-Schemes/index.html'>Partition Scheme</a></li>
					<li><a href='DB-Users/index.html'>Database Users</a></li>
				    </ol>"; 
			    writeHtmlPage $db $db $body $db_page; 
			
			    # Get info for the current database 
			    getDatabaseInfo $sql_server $db; 
			    Write-Host "Documented DB info"; 

			    # Get schemata for the current database 
			    $schemata = getDatabaseSchemata $sql_server $db; 
			    createObjectTypePages "Schemata" $schemata $filePath $db; 
			    Write-Host "Documented schemata"; 
			    
			    # Get tables for the current database 
			    $tables = getDatabaseTables $sql_server $db; 
			    createObjectTypePages "Tables" $tables $filePath $db; 
			    Write-Host "Documented tables"; 

			    # Get views for the current database 
			    $views = getDatabaseViews $sql_server $db; 
			    createObjectTypePages "Views" $views $filePath $db; 
			    Write-Host "Documented views"; 

			    # Get procs for the current database 
			    $procs = getDatabaseStoredProcedures $sql_server $db; 
			    createObjectTypePages "Stored Procedures" $procs $filePath $db; 
			    Write-Host "Documented stored procedures"; 
			    
			    # Get functions for the current database 
			    $functions = getDatabaseFunctions $sql_server $db; 
			    createObjectTypePages "Functions" $functions $filePath $db; 
			    Write-Host "Documented functions"; 

			    # Get triggers for the current database 
			    $triggers = getDatabaseTriggers $sql_server $db; 
			    createObjectTypePages "Triggers" $triggers $filePath $db; 
			    Write-Host "Documented triggers"; 

			    # Get UDDTs for the current database 
			    $uddts = getUDDTS $sql_server $db; 
			    createObjectTypePages "UDDTs" $uddts $filePath $db; 
			    Write-Host "Documented User defined datatypes"; 

    			    # Get partition functions for the current database 
			    $partitionfunctions = getDatabasePartitions $sql_server $db;
			    createObjectTypePages "Partition-Functions" $partitionfunctions $filePath $db; 
			    Write-Host "Documented Partition Functions";
			    
			    # Get partition schemes for the current database 
			    $partitionschemes = getDatabasePartitionSchemes $sql_server $db; 
			    createObjectTypePages "Partition-Schemes" $partitionschemes $filePath $db; 
			    Write-Host "Documented Partition Schemes";

			    # Get list of DB users
			    $dbusers = getDBUsers $sql_server $db; 
			    createObjectTypePages "DB-Users" $dbusers $filePath $db; 
			    Write-Host "Documented DB Users";
			 
			    Write-Host "Finished documenting " $db.Name; 
			  
			}
		}
		else
		{
			write-warning "Do not understand supplied second argument. Should be either Scripts or Docs !!!"
			endExecution;
		}	
	}
	endExecution;
}
else
{
	Write-Warning "No server list file specified !!! ";
	endExecution;	
}

