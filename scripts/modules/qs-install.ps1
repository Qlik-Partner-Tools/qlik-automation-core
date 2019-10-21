<#
Module:             qs-install
Author:             Clint Carr
Modified by:        -
Modification History:
 - Added November Techb preview
 - Bug in extension pack code
 - Added functionality to support the certified visualization bundle
 - Added functionality to support the certified extension bundle
 - Added Logging
 - Added comments
 - Sent output to Null
 - Changed installation to an Invoke-Command script block
last updated:       22/10/2019
Intent: Install the selected version of Qlik Sense
#>

# These versions do not have the dashboardbundle as an installer option
$qsVersions = @("Qlik Sense April 2019 pre-release","Qlik Sense September 2018","Qlik Sense June 2018 Patch 1","Qlik Sense June 2018","Qlik Sense April 2018 Patch 1",
            "Qlik Sense April 2018","Qlik Sense February 2018","Qlik Sense November 2017 Patch 2","Qlik Sense November 2017 Patch 1", 
            "Qlik Sense November 2017","Qlik Sense September 2017 Patch 1","Qlik Sense September 2017","Qlik Sense June 2017 Patch 3",
            "Qlik Sense June 2017 Patch 2","Qlik Sense June 2017 Patch 1","Qlik Sense June 2017","Qlik Sense 3.2 SR5","Qlik Sense 3.2 SR4",
            "Qlik Sense 3.2 SR3","Qlik Sense 3.2 SR2","Qlik Sense September 2018 pre-release")

# This version only has the dashboard bundle
$qsVersionDashOnly = @("Qlik Sense November 2018","Qlik Sense November 2018 Patch 1","Qlik Sense November 2018 Patch 2")

$qsVersionBoth = @("Qlik Sense April 2019", "Qlik Sense June 2019 pre-release", "Qlik Sense June 2019", "Qlik Sense September 2019", "Qlik Sense November 2019 pre-release", "Qlik Sense November 2019" )

$qsVer = (Get-Content C:\shared-content\binaries\qver.json -raw) | ConvertFrom-Json

Write-Log -Message "Starting qs-install.ps1"
$scenario = (Get-Content c:\vagrant\scenario.json -raw) | ConvertFrom-Json
$config = (Get-Content c:\vagrant\files\qs-cfg.json -raw) | ConvertFrom-Json
foreach ($server in $scenario.config.servers)
{
    If ($server.sense.persistence -eq "shared" -and $server.sense.central -eq $true -and $server.name -eq $ENV:computername )
    {
        Write-Log -Message "Installing Shared Persistence"
        If (Test-Path "C:\installation\Qlik_Sense_setup.exe")
        {
            Write-Log -Message "Installing Qlik Sense Server from c:\installation"
            Unblock-File -Path C:\installation\Qlik_Sense_setup.exe
            Invoke-Command -ScriptBlock {Start-Process -FilePath "c:\installation\Qlik_Sense_setup.exe" -ArgumentList "-s -log c:\installation\logqlik.txt dbpassword=$($config.sense.PostgresAccountPass) hostname=$($env:COMPUTERNAME) userwithdomain=$($env:computername)\$($config.sense.serviceAccount) password=$($config.sense.serviceAccountPass)  spc=c:\installation\sp_config.xml" -Wait -PassThru}  | Out-Null
        }
        elseIf (Test-Path "c:\shared-content\binaries\Qlik_Sense_setup.exe")
        {
            Write-Log -Message "Installing Qlik Sense Server from c:\shared-content\binaries"
            Unblock-File -Path C:\shared-content\binaries\Qlik_Sense_setup.exe
            if ($qsVersionDashOnly -contains $qsVer.name)
                {
                    Write-log -Message "Installing with Dashboard bundle"
                    Invoke-Command -ScriptBlock {Start-Process -FilePath "c:\shared-content\binaries\Qlik_Sense_setup.exe" -ArgumentList "-s -log c:\installation\logqlik.txt dbpassword=$($config.sense.PostgresAccountPass) hostname=$($env:COMPUTERNAME) userwithdomain=$($env:computername)\$($config.sense.serviceAccount) password=$($config.sense.serviceAccountPass) dashboardbundle=1 spc=c:\installation\sp_config.xml" -Wait -PassThru} | Out-Null
                }
                elseif ($qsVersions -notcontains $qsVer.name -and $qsVersionDashOnly -notcontains $qsVer.name -and $qsVersionBoth -notcontains $qsVer.name)
                {
                    Write-log -Message "Installing with Dashboard Bundle and Extension Bundle"
                    Invoke-Command -ScriptBlock {Start-Process -FilePath "c:\shared-content\binaries\Qlik_Sense_setup.exe" -ArgumentList "-s -log c:\installation\logqlik.txt dbpassword=$($config.sense.PostgresAccountPass) hostname=$($env:COMPUTERNAME) userwithdomain=$($env:computername)\$($config.sense.serviceAccount) password=$($config.sense.serviceAccountPass) dashboardbundle=1 visualizationbundle=1 spc=c:\installation\sp_config.xml" -Wait -PassThru} | Out-Null
                }
                elseif ($qsVersionBoth -contains $qsVer.name)
                {
                Write-log -Message "Installing with Dashboard Bundle and Extension Bundle"
                Invoke-Command -ScriptBlock {Start-Process -FilePath "c:\shared-content\binaries\Qlik_Sense_setup.exe" -ArgumentList "-s -log c:\installation\logqlik.txt dbpassword=$($config.sense.PostgresAccountPass) hostname=$($env:COMPUTERNAME) userwithdomain=$($env:computername)\$($config.sense.serviceAccount) password=$($config.sense.serviceAccountPass) bundleinstall=dashboard,visualization spc=c:\installation\sp_config.xml" -Wait -PassThru} | Out-Null
                }
            else
                {
                    Invoke-Command -ScriptBlock {Start-Process -FilePath "c:\shared-content\binaries\Qlik_Sense_setup.exe" -ArgumentList "-s -log c:\installation\logqlik.txt dbpassword=$($config.sense.PostgresAccountPass) hostname=$($env:COMPUTERNAME) userwithdomain=$($env:computername)\$($config.sense.serviceAccount) password=$($config.sense.serviceAccountPass) spc=c:\installation\sp_config.xml" -Wait -PassThru} | Out-Null
                }
        }
        else
        {
            Write-Log -Message "No Binary found. Stopping provision" -Severity "Error"
            New-Item c:\qmi\QMIError -Force -ItemType File | Out-Null
            Exit
        }
    }
    elseif ($server.sense.persistence -eq "sync" -and $server.sense.central -eq $true -and $server.name -eq $ENV:computername )
    {
        Write-Log -Message "Installing Synchronised Persistence"
        Write-Log -Message "Note: Will not function with June and later releases!"
        If (Test-Path "C:\shared-content\binaries\Qlik_Sense_setup.exe")
        {
            Write-Log -Message "Installing Qlik Sense Server from c:\shared-content\binaries"
            Unblock-File -Path C:\shared-content\binaries\Qlik_Sense_setup.exe
            Invoke-Command -ScriptBlock {Start-Process -FilePath "c:\shared-content\binaries\Qlik_Sense_setup.exe" -ArgumentList "-s -log c:\installation\logqlik.txt dbpassword=$($config.sense.PostgresAccountPass) hostname=$($env:COMPUTERNAME) userwithdomain=$($env:computername)\$($config.sense.serviceAccount) password=$($config.sense.serviceAccountPass)" -Wait -PassThru} | Out-Null
        }
        else
        {
            Write-Log -Message "No Binary found. Stopping provision" -Severity "Error"
            New-Item c:\qmi\QMIError -Force -ItemType File | Out-Null
            Exit
        }
    }
    elseif ($server.sense.central -eq $false -and $server.sense.persistence -eq "shared" -and $server.name -eq $env:computername)
    {
            Write-Log -Message "Installing RIM Node Shared Persistence"
            If (Test-Path "C:\installation\Qlik_Sense_setup.exe")
            {
                Write-Log -Message "Installing Qlik Sense Server from c:\installation"
                Unblock-File -Path C:\installation\Qlik_Sense_setup.exe
                Invoke-Command -ScriptBlock {Start-Process -FilePath "c:\installation\Qlik_Sense_setup.exe" -ArgumentList "-s -log c:\installation\logqlik.txt rimnode=1 dbpassword=$($config.sense.PostgresAccountPass) hostname=$($env:COMPUTERNAME) userwithdomain=$($env:computername)\$($config.sense.serviceAccount) password=$($config.sense.serviceAccountPass)  spc=c:\installation\sp_config_rim.xml" -Wait -PassThru} | Out-Null
            }
            elseIf (Test-Path "c:\shared-content\binaries\Qlik_Sense_setup.exe")
            {
                Write-Log -Message "Installing Qlik Sense Server from c:\shared-content\binaries"
                Unblock-File -Path C:\shared-content\binaries\Qlik_Sense_setup.exe
                Invoke-Command -ScriptBlock {Start-Process -FilePath "c:\shared-content\binaries\Qlik_Sense_setup.exe" -ArgumentList "-s -log c:\installation\logqlik.txt rimnode=1 dbpassword=$($config.sense.PostgresAccountPass) hostname=$($env:COMPUTERNAME) userwithdomain=$($env:computername)\$($config.sense.serviceAccount) password=$($config.sense.serviceAccountPass)  spc=c:\installation\sp_config_rim.xml" -Wait -PassThru}  | Out-Null
            }
            else
            {
                Write-Log -Message "No Binary found. Stopping provision" -Severity "Error"
                New-Item c:\qmi\QMIError -Force -ItemType File | Out-Null
                Exit
            }
    }
}
