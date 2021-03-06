<#
Module:             qs-post-cfg
Author:             Clint Carr
Modified by:        -
Modification History:
 - Fixed connect as user logic (qlik-cli change)
 - Added logic to accomodate for Professional/Analyzer or User licenses 
 - Added a loop into the Connect-Qlik statement to remove an abort error
 - Added Logging
 - Added comments
 - Error checking
 - Modified service connection for Qlik Sense from endless loop to a set number of attempts.
 - Added a service restart at the end of the Central Node (seems to resolve an issue with April 2018)
last updated:       10/18/2019
Intent: Configure the Qlik Sense environment with applications and Security Rules.
#>
if(!(Test-Path c:\qmi\QMIError)){
    Write-Log -Message "Starting qs-post-cfg.ps1"
    $scenario = (Get-Content c:\vagrant\scenario.json -raw) | ConvertFrom-Json

    ### Waiting for Qlik Sense installation to complete
    #-----------
    Function restartQse
    {
        Write-Log "Checking Engine Service has started..."
        $qse = get-service QlikSenseEngineService
        write-log -Message "The engine is currently $($qse.Status)"
        if ($qse.Status -eq "Stopped") {Write-Log -Message "Starting Qlik Sense Engine and waiting 120 seconds" -Severity "Warn"; Start-Service QlikSenseEngineService ; Restart-Service QlikSenseServiceDispatcher; start-sleep -s 120}
        write-log -Message "The engine is currently $($qse.Status)"
    }

    Function connQSR
    {
        $i = 1
        $statusCode = 0
        while ($statusCode -ne 200 -and $i -le 10) 
            { 
                try {$statusCode = (Invoke-WebRequest https://$($env:COMPUTERNAME)/qps/user -UseBasicParsing).statusCode }
                catch
                    {
                        $i++
                        write-log -Message "QSR on $env:COMPUTERNAME not responding attempt $i of 10..." -Severity "Warn"
                        start-sleep -s 20 
                    }
            } 
    }

    Function restartServices
    {
        write-log -Message "Restarting Qlik Sense Services on $env:COMPUTERNAME" -Severity "Warn"
        Restart-Service QlikSenseRepositoryDatabase -Force
        Restart-Service QlikLoggingService -Force
        Restart-Service QlikSenseServiceDispatcher -Force
        Restart-Service QlikSenseRepositoryService -Force
        Restart-Service QlikSenseProxyService -Force
        Restart-Service QlikSenseEngineService -Force
        Restart-Service QlikSensePrintingService -Force
        Restart-Service QlikSenseSchedulerService -Force
    }

 Function qlikSenseUserAccess
    {
        $userAccessGroup = (@{name = "License Everyone";} | ConvertTo-Json -Compress -Depth 10)
            $licenseId = Invoke-QlikPost "/qrs/License/UserAccessGroup" $userAccessGroup
            $systemRuleJson = (@{
                name = "Grant Everyone a token";
                category = "License";
                rule = '((user.name like "*"))';
                type = "Custom";
                resourceFilter = "License.UserAccessGroup_" + $licenseId.id;
                actions = 1;
                ruleContext = "QlikSenseOnly";
                disabled = $false;
                comment = "Rule to set up automatic user access";} | ConvertTo-Json -Compress -Depth 10)
            Write-Log -Message "Adding user license rule to grant Everyone Tokens."
            try
            {
                Invoke-QlikPost "/qrs/SystemRule" $systemRuleJson | Out-Null
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
    }

    Function qlikSenseProfessionalAccess
    {
           $professionalAccessGroup = (@{name = "License Everyone";} | ConvertTo-Json -Compress -Depth 10)
            $licenseId = Invoke-QlikPost "/qrs/License/ProfessionalAccessGroup" $professionalAccessGroup
            $systemRuleJson = (@{
                name = "Grant Everyone Professional Access";
                category = "License";
                rule = '((user.name like "*"))';
                type = "Custom";
                resourceFilter = "License.ProfessionalAccessGroup_" + $licenseId.id;
                actions = 1;
                ruleContext = "QlikSenseOnly";
                disabled = $false;
                comment = "Rule to set up automatic user access";} | ConvertTo-Json -Compress -Depth 10)
            Write-Log -Message "Adding user license rule to grant Everyone access as Professional."
            try
            {
                Invoke-QlikPost "/qrs/SystemRule" $systemRuleJson | Out-Null
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
    }

    #-----------
    write-log -Message "Waiting three minutes for Qlik Sense installation to complete"
    start-sleep -s 180

    foreach ($server in $scenario.config.servers)
    {
        if ($server.sense.central -eq $true -and $server.name -eq $ENV:computername)
        {
            ### wait for Qlik Sense Proxy service to respond with an HTTP 200 status before proceeding
            connQSR
            $statusCode = (Invoke-WebRequest https://$($env:COMPUTERNAME)/qps/user -UseBasicParsing).statusCode
            if ($statusCode -ne 200)
                { 
                    Write-Log -Message "Waiting 25 seconds before next pass" -Severity "Warn"
                    restartServices
                    Write-Log -Message "Waiting 45 seconds for Services to ensure they are ready" -Severity "Warn"
                    start-sleep -s 45
                    connQSR
                }
            
            $statusCode = (Invoke-WebRequest https://$($env:COMPUTERNAME)/qps/user -UseBasicParsing).statusCode
            if ($statusCode -ne 200)
                { 
                    Write-Log -Message "Provisioning failed" -Severity "Error"
                    Exit 
                }
            Write-Log -Message "Qlik Sense Proxy responding on $env:COMPUTERNAME, status code: $statusCode"
            Write-Log -Message "Connecting to Qlik Sense Repository Service on $env:COMPUTERNAME"
            
            restartQse

            ### Connect to the Qlik Sense Repository Service with Qlik-Cli
            do {write-log -Message "Connecting to Qlik Sense Repository"; start-sleep 15} 
            While( (Connect-Qlik $($env:COMPUTERNAME) -TrustAllCerts -UseDefaultCredentials -ErrorAction SilentlyContinue).length -eq 0 )
            
            $license = (Get-Content c:\shared-content\licenses\qlik-license.json -raw) | ConvertFrom-Json
            if ( (Test-Path c:\shared-content-plus\licenses\qlik-license.json) ) {
                $license = (Get-Content c:\shared-content-plus\licenses\qlik-license.json -raw) | ConvertFrom-Json
            }
                if ($server.sense.license -eq "token" )
                    {
                        $license = (Get-Content c:\shared-content\licenses\qlik-license.json -raw) | ConvertFrom-Json
                        if ( (Test-Path c:\shared-content-plus\licenses\qlik-license.json) ) 
                        {
                            $license = (Get-Content c:\shared-content-plus\licenses\qlik-license.json -raw) | ConvertFrom-Json
                        }

                        Write-Log -Message "Setting license: $($license.sense.serial)"
                        try
                        {
                            Set-QlikLicense -serial $license.sense.serial -control $license.sense.control -name "$($license.sense.name)" -organization "$($license.sense.organization)" -lef "$($license.sense.lef)" | Out-Null
                        }
                        catch
                        {
                            Write-Log -Message $_.Exception.Message -Severity "Error"
                        }
                        qlikSenseUserAccess
                    }
                else {
                        Write-Log -Message "Setting license: $($license.sensepa.serial)"
                        try
                        {
                            Set-QlikLicense -serial $license.sensepa.serial -control $license.sensepa.control -name "$($license.sensepa.name)" -organization "$($license.sensepa.organization)" -lef "$($license.sensepa.lef)" | Out-Null
                        }
                        catch
                        {
                            Write-Log -Message $_.Exception.Message -Severity "Error"
                        }
                    qlikSenseProfessionalAccess
                }

                
            ### Add the Qlik local user to Qlik Sense
            $json = (@{userId = "qlik";
                        userDirectory = $env:COMPUTERNAME;
                        name = "qlik";
                    } | ConvertTo-Json -Compress -Depth 10 )
            Write-Log -Message "Adding Qlik user."
            try
            {
                Invoke-QlikPost "/qrs/user" $json | Out-Null
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            ### Grant Qlik user Root Admin
            Write-Log "Granting Root Admin role to Qlik user"
            try
            {
                Update-QlikUser -id $(Get-QlikUser -full -filter "name eq 'qlik'").id -roles "RootAdmin" | Out-Null
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            restartQse
            ### Import scenario extensions
            Write-Log -Message "Importing extensions from c:\installation\extensions"
            If (Test-Path "C:\installation\extensions\") {
                gci c:\\installation\\extensions\\*.zip | foreach {
                    try
                    {
                        Write-Log -Message "Importing $_";
                        Import-QlikExtension -ExtensionPath $_.FullName | Out-Null
                    }
                    catch
                    {
                        Write-Log -Message $_.Exception.Message -Severity "Error"
                    }
            }
            }

            ### Import shared-content extensions
            Write-Log -Message "Importing extensions from c:\shared-content\extensions"
            If (Test-Path "C:\shared-content\extensions\") {
                gci c:\\shared-content\\extensions\\*.zip | foreach {
                    try
                    {
                        Write-Log -Message "Importing $_";
                        Import-QlikExtension -ExtensionPath $_.FullName | Out-Null
                    }
                    catch
                    {
                        Write-Log -Message $_.Exception.Message -Severity "Error"
                    }
            }
            }

            ### Import scenario applications
            Write-Log -Message "Connecting as user Qlik to QRS"
            try
            {
                $cert = "CN=$env:COMPUTERNAME-ca"
                gci cert:\CurrentUser\My | where {$_.issuer -eq $cert} | Connect-Qlik -username "$env:COMPUTERNAME\qlik" | Out-Null
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }

            Write-Log -Message "Importing applications from c:\installation\applications"
            If (Test-Path "C:\installation\apps\") {
                gci c:\\installation\\apps\\*.qvf | foreach {
                    try
                    {
                        Write-Log -Message "Importing $_";
                        Import-QlikApp -name $_.BaseName -file $_.FullName -upload | Out-Null
                    }
                    catch
                    {
                        Write-Log -Message $_.Exception.Message -Severity "Error"
                    }
                }
            }

            ### Import shared-content applications
            Write-Log -Message "Importing applications from c:\shared-content\applications"
            If (Test-Path "C:\shared-content\apps\") {
                gci c:\\shared-content\\apps\\*.qvf | foreach {
                    try
                    {
                        Write-Log -Message "Importing $($_)";
                        Import-QlikApp -name $_.BaseName -file $_.FullName -upload | Out-Null
                    }
                    catch
                    {
                        Write-Log -Message $_.Exception.Message -Severity "Error"
                    }
                }
            }
            restartQse
            $apps = gci c:\shared-content\apps\ -Directory
            foreach ($subDirectory in $apps)
            {
                # $encodeDirectory = [System.Web.HttpUtility]::UrlEncode($subDirectory);
                $streams = $(Get-QlikStream -filter "name eq '$($subDirectory)'").name
                if ($streams -ne $subDirectory)
                    {
                        Write-Log -Message "Creating $subDirectory stream"
                        New-QlikStream $subDirectory | Out-Null;
                        $streamId = $(Get-QlikStream -filter "name eq '$($subDirectory)'").id
                        $systemRuleJson = (@{
                            name = "Grant everyone access to $subDirectory";
                            category = "Security";
                            rule = '((user.name like "*"))';
                            type = "Custom";
                            resourceFilter = "Stream_$streamId";
                            actions = 34;
                            ruleContext = "QlikSenseOnly";
                            disabled = $false;
                            comment = "Stream access";} | ConvertTo-Json -Compress -Depth 10)
                        Write-Log -Message "Creating $subDirectory System Rule"
                        Invoke-QlikPost "/qrs/systemrule" $systemRuleJson | Out-Null
                    }
            $files = gci C:\shared-content\apps\$subDirectory\*.qvf -File
            foreach ($file in $files)
                {
                    $streamId = $(Get-QlikStream -filter "name eq '$($subDirectory)'").id
                    # $encode = [System.Web.HttpUtility]::UrlEncode($file.BaseName)
                    Write-Log -Message "Importing $($file)";
                    Import-QlikApp -name $file.BaseName -file $file.FullName -upload  | Out-Null;
                    Write-Log -Message "Publishing $($file.BaseName) to $($subDirectory)";
                    publish-qlikapp -id $(get-qlikapp -filter "name eq '$($file.BaseName)'").id -stream $streamId -name $file.BaseName  | Out-Null
                }
            }
            ### Updating White List
            Write-Log -Message "Adding Websocket Origin White List"
            try
            {
                $serverIp=$server.ip
                if ( Test-Path variable:\serverIp ) {
                    Update-QlikVirtualProxy -id $(Get-QlikVirtualProxy -filter "description eq 'Central Proxy (Default)'").id -websocketCrossOriginWhiteList $server.ip,"qmi-nginx"  | Out-Null
                } else {
                    Update-QlikVirtualProxy -id $(Get-QlikVirtualProxy -filter "description eq 'Central Proxy (Default)'").id -websocketCrossOriginWhiteList "qmi-nginx"  | Out-Null
                }
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            Start-Sleep -s 10

            ### Enabling HTTP
            Write-Log -Message "Enabling HTTP access on Central Node proxy"
            try
            {
                Get-QlikProxy -filter "serverNodeConfiguration.Name eq 'Central'" | Update-QlikProxy -AllowHttp 1  | Out-Null
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            ### Creating qsgrep function
            IF (-Not(Test-Path "c:\users\vagrant\Documents\WindowsPowerShell"))
            {
                New-Item "C:\Users\vagrant\Documents\WindowsPowerShell\" -ItemType Directory  | Out-Null
            }
            echo 'function qsgrep($pattern,$service,$ext="txt") {Get-ChildItem "C:\ProgramData\Qlik\Sense\Log\$service" -Filter *.$ext -Recurse | Select-String $pattern}' > "C:\Users\vagrant\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

        }
        ### Rim Node
        elseif ($server.sense.central -eq $false -and $server.name -eq $ENV:computername)
        {
            Write-Log -Message "Connecting to the Qlik Sense Repository Service"
            $svc = Get-Service -Name QlikSenseRepositoryService
            while ($svc.Status -ne "Running")
            {
                Start-Sleep -seconds 10
                $svc = Get-Service -Name QlikSenseRepositoryService
            }
            Write-Log -Message "Waiting 90 seconds before attempting to connect to Central Node"
            Start-Sleep 90

            ### Connecting to the Central Node
            Write-Log -Message "Connecting to the central name $($scenario.config.servers[0].name)"
            try
            {
                Connect-Qlik $scenario.config.servers[0].name -TrustAllCerts | Out-Null
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            ### Registering Rim Node in QMIC
            $hostname = $env:computername
            Write-Log -Message "Registering Rim Node"
            try
            {
                Register-QlikNode -hostname $hostname -name "Rim" -nodePurpose 2 -engineEnabled -proxyEnabled
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            Start-Sleep -s 10

            ### Updating Virtual Proxys
            Write-Log -Message "Updating Virtual Proxy on both Central and Rim node to support load balancing."
            try
            {
                Update-QlikVirtualProxy -id $(Get-QlikVirtualProxy -filter "description eq 'Rim Proxy (Default)'").id -loadBalancingServerNodes $(Get-QlikNode -filter "name eq 'Rim'").id, $(Get-QlikNode -filter "name eq 'Central'").id
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            try
            {
                Update-QlikVirtualProxy -id $(Get-QlikVirtualProxy -filter "description eq 'Central Proxy (Default)'").id -loadBalancingServerNodes $(Get-QlikNode -filter "name eq 'Rim'").id, $(Get-QlikNode -filter "name eq 'Central'").id
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            ### Enabling HTTP on Rim Node
            Write-Log -Message "Updating Rim Node Proxy to support HTTP"
            try
            {
                Get-QlikProxy -filter "serverNodeConfiguration.Name eq 'Rim'" | Update-QlikProxy -AllowHttp 1
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            ### Set the node type to Both
            Write-Log -Message "Setting Node purpose to Both Dev and Production"
            try
            {
                update-Qliknode -id $(Get-QlikNode -filter "name eq 'Rim'").id -nodePurpose Both
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            # update whitelist for multinode-not used for others
            try
            {
                $serverIp=$server.ip
                if ( Test-Path variable:\serverIp ) {
                    Update-QlikVirtualProxy -id $(Get-QlikVirtualProxy -filter "description eq 'Rim Proxy (Default)'").id -websocketCrossOriginWhiteList $server.ip,"qmi-nginx"
                } else {
                    Update-QlikVirtualProxy -id $(Get-QlikVirtualProxy -filter "description eq 'Rim Proxy (Default)'").id -websocketCrossOriginWhiteList "qmi-nginx"
                }
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            ### Update Windows Authentication Pattern
            Write-Log -Message "Updating Windows Authentication Pattern to ensure login page is displayed."
            try
            {
                update-QlikVirtualProxy -id $(Get-QlikVirtualProxy -filter "description eq 'Rim Proxy (Default)'").id -windowsAuthenticationEnabledDevicePattern qmi
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
            try
            {
                update-QlikVirtualProxy -id $(Get-QlikVirtualProxy -filter "description eq 'Central Proxy (Default)'").id -windowsAuthenticationEnabledDevicePattern qmi
            }
            catch
            {
                Write-Log -Message $_.Exception.Message -Severity "Error"
            }
        }
    }
}