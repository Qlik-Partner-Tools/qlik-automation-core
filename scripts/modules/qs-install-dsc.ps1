$configData = @{
    AllNodes = @(@{
        NodeName = 'localhost'
        PSDscAllowPlainTextPassword = $true
    })
}

$scenario = (Get-Content c:\vagrant\scenario.json -raw) | ConvertFrom-Json
$config = (Get-Content c:\vagrant\files\qs-cfg.json -raw) | ConvertFrom-Json
$license = (Get-Content c:\shared-content\licenses\qlik-license.json -raw) | ConvertFrom-Json
$qsVer = (Get-Content C:\shared-content\binaries\qver.json -raw) | ConvertFrom-Json
$qsBinaryURL = (Get-Content C:\shared-content\binaries\qBinaryDownload.json -raw) | ConvertFrom-Json
$selVer = $qsBinaryURL.qliksense | where name -eq $qsVer.name
$server = $scenario.config.servers | where name -eq $(hostname)

$password = ConvertTo-SecureString -String $($config.sense.serviceAccountPass) -AsPlainText -Force
$SenseService = New-Object System.Management.Automation.PSCredential("$env:computername\$($config.sense.serviceAccount)", $password)
$QlikAdmin = New-Object System.Management.Automation.PSCredential("$env:computername\qlik", $password)

Configuration QMIConfig
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration, QlikResources, QMI

    Node localhost
    {
        Windows local
        {
            PasswordComplexityEnabled = $false
            Wallpaper                 = 'C:\shared-content\files\wallpaper\Qlik-Wallpaper-dark-01.jpg'
            Hosts                     = $scenario.config.servers
        }
        
        User QlikAdmin
        {
            UserName               = $QlikAdmin.GetNetworkCredential().UserName
            Password               = $QlikAdmin
            FullName               = 'Qlik User'
            PasswordChangeRequired = $false
            PasswordNeverExpires   = $true
            Ensure                 = 'Present'
            DependsOn              = "[Windows]local"
        }

        User SenseService
        {
            UserName                 = $SenseService.GetNetworkCredential().UserName
            Password                 = $SenseService
            FullName                 = 'Qlik Sense Service Account'
            PasswordChangeNotAllowed = $true
            PasswordChangeRequired   = $false
            PasswordNeverExpires     = $true
            Ensure                   = 'Present'
            DependsOn                = "[Windows]local"
        }

        Group Administrators
        {
            GroupName        = 'Administrators'
            MembersToInclude = $QlikAdmin.GetNetworkCredential().UserName, $SenseService.GetNetworkCredential().UserName
            DependsOn        = "[User]QlikAdmin", "[User]SenseService"
        }

        $SenseProductName = $selVer.name
        Binary Sense
        {
            Name     = $SenseProductName
            SetupUri = if($selVer.url2) {$selVer.url2} else {$selVer.url}
            PatchUri = if($selVer.url2) {$selVer.url}
        }

        if ($server.sense.central)
        {
            QlikCentral CentralNode
            {
                SenseService         = $SenseService
                QlikAdmin            = $QlikAdmin
                ProductName          = if($SensePatch){ $SenseProductName, $SensePatch -join ' ' } else { $SenseProductName }
                SetupPath            = $SetupFullPath
                PatchPath            = $PatchFullPath
                License              = $license.sense
                PSDscRunasCredential = $QlikAdmin
                DependsOn            = "[Group]Administrators", "[Binary]Sense"
            }
        
            SenseConfig QMI
            {
                RootImportPaths =
                @(
                    "c:\installation\",
                    "C:\shared-content\"
                )
                UserTokenForEveryone    = $true
                StreamAccessForEveryone = $true
                PSDscRunasCredential    = $QlikAdmin
                DependsOn               = "[QlikCentral]CentralNode"
            }
        } else {
            QlikRimNode $server.name
            {
                SenseService         = $SenseService
                ProductName          = if($SensePatch){ $SenseProductName, $SensePatch -join ' ' } else { $SenseProductName }
                SetupPath            = $SetupFullPath
                PatchPath            = $PatchFullPath
                CentralNode          = ($scenario.config.servers | where { $_.sense.central }).name
                Engine               = [bool]$server.sense.engine
                Printing             = [bool]$server.sense.engine
                Proxy                = [bool]$server.sense.proxy
                Scheduler            = [bool]$server.sense.scheduler
                PSDscRunasCredential = $QlikAdmin
                DependsOn            = "[Group]Administrators", "[Binary]Sense"
            }
        }
    }
}

QMIConfig -ConfigurationData $configData
Start-DscConfiguration -Path .\QMIConfig -Wait -Verbose -Force