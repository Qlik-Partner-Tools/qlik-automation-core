<#
Module:             q-updateHosts
Author:             Clint Carr
Modified by:        -
Modification History:
 - Added Logging
 - Added comments
last updated:       10/09/2017
Intent: Update the HOSTS file on the QMI Scenario so each QMI scenario can communicate with the others 
#>
Write-Log -Message "Starting q-updateHosts"
### Get all entrees from the Hosts file that do not start with QMI
Set-Content -Path "C:\Windows\System32\Drivers\ETC\hosts" -Value (Get-Content "c:\Windows\System32\Drivers\ETC\hosts" | Select-String -Pattern 'qmi' -NotMatch)

### Open the QMI-Machines.json file
$scriptDir += "c:\shared-content\files\hosts\qmi-machines.json"
$config = (Get-Content $scriptDir -raw) | ConvertFrom-Json

### Update the HOSTS file
Write-Log "Updating HOSTS file"
$config.servers | foreach { Write "$($_.ip) $($_.name)" | Out-File "C:\Windows\System32\drivers\etc\hosts" -Append -Encoding "UTF8" }