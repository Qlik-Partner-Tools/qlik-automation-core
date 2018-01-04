<#
Module:             qv-initial-cfg
Author:             Clint Carr
Modified by:        -
last updated:       10/11/2017

Modification History:
 - Added Comments
 - Added Logging
 - Changed ADSI commands to use Carbon

Intent: Get the selected QlikView binary

Dependencies: 
 - 
#>
Write-Log -Message "Starting qv-initial-cfg.ps1"
[xml]$QlikViewConfig = Get-Content -Path C:\installation\install-qv-cfg.xml

try
{
    Write-Log -Message "Creating Service Account qservice"
    $password = ConvertTo-SecureString -String $($QlikViewConfig.config.serviceAccountPass) -AsPlainText -Force
    New-LocalUser $($QlikViewConfig.config.serviceAccount) -Password $($password) -FullName "QlikView Service Account" -AccountNeverExpires -PasswordNeverExpires -ea Stop | Out-Null
}
catch
{
    Write-Log -Message $_.Exception.Message -Severity 'Error'
}

Write-Log "Adding Service Account to local administators group"
Add-GroupMember -Name 'Administrators' -Member $env:COMPUTERNAME\qservice

Write-Log -Message "Creating QlikView Adminstrators group"
Install-Group -Name 'QlikView Administrators' -Description 'QlikView Administrators' -Members $ENV:ComputerName\qservice,$ENV:ComputerName\vagrant,$ENV:ComputerName\qlik | Out-Null

Write-Log -Message "Creating QlikView Management API group"
Install-Group -Name 'QlikView Management API' -Description 'QlikView Management API' -Members $ENV:ComputerName\qservice,$ENV:ComputerName\vagrant,$ENV:ComputerName\qlik | Out-Null

Write-Log -Message "Opening Firewall ports 80 and 4780"
New-NetFirewallRule -DisplayName "Qlikview" -Direction Inbound -LocalPort 4780, 80 -Protocol TCP -Action Allow | Out-Null

if ($QlikViewConfig.config.webServer -eq "iis")
{
    import-module servermanager | Out-Null
    Write-Log -Message "Installing IIS Server - This may take a couple of minutes"
    # Configure Windows Features
    Install-WindowsFeature Web-Server, Web-Dyn-Compression, Web-Windows-Auth, Web-ASP, Web-ASP-NET45, Web-Mgmt-Tools | Out-Null

    # Remove the Default Web Site and DefaultAppPool
    Remove-Website -Name 'Default Web Site' | Out-Null
    Remove-WebAppPool DefaultAppPool  | Out-Null

    # Create a Web site for QlikView
    Write-Log -Message "Creating directory for Web Site"
    New-Item -ItemType directory -Path C:\inetpub\QlikView | Out-Null
    New-WebSite -Name QlikView -Port 80 -PhysicalPath "$env:systemdrive\inetpub\qlikview"  | Out-Null
}


