<#
Module:             q-bootstrap
Author:             Clint Carr
Modified by:        - Manuel Romero
Modification History:
 - Added Logging
 - Added comments
last updated:       04/01/2018
Intent: Import QMI and Utils Modules.
#>

New-Item -ItemType directory -Path C:\Windows\System32\WindowsPowerShell\v1.0\Modules\qmiCLI -force | Out-Null
Copy-Item C:\shared-content\scripts\modules\qmiCLI.psm1 C:\Windows\System32\WindowsPowerShell\v1.0\Modules\qmiCLI\qmiCLI.psm1 | Out-Null
Import-Module qmiCLI.psm1 | Out-Null

#Importing Utils module
New-Item -ItemType directory -Path C:\Windows\System32\WindowsPowerShell\v1.0\Modules\qmiUtils -force | Out-Null
Copy-Item C:\shared-content\scripts\modules\qmiUtils.psm1 C:\Windows\System32\WindowsPowerShell\v1.0\Modules\qmiUtils\qmiUtils.psm1 | Out-Null
Import-Module qmiUtils.psm1 | Out-Null