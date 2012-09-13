## PowerShell: Script To Configure And Enable Client And Target Machines For PowerShell Remoting (WinRM) ##

<#

Overview: This script is composed of 2 parts.

1. This is to be run on all client machines that will execute remote commands to machines specified for delegation (client role)
2. This is to be run on all target machines that will be enabled to receive remote PowerShell commands (server role)

#>

## 1: Enable PSRemoting on your Client (source machine that will be executing the remote commands) ##

## Add the clients (target machines you want to delegate PSRemoting commands to)
$DelegateMachines = "SERVER1", "SERVER2", "SERVER3" #Change the machine names or use a whole domain like the example below
#$DelegateMachines = "*.DOMAIN.com"

# Configures the Client for WinRM and WSManCredSSP
Write-Host "Configuring PowerShell remoting..."
$winRM = Get-Service -Name winrm
If ($winRM.Status -ne "Running") {Start-Service -Name winrm}
Set-ExecutionPolicy Bypass -Force
Enable-PSRemoting -Force
Enable-WSManCredSSP -Role Client -delegatecomputer $DelegateMachines -Force | Out-Null

#Get out of this PowerShell process
Stop-Process -Id $PID -Force

## 2: Enable PSRemoting on your Target (target machine that will be receiving PSRemoting commands) ##

# Configures the Target for WinRM and WSManCredSSP
Write-Host "Configuring PowerShell remoting..."
$winRM = Get-Service -Name winrm
If ($winRM.Status -ne "Running") {Start-Service -Name winrm}
Set-ExecutionPolicy Bypass -Force
Enable-PSRemoting -Force
Enable-WSManCredSSP -Role Server -Force | Out-Null
# Increase the local memory limit to 1 GB
Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 1024

#Get out of this PowerShell process
Stop-Process -Id $PID -Force



