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

$scenario = (Get-Content c:\vagrant\scenario.json -raw) | ConvertFrom-Json

$statusCode = 0
while ($StatusCode -ne 200) {
  write-Log -Message "StatusCode is $StatusCode"
  try { $statusCode = (invoke-webrequest http://localhost:4799/QMS/Service -usebasicParsing).statusCode }
Catch {
    write-Log -Message "Server down, waiting 20 seconds"
    start-Sleep -s 20
    }
}
$qsVer = (Get-Content C:\shared-content\binaries\qver.json -raw) | ConvertFrom-Json

$license = (Get-Content c:\shared-content\licenses\qlik-license.json -raw) | ConvertFrom-Json
if ( (Test-Path c:\shared-content-plus\licenses\qlik-license.json) ) {
    $license = (Get-Content c:\shared-content-plus\licenses\qlik-license.json -raw) | ConvertFrom-Json
}
# Write-Log -Message "Setting QlikView License"
# c:\\installation\\post-install\\set-license.exe -serial $license.qlikview.serial -control $license.qlikview.control -name "$($license.qlikview.name)" -organization "$($license.qlikview.organization)"

# we don't have any multinode QV scenarios so assuming it's the first entry..
if ($scenario.config.servers[0].license -eq "signed" -and $qsVer.name -like "QlikView*202*")
# only use signed license from 2020 onward
{
    Write-Log -Message "Setting license: Signed"
    c:\\shared-content\\scripts\\qv-set-license\\qv-set-license.exe $Env:Computername SIGNED $license.qliksigned.key  

}
else {
  Write-Log -Message "Setting license: Lef"
  #old
  # c:\\installation\\post-install\\set-license.exe -serial $license.qlikview.serial -control $license.qlikview.control -name "$($license.qlikview.name)" -organization "$($license.qlikview.organization)"
  c:\\shared-content\\scripts\\qv-set-license\\qv-set-license.exe $Env:Computername LEF QVS $license.qlikview.serial $license.qlikview.control "$($license.qlikview.name)" "$($license.qlikview.organization)"
  Restart-Service QlikviewServer
  start-Sleep -s 20
  c:\\shared-content\\scripts\\qv-set-license\\qv-set-license.exe $Env:Computername LEF PUBLISHER $license.qlikview.serial $license.qlikview.control "$($license.qlikview.name)" "$($license.qlikview.organization)"
  Restart-Service QlikviewDistributionService
  start-Sleep -s 20

}

Write-Log -Message "Restarting QVS so it accepts license"
#Restart-Service QlikviewServer
#Restart-Service QlikviewDistributionService
Restart-Service QlikviewManagementService


#copy published documents to source documents
Write-Log -Message "Copying sample documents to SourceDocuments"
Copy-Item c:\\programdata\\qliktech\\Documents\\*.qvw c:\\programdata\\qliktech\\SourceDocuments\\ -Force
