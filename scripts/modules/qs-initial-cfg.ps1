<#
Module:             qs-initial-cfg
Author:             Clint Carr
Modified by:        Adam Haydon
Modification History:
 - Added new installation method for Qlik-Cli (via NuGet)
 - Added Logging
 - Added comments
last updated:       11/06/2017
Intent: Configure Server for Qlik Sense installation.
#>

Write-Log -Message "Starting qs-initial-cfg.ps1"
$scenario = (Get-Content c:\vagrant\scenario.json -raw) | ConvertFrom-Json
$config = (Get-Content c:\vagrant\files\qs-cfg.json -raw) | ConvertFrom-Json
$computer = $scenario.config.servers | where { $_.name -eq $env:computername }
$scenario.config.servers | foreach { Write "$($_.ip) $($_.name)" | Out-File "C:\Windows\System32\drivers\etc\hosts" -Append -Encoding "UTF8" }

Trap {
	Write-Log -Message $_.Exception.Message -Severity "Error"
  	Break
}

# create the qservice account
Write-Log -Message "Creating Service Account qservice"
$password = ConvertTo-SecureString -String $($config.sense.serviceAccountPass) -AsPlainText -Force
New-LocalUser $($config.sense.serviceAccount) -Password $password -FullName "Qlik Sense Service Account" -AccountNeverExpires -PasswordNeverExpires -ea Stop | Out-Null

# create the shared persistence share and directory
foreach ($server in $scenario.config.servers)
{
    if ($server.name -eq $env:COMPUTERNAME -and $server.sense.central -eq $true -and $server.sense.persistence -eq "shared")
    {
        Write-Log -Message "Creating directory c:\QlikShare"
        New-Item -ItemType directory -Path C:\QlikShare -ea Stop | Out-Null
        Write-Log -Message "Creating QlikShare SMB Share"
        New-SmbShare -Name QlikShare -Path C:\QlikShare -FullAccess everyone -ea Stop | Out-Null
    }
}
# download and import Qlik-CLI
Write-Log -Message "Installing NuGet package provider"
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Write-Log -Message "Installing DesiredState module"
Install-Module -Name xPSDesiredStateConfiguration -Confirm:$false -Force  | Out-Null
Write-Log -Message "Installing Networking module"
Install-Module -Name xNetworking -Confirm:$false -Force  | Out-Null
Write-Log -Message "Installing SMB module"
Install-Module -Name xSmbShare -Confirm:$false -Force  | Out-Null
Write-Log -Message "Installing Qlik-CLI module"
Install-Module -Name Qlik-CLI -Confirm:$false -Force  | Out-Null
Write-Log -Message "Installing Qlik-DSC module"
Install-Module -Name QlikResources -Confirm:$false -Force  | Out-Null

cmd.exe /c winrm set winrm/config `@`{MaxEnvelopeSizekb=\`"8192\`"`}  | Out-Null

# add service account to local administrators group
Write-Log -Message "Adding service account to local administrators group."
Add-GroupMember -Name 'Administrators' -Member $env:COMPUTERNAME\qservice -ea Stop  | Out-Null

# open windows firewall
Write-Log "Opening Firewall ports 443/4244, 80/4248; iPortal 3090; Session-Apps 4000; Ticket 5000-6000;"
New-NetFirewallRule -DisplayName "Qlik Sense" -Direction Inbound -LocalPort 443, 4244,4242, 4432, 4444, 5355, 5353, 80, 4248, 3090, 4000, 5555, 5556 -Protocol TCP -Action Allow -ea Stop | Out-Null

