<#
Module:             qs-installR
Author:             Clint Carr
Modified by:        -
Modification History:
 - Changed install of R to use chocolatey
 - Changed install of RStudio to use chocolatey
 - Added Logging
 - Added comments
 - Updated Extensions to the latest version
last updated:       14/11/2017
Intent: Installation of R, RStudio, RServe, and functions interesting to demonstrate Qlik Sense integration with R
#>

if(!(Test-Path c:\qmi\QMIError)){
    Write-Log -Message "Starting qs-installR"
    # download popular extensions for showcasing R
    New-Item -ItemType directory -Path $env:USERPROFILE\Downloads\Extensions -force | Out-Null

    #AdvancedAnalyticsToolBox
    Write-Log -Message "Downloading AdvancedAnalyticsToolBox"
    (New-Object System.Net.WebClient).DownloadFile("https://github.com/mhamano/advanced-analytics-toolbox/releases/download/v1.4.0/advanced-analytics-toolbox-1.4.0.zip", "$env:USERPROFILE\Downloads\extensions\advanced-analytics-toolbox-1.4.0.zip")
    ##AAIExpressionBuilder
    Write-Log -Message "Downloading AAIExpressionBuilder"
    (New-Object System.Net.WebClient).DownloadFile("https://github.com/AnalyticsEarth/AAIExpressionBuilder/releases/download/v1.0.1/AAIExpressionBuilder.zip", "$env:USERPROFILE\Downloads\extensions\AAIExpressionBuilder.zip")

    Start-Sleep 5
    Write-Log "Connecting to the Qlik Sense Repository on $env:COMPUTERNAME"
    Connect-Qlik $env:COMPUTERNAME -UseDefaultCredentials | Out-Null
    If (Test-Path "$env:USERPROFILE\downloads\extensions\") {
                Write-Log -Message "Importing extensions"
                gci $env:USERPROFILE\\downloads\\extensions\\*.zip | foreach { Write-Log -Message "Importing extension $($_.Fullname)"; Import-QlikExtension -ExtensionPath $_.FullName | Out-Null}
            }

    # create analytic connection in QMC
    Write-Log -Message "Creating Analytic Connection"

    $json = (@{
    name = "R";
    host = "localhost";
    port = 50051;
    reconnectTimeout= 10;
    requestTimeout= 20;
    } | ConvertTo-Json -Compress -Depth 10)
    Write-Log -Message "Creating R Analytic Connection in the QMC"
    invoke-qlikpost "/qrs/AnalyticConnection" $json  | Out-Null

    Write-Log -Message "Install R"
    cinst r.project -ia "/dir=c:\aai\r" | Out-Null

    Write-Log -Message "Installing R Studio"
    cinst r.studio -ia "/D=c:\aai\Rstudio" | Out-Null

    ### Start a new powershell window and download and install packages
    # & C:\shared-content\scripts\modules\r-dl-r-packages.ps1
    Write-Log -Message  "Downloading R Packages, dependencies - can take up to five (5) minutes"
    c:\AAI\R\bin\x64\Rscript.exe c:\shared-content\scripts\modules\r-install-packages.R

    ### Wait until RServe is installed
    while (!(Test-Path "C:\AAI\R\library\Rserve\libs\x64\RServe.exe")) {
        Write-Log -Message "Wait until R packages are installed"
        Start-Sleep -s 20
    }
    Write-Log -Message "R packages have been installed!"

    ### Copy rserve executables to r folder
    Write-Log -Message "Copying RServe to c:\AAI\R\bin\x64"
    Get-ChildItem -path 'c:\AAI\R\library\Rserve\libs\x64\' -Recurse | Copy-Item -Destination 'C:\AAI\R\bin\x64\'

    ### Copy shortcuts to desktop
    Write-Log -Message  "Copying RServe and SSE to RServer shortcuts to desktop."
    Get-ChildItem -path 'c:\vagrant\files\' -Filter *.lnk -Recurse | Copy-Item -Destination 'c:\users\vagrant\desktop'

    Write-Log -Message  "Copying Restart Service batch file to desktop"
    Copy-Item 'C:\vagrant\files\restart-qlik-sense.bat' 'C:\Users\vagrant\Desktop\restart-qlik-sense.bat'

    # start a new powershell and start RServe
    Write-Log -Message "Starting RServe"
    start powershell {c:\shared-content\scripts\modules\r-start-rserve.ps1}

    start-sleep -s 10

    # start SSE plugin
    Write-Log -Message "Starting SSEtoRServe"
    start powershell {C:\vagrant\files\sse-r-plugin-1.0.0-qlik-oss\SSEtoRserve.exe}

    Write-Log "Restarting Qlik Sense Engine Service"
    net stop QlikSenseEngineService | Out-Null
    start-sleep -s 10
    net start QlikSenseEngineService | Out-Null
}