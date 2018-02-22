<#
Module:             q-user-setup
Author:             Clint Carr
Modified by:        -
Modification History:
 - Changed the creation of Qlik User to be based on Carbon
 - Added Logging
 - Added comments
last updated:       22/02/2018
Intent: Disable Password complexity, create Qlik user and grant remote desktop rights
#>

Write-Log "Starting q-user-setup.ps1"

Trap {
	Write-Log -Message $_.Exception.Message -Severity "Error"
  	Break
}

### Disable Password policy
Write-Log -Message "Disabling Password Complexity"
secedit /export /cfg c:\secpol.cfg  | Out-Null
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg  | Out-Null
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY | Out-Null
rm -force c:\secpol.cfg -confirm:$false  | Out-Null

### Install Carbon PowerShell Module
Write-Log -Message "Installing carbon"
cinst carbon -y | Out-Null

### create Qlik User
$password = ConvertTo-SecureString -String "Qlik1234" -AsPlainText -Force 
Install-User -UserName Qlik -Password $password

### Grant Remote Admin Rights to Qlik User
Write-Log -Message "Granting Qlik account Remote Interactive Logon Right"
Grant-Privilege -Identity $env:COMPUTERNAME\qlik -Privilege SeRemoteInteractiveLogonRight

Write-Log -Message "Adding Qlik user to Remote Desktop Users"
Add-GroupMember -Name 'Remote Desktop Users' -Member $env:COMPUTERNAME\qlik

Write-Log -Message "Adding Qlik user to local Administrators"
Add-GroupMember -Name 'Administrators' -Member $env:COMPUTERNAME\qlik
