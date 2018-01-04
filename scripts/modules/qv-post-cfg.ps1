<#
Module:             qv-post-cfg
Author:             Clint Carr
Modified by:        -
last updated:       10/11/2017

Modification History:
 - Added Comments
 - Added Logging
 - Changed output to NULL

Intent: Perform post installation configuration

Dependencies:
 -
#>
Write-Log -Message "Starting qv-post-cfg.ps1"
Write-Log -Message "Waiting for QlikView Management Service to come up..."

$statusCode = 0
while ($StatusCode -ne 200) {
  write-Log -Message "StatusCode is $StatusCode"
  try { $statusCode = (invoke-webrequest http://localhost:4799/QMS/Service -usebasicParsing).statusCode }
Catch {
    write-Log -Message "Server down, waiting 20 seconds"
    start-Sleep -s 20
    }
}

$license = (Get-Content c:\shared-content\licenses\qlik-license.json -raw) | ConvertFrom-Json
if ( (Test-Path c:\shared-content-plus\licenses\qlik-license.json) ) {
    $license = (Get-Content c:\shared-content-plus\licenses\qlik-license.json -raw) | ConvertFrom-Json
}
Write-Log -Message "Setting QlikView License"
c:\\installation\\post-install\\set-license.exe -serial $license.qlikview.serial -control $license.qlikview.control -name "$($license.qlikview.name)" -organization "$($license.qlikview.organization)"