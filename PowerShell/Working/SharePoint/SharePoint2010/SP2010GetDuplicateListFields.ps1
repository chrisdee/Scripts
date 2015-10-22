## SharePoint Server: PowerShell Script to Identify and List Duplicate List Fields against a Content Database ##

<#>

Overview: Script that runs against a SharePoint Content Database to Loop through each Site Collection, Sub-Web, List, and List Field to try identify / list duplicate list fields

Environments: SharePoint Server 2010 / 2013 Farms

Usage: Run the script, and when prompted, provide the content database name you want to check for duplicates in. 

The script generates the following text report files in the same directory it was run in:

DuplicateFieldIntNameIDs.txt
DuplicateListFieldIDs.txt
DuplicateViewFields.txt

Resource: http://blog.sharepoint-voodoo.net/?p=142

#>

Add-PSSnapin Microsoft.SharePoint.PowerShell -EA 0

# Presumeably the issue you are having is that a Content Database won't upgrade due to duplicate field names
$inputDB = Read-Host "Enter the name of the Content Database to be scanned for duplicate list fields "
$sites = Get-SPSite -Limit All  -ContentDatabase $inputDB

# Set up the logging files and current date
$date = Get-Date
[string]$curloc = get-location
$viewFieldText = "$curloc\DuplicateViewFields.txt"
$listFieldIDText = "$curloc\DuplicateListFieldIDs.txt"
$listFieldIntNameText = "$curloc\DuplicateFieldIntNameIDs.txt"

# Create the initial files by writing the date to them
$date | out-file "$viewFieldText"
$date | out-file "$listFieldIDText"
$date | out-file "$listFieldIntNameText"

# Start looping through each Site Collection in the DB
foreach ($site in $sites)
{

	# Loop through each sub-web in the current site collection
	foreach ($web in $site.allwebs)
	{
		# Loop through each list in the current sub-web	
		foreach ($list in $web.lists)
		{
			$siteName = $site.Title
			Write-Host "Checking $siteName/$web/$list List for duplicate Field Names or IDs..."

			# Create the Arrays that will hold data about the list fields being scanned
			# An array of objects. Each object will be made up of the Field ID, Field Title, and Field Internal Name
			$objFieldArray = @() 

			# Loop through each Field in the list
			foreach($listField in $list.Fields)
			{
				# Does the current list field ID already exist in the array of objects?
				$objFieldRow = $objFieldArray | ?{$_.FieldID -eq $listField.ID}
				$objFieldIntName = $objFieldArray | ?{$_.InternalName -eq $listField.InternalName}

				# If the current list field ID or InternalName was matched in the array of objects, log info about the current list field
				# and the matching list field object from the array of objects
          		if ($objFieldRow.FieldID -eq $listField.ID -or $objFieldIntName.InternalName -eq $listField.InternalName)
                {
					# Generate the variables to be logged to the text file
                    $webUrl = $web.Url
					$listTitle = $list.Title
					$listFieldID = $listField.ID
					$listFieldTitle = $listField.Title
					$listFieldInternalName = $listField.InternalName
					$existingID = $objFieldRow.FieldID
					$existingName = $objFieldRow.FieldName
					$existingInternal = $objFieldRow.InternalName

					# Start logging
					Write-Host "Duplicate item detected"
					"------------Duplicate item detected-----------------" | out-file "$listFieldIDText" -append
                    "Web URL: $webUrl" | out-file "$listFieldIDText" -append
                    "List: $listTitle" | out-file "$listFieldIDText" -append
					"Field #1 ID: $listFieldID" | out-file "$listFieldIDText" -append
                    "Field #1 Title: $listFieldTitle" | out-file "$listFieldIDText" -append
					"Field #1 Internal Name: $listFieldInternalName" | out-file "$listFieldIDText" -append
					"" | out-file "$listFieldIDText" -append
					"Field #2 ID: $existingID" | out-file "$listFieldIDText" -append
					"Field #2  Name: $existingName" | out-file "$listFieldIDText" -append
					"Field #2  InternalName: $existingInternal" | out-file "$listFieldIDText" -append
					"----------------------------------------------------" | out-file "$listFieldIDText" -append
					"" | out-file "$listFieldIDText" -append
                }
				else # If the current list field ID or InternalName is not found in the array of objects, insert it now 
				{
					# Create the blank object
					$objFieldData = "" | select FieldID,FieldName,InternalName

					# Insert data into the object
					$objFieldData.FieldID = $listField.ID
					$objFieldData.FieldName = $listField.Title
					$objFieldData.InternalName = $listField.InternalName

					# Insert the new object into the Array
					$objFieldArray += $objFieldData
				}
			}

			Write-Host "Checking List Views for duplicate fields..."					

			# Now that all of the list fields have been checked, we need to check for duplicate field names in each of the list views
			foreach($ListView in $list.Views)
			{
				# Create an array to hold the Internal Names of the View Fields
				$viewFieldArray = @()

				# Loop through each field in the view
				foreach ($ViewField in $ListView.ViewFields)
				{
					# Check if the current View Field Internal Name exists in the array
              		if ($viewFieldArray -contains $ViewField)
                    {
                        # Log info about the duplicate view field
						$webUrl = $web.Url
						$listTitle = $list.Title
						$listViewTitle = $ListView.Title

						Write-Host "Duplicate item detected"
						"------------Duplicate item detected-----------------" | out-file "$viewFieldText" -append
                        "Web URL: $webUrl" | out-file "$viewFieldText" -append
                        "List: $listTitle" | out-file "$viewFieldText" -append
                        "View Name: $listViewTitle" | out-file "$viewFieldText" -append
                        "Duplicate Field: $ViewField" | out-file "$viewFieldText" -append
						"----------------------------------------------------" | out-file "$viewFieldText" -append
						"" | out-file "$viewFieldText" -append

                    }
                    else 
					{
						# If the view field internal name was not found in the array, add it now
						$viewFieldArray += $ViewField
					}
			  	}
			}
		}
	}
}