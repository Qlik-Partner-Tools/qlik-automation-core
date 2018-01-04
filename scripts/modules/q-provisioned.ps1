<#
Module:             q-provisioned.ps1
Author:             Clint Carr
Modified by:        -
Modification History:
 - Added Logging
 - Added comments
last updated:       10/09/2017
Intent: Configure Server for Qlik Sense installation.
#>
if(!(Test-Path c:\qmi\QMIError)){
    Write-Log -Message "Starting q-provisioned.ps1"
    # Execute any PowerShell scripts in ../Shared-Content/Scripts
    Get-ChildItem "c:\shared-content\scripts\*.ps1" -Exclude "provisioned.ps1", "set-windowslicense.ps1" | % { & $_.FullName }
    rm c:\shared-content\binaries\*.exe

    Write-Log -Message "Updating Windows License"
    & "c:\shared-content\scripts\set-windowslicense.ps1"

    Write-Log -Message "Updating Host file"
    & "c:\shared-content\scripts\modules\q-updateHosts.ps1"

    # Display information about the provisioned environment (RUN LAST!)
    & c:\shared-content\scripts\provisioned.ps1

    Write-Log -Message "Server provisioning Complete."
}
else
{
    Write-Log -Message "Provisioning failed. Please check logs in ~/QlikMachineImages/<scenarioName>/QMIProvision.log"
}