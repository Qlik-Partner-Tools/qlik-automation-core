Write-Log -Message "Getting Nuget"
Get-PackageProvider -Name NuGet -ForceBootstrap
Write-Log -Message "Getting DSc and Qlik-CLI Modules"
Install-Module -Name xPSDesiredStateConfiguration -Force
Install-Module -Name xNetworking -Force
Install-Module -Name xSmbShare -Force
Install-Module -Name Qlik-Cli -Force
Install-Module -Name QlikResources -Force

Write-Log -Message "Copying DSc Configuration"
Copy-Item 'C:\shared-content\scripts\modules\DSC\*' "$env:ProgramFiles\WindowsPowerShell\Modules\" -Recurse -Force