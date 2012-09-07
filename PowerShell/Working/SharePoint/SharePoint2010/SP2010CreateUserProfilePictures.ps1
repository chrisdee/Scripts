<# SharePoint Server 2010: PowerShell Script To Populate The User Profile Picture Property From A CSV File

Overview: The script below updates the Picture (PictureURL) User Profile Property from a CSV file that contains
the users DOMAIN\AccountName and a URL for each users picture stored within a SharePoint Picture Library.

Usage:

Create a new 'Picture Library'on your SharePoint Site.

Ensure that all of your user photos are named the same as their AD account names e.g. 'chris.dee' or 'CDee'.

Upload all of your images to the 'Picture Library' you created above.

Now provision your CSV file to include the following column headers: 'UserName','PictureURL'.

Example:

UserName,PictureURL
DOMAIN\Adam.Evans,http://YourSite.com/userphotos/Adam.Evans.jpg
DOMAIN\John.Murray,http://YourSite.com/userphotos/John.Murray.jpg

Edit the following variables, and run the script to map the photos to the User Profile Picture properties

$CSVFile
$mySiteUrl

Important:

You should see the photos mapped against the User Profiles Picture Properties field within your User 
Profile Service Application once ran.

For the images to show up on people search results 'thumb nail' previews:

Kick off a Crawl of your Content Source that contains the start address to your My Sites.

Script Resource: http://gallery.technet.microsoft.com/scriptcenter/Populate-PictureUrl-with-21f5d5d7

#>

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue

$CSVFile = "D:\Scripts\pictureurls.csv" #Change this to suit your environment
$mySiteUrl = "http://mysite.contoso.com" #Change this to suit your environment

#Connect to the User Profile Manager
$site = Get-SPSite $mySiteUrl
$context = Get-SPServiceContext $site
$profileManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($context)


#Read CSV file and process each line
$csv = import-csv -path $CSVFile
foreach ($line in $csv) 
{
	$adAccount = '"' + $line.UserName + '"'
	$pictureUrl = $line.PictureURL

	
	$up = $profileManager.GetUserProfile($line.UserName)
	if ($up)
	{
		$up["PictureURL"].Value = $pictureUrl
		$up.Commit()
		write-host $up.DisplayName" --> ", $pictureUrl	
	}
	if (!$up) {
		write-host $adAccount, " --> no profile found"
	}
}
