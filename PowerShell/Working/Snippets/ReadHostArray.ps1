<#
AUTHOR:    James Philip
BLOG:      Powershelldude.blogspot.com | https://gallery.technet.microsoft.com/Read-HostArray-A-function-e9ac0115

.DESCRIPTION
Read-HostArray, A function to paste an array value in PowerShell.

.Usage
Load this script to your PowerShell console by executing the command ". Filepath\Read-HostArray.ps1" and use the Function "Read-HostArray" wherever you need to get multi line Input from the user, as you use the default command Read-Host in PowerShell.

.Tip:
Paste this script code or add the command that you used to load this script, in your PowerShell Profile File to avoid loading this script everytime you open a new PowerShell Session. 
Powershell Profile file is under your Documents Folder generally (\Documents\WindowsPowershell\Microsoft.Powershell_Profile.ps1). 
You may need to create the Folder (WindowsPowershell) and File (Microsoft.Powershell_Profile.ps1) if they doesn't exist already.

.EXAMPLE - 1
Get services list from multiple computers
Get-WmiObject -Class Win32_Service -ComputerName (Read-HostArray) | Select Name,State

.EXAMPLE - 2
Assign Fullaccess permission for multiple users on User2
Read-HostArray | Foreach { Add-Mailboxpermission $User2 -User $_ -Accessrights Fullaccess}

.EXAMPLE - 3
Assign Fullaccess permission for user2 on multiple mailboxes.
Read-HostArray | Foreach { Add-Mailboxpermission $_ -User User2 -Accessrights Fullaccess}

.NOTES
#>

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$JE5RE2JA4 = New-Object System.Windows.Forms.Form
$JE5RE2JA4.Text = "Read-HostArray"
$JE5RE2JA4.Size = New-Object System.Drawing.Size(300,250) 
$JE5RE2JA4.StartPosition = "CenterScreen"
$JE5RE2JA4.KeyPreview = $True
$JE5RE2JA4.Topmost = $True
$JE5RE2JA4.FormBorderStyle = 'Fixed3D'
$JE5RE2JA4.MaximizeBox = $false
$JE5RE2JA4.Add_KeyDown({
        if($_.Control -eq $True -and $_.KeyCode -eq "A")
        {
            $0j4l2bb.SelectAll()
            $_.SuppressKeyPress = $True
        }
 })

$TD308JY = New-Object System.Windows.Forms.Button
$TD308JY.Location = New-Object System.Drawing.Size(50,180)
$TD308JY.Size = New-Object System.Drawing.Size(75,25)
$TD308JY.Text = "OK"
$TD308JY.DialogResult = [System.Windows.Forms.DialogResult]::OK

$NJ340KD = New-Object System.Windows.Forms.Button
$NJ340KD.Location = New-Object System.Drawing.Size(165,180)
$NJ340KD.Size = New-Object System.Drawing.Size(75,25)
$NJ340KD.Text = "Cancel"
$NJ340KD.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

$0j4l2bb = New-Object System.Windows.Forms.TextBox 
$0j4l2bb.Location = New-Object System.Drawing.Size(10,10) 
$0j4l2bb.Size = New-Object System.Drawing.Size(270,150)
$0j4l2bb.AcceptsReturn = $true
$0j4l2bb.AcceptsTab = $false
$0j4l2bb.Multiline = $true
$0j4l2bb.ScrollBars = 'Both'
$0j4l2bb.WordWrap = $False

$JE5RE2JA4.Controls.Add($TD308JY)
$JE5RE2JA4.Controls.Add($NJ340KD)
$JE5RE2JA4.Controls.Add($0j4l2bb)
$JE5RE2JA4.AcceptButton = $TD308JY
$JE5RE2JA4.CancelButton = $NJ340KD

Function Read-HostArray
{
     $JE5RE2JA4.Add_Shown({$JE5RE2JA4.Activate(); $0j4l2bb.focus()})
     $H4ow2 = $JE5RE2JA4.ShowDialog()

     if ($H4ow2 –eq [System.Windows.Forms.DialogResult]::OK)
     {
        Return $0j4l2bb.Text.Replace("`n","").Split()
     }
}

Write-Host "`nYou can now use Read-HostArray in your code lines. If you see any issues, check the command you used to load this script." -ForegroundColor Green
Write-Host "Tip: " -ForegroundColor Yellow
Write-Host "Paste this script code or add the command that you just used to load this script now, in your PowerShell Profile File to avoid loading this script everytime you open a new PowerShell Session." -ForegroundColor Yellow
Write-Host 'Powershell Profile file is under your Documents Folder generally (\Documents\WindowsPowershell\Microsoft.Powershell_Profile.ps1). Verify your Profile path by running the variable "$Profile"' -ForegroundColor Yellow
Write-Host "You may need to create the Folder (WindowsPowershell) and File (Microsoft.Powershell_Profile.ps1) if they doesn't exist already. `n" -ForegroundColor Yellow