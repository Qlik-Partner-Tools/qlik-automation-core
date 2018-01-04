<#
Module:             r-dl-r-packages
Author:             Clint Carr
Modified by:        -
Modification History:
 - Added Logging
 - Added comments
 - Changed batch to Rscript
last updated:       10/11/2017
Intent: Installation of R packages
#>

# install R packages
Write-Log -Message  "Downloading R Packages, dependencies - can take up to five (5) minutes"
c:\AAI\R\bin\x64\Rscript.exe c:\shared-content\scripts\modules\r-install-packages.R