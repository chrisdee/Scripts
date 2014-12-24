## PowerShell: Script to Search a File Path For All Files by Name Or Type ##

<#
			" Satnaam WaheGuru Ji"	
			Resource: https://gallery.technet.microsoft.com/scriptcenter/Search-for-Files-Using-340397aa
			Author  :  Aman Dhally
			E-Mail  :  amandhally@gmail.com
			website :  www.amandhally.net
			twitter : https://twitter.com/#!/AmanDhally
			facebook: http://www.facebook.com/groups/254997707860848/
			Linkedin: http://www.linkedin.com/profile/view?id=23651495

			Date	: 13-Sept-2012, 11:43 AM
			File	: Find_Files
			Purpose : FInd Files Using Powershell
			
			Version : 1

			


#>

"`n"
write-Host "---------------------------------------------" -ForegroundColor Yellow
$filePath = Read-Host "Please Enter File Path to Search"
write-Host "---------------------------------------------" -ForegroundColor Green
$fileName = Read-Host "Please Enter File Name to Search"
write-Host "---------------------------------------------" -ForegroundColor Yellow
"`n"

Get-ChildItem -Recurse -Force $filePath -ErrorAction SilentlyContinue | Where-Object { ($_.PSIsContainer -eq $false) -and  ( $_.Name -like "*$fileName*") } | Select-Object Name,Directory| Format-Table -AutoSize *

write-Host "------------END of Result--------------------" -ForegroundColor Magenta

# end of the script