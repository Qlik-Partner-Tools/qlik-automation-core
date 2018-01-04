<#
Module:             qs-update
Author:             Clint Carr
Modified by:        -
Modification History:
 - Added Logging
 - Added comments
last updated:       10/09/2017
Intent: Installation of Patch for Qlik Sense
#>

If (Test-Path "c:\shared-content\binaries\Qlik_Sense_update.exe")
        {
            Write-Log -Message "Starting qs-update.ps1"
            Write-Log -Message "Installing Update"
            Unblock-File -Path c:\shared-content\binaries\Qlik_Sense_Update.exe
            Invoke-Command -ScriptBlock {Start-Process -FilePath "c:\shared-content\binaries\Qlik_Sense_Update.exe" -ArgumentList "install" -Wait -Passthru } | Out-Null
            
            ### Restarting services
            Write-Log -Message "Restarting Qlik Services"
            Get-Service Qlik* | where {$_.Name -ne 'QlikLoggingService'} | Start-Service
            Get-Service Qlik* | where {$_.Name -eq 'QlikSenseServiceDispatcher'} | Stop-Service
            Get-Service Qlik* | where {$_.Name -eq 'QlikSenseServiceDispatcher'} | Start-Service
            $statusCode = 0
            while ($StatusCode -ne 200)
            {
                write-Log -Message "StatusCode is $($StatusCode)"
                try { $statusCode = (invoke-webrequest  https://$($env:COMPUTERNAME)/qps/user -usebasicParsing).statusCode }
                Catch
                    {
                        write-Log -Message "Server down, waiting 20 seconds" -Severity "Warn"
                        start-Sleep -s 20
                    }
            }
            Write-Log -Message "Qlik Sense Proxy responding on $env:COMPUTERNAME, status code: $statusCode"
        
        ### Restart EA PowerTools Service if exists
        If ( Get-Service QlikEAPowerToolsServiceDispatcher -ErrorAction SilentlyContinue ) {
            Write-Log "Restarting QlikEAPowerToolsServiceDispatcher..."
            Restart-Service QlikEAPowerToolsServiceDispatcher
         }
        }