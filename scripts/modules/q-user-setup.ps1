<#
Module:             q-user-setup
Author:             Clint Carr
Modified by:        -
Modification History:
 - Deleted disable IPv6
 - Changed the creation of Qlik User to be based on Carbon
 - Added Logging
 - Added comments
last updated:       27/07/2018
Intent: Disable Password complexity, create Qlik user and grant remote desktop rights
#>

Write-Log "Starting q-user-setup.ps1"

Trap {
	Write-Log -Message $_.Exception.Message -Severity "Error"
  	Break
}

# The following should be in the base box..
Write-Log -Message "Setting TLS 1.2 for Powershell"
$ProfileFile = "${PsHome}\Profile.ps1"
if (! (Test-Path $ProfileFile)) {
New-Item -Path $ProfileFile -Type file -Force
}
''                                                                                | Out-File -FilePath $ProfileFile -Encoding ascii -Append
'# It is 2018, SSL3 and TLS 1.0 are no good anymore'                              | Out-File -FilePath $ProfileFile -Encoding ascii -Append
'[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12' | Out-File -FilePath $ProfileFile -Encoding ascii -Append
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

### Disable Password policy
Write-Log -Message "Disabling Password Complexity"
secedit /export /cfg c:\secpol.cfg  | Out-Null
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg  | Out-Null
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY | Out-Null
rm -force c:\secpol.cfg -confirm:$false  | Out-Null

### Install Carbon PowerShell Module
Write-Log -Message "Installing carbon"
cinst carbon -y | Out-Null
import-module "Carbon"

### create Qlik User
Install-User -UserName Qlik -Password Qlik1234

### Grant Remote Admin Rights to Qlik User
Write-Log -Message "Granting Qlik account Remote Interactive Logon Right"
Grant-Privilege -Identity $env:COMPUTERNAME\qlik -Privilege SeRemoteInteractiveLogonRight

Write-Log -Message "Adding Qlik user to Remote Desktop Users"
Add-GroupMember -Name 'Remote Desktop Users' -Member $env:COMPUTERNAME\qlik

Write-Log -Message "Adding Qlik user to local Administrators"
Add-GroupMember -Name 'Administrators' -Member $env:COMPUTERNAME\qlik

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control"
Set-ItemProperty $regPath -Name "ServicesPipeTimeout" -Type DWord -Value 180000
