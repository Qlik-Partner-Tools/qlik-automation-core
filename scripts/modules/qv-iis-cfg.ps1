<#
Module:             qv-iis-cfg
Author:             Clint Carr
Modified by:        -
last updated:       10/11/2017

Modification History:
 - Added Comments
 - Added Logging

Intent: Get the selected QlikView binary

Dependencies: 
 - 
#>
Write-Log -Message "Starting qv-iis-cfg.ps1"
Write-Log -Message "Modifying IIS Application pools"

Import-Module WebAdministration | Out-Null
Set-ItemProperty IIS:\Sites\QlikView applicationPool 'QlikView IIS'
Set-ItemProperty IIS:\Sites\QlikView\QlikView applicationPool 'QlikView IIS'
Set-ItemProperty IIS:\Sites\QlikView\QVPlugin applicationPool 'QlikView IIS'
Set-ItemProperty IIS:\Sites\QlikView\Scripts applicationPool 'QlikView IIS'