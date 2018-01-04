<#
Module:             qs-getBinary
Author:             Clint Carr
Modified by:        -
Modification History:
 - Added Logging
 - Added comments
last updated:       10/09/2017
Intent: Download the Qlik Sense binary selected by the end user of QMI.
#>

Write-Log -Message "Starting qs-getBinary.ps1"
$qsVer = (Get-Content C:\shared-content\binaries\qver.json -raw) | ConvertFrom-Json
$qsBinaryURL = (Get-Content C:\shared-content\binaries\qBinaryDownload.json -raw) | ConvertFrom-Json
$bin = "c:\shared-content\binaries"
$binLoc = gci $bin
$binaryName = $qsBinaryURL.qliksense | where { $_.name -eq $qsVer.name}
$path = join-path $bin($($binaryName.name))
$selVer = $qsBinaryURL.qliksense | where { $_.name -eq $qsVer.name }
Write-Log "Qlik Sense version to install: $($selVer.name)"

### Check if binary is present in the path.
if ( -Not (Test-Path $path\Qlik_Sense_setup.exe))
    {
        write-log -Message "Binary not found for $($selVer.name), downloading..."
        if ( -Not (Test-Path $path))
        {
            New-Item -ItemType directory -Path $path -ea Stop | Out-Null 
        }
        $url = $selVer.url
        $fileName = $url.Substring($url.LastIndexOf("/") + 1)
        $dlLoc = join-path $path $fileName
        if ($selVer.name -like "*June 2017 Patch*") {
            if (Test-Path "$bin\Qlik Sense June 2017\Qlik_Sense_setup.exe")
            {
                  Write-Log -Message "June binary found, copying existing binary"
                  cp "$bin\Qlik Sense June 2017\Qlik_Sense_setup.exe" $path\Qlik_Sense_setup.exe
                  Write-Log -Message "Downloading $file from $url to $dlLoc"  -Severity "Warn"
                  (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
            }
            else
            {
                Write-Log -Message "Downloading base binary."
                (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
                $url2 = $selVer.url2
                $fileName = $url2.Substring($url2.LastIndexOf("/") + 1)
                $dlLoc = join-path $path $fileName
                Write-Log -Message "Downloading $file from $url to $dlLoc"  -Severity "Warn"
                (New-Object System.Net.WebClient).DownloadFile($url2, $dlLoc)
            }
        }
        elseif ($selVer.name -like "*September 2017 Patch*") {
            if (Test-Path "$bin\Qlik Sense September 2017\Qlik_Sense_setup.exe")
            {
                  Write-Log -Message "September binary found, copying existing binary"
                  cp "$bin\Qlik Sense September 2017\Qlik_Sense_setup.exe" $path\Qlik_Sense_setup.exe
                  Write-Log -Message "Downloading $filename from $url to $dlLoc"
                  (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
            }
            else
            {
                Write-Log -Message "Downloading base binary." -Severity "Warn"
                (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
                $url2 = $selVer.url2
                $fileName = $url2.Substring($url2.LastIndexOf("/") + 1)
                $dlLoc = join-path $path $fileName
                Write-Log -Message "Downloading $file from $url to $dlLoc"
                (New-Object System.Net.WebClient).DownloadFile($url2, $dlLoc)
            }
        }
        elseif ($selVer.name -like "*November 2017 Patch*") {
            if (Test-Path "$bin\Qlik Sense November 2017\Qlik_Sense_setup.exe")
            {
                  Write-Log -Message "November binary found, copying existing binary"
                  cp "$bin\Qlik Sense November 2017\Qlik_Sense_setup.exe" $path\Qlik_Sense_setup.exe
                  Write-Log -Message "Downloading $filename from $url to $dlLoc"
                  (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
            }
            else
            {
                Write-Log -Message "Downloading base binary." -Severity "Warn"
                (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
                $url2 = $selVer.url2
                $fileName = $url2.Substring($url2.LastIndexOf("/") + 1)
                $dlLoc = join-path $path $fileName
                Write-Log -Message "Downloading $file from $url to $dlLoc"
                (New-Object System.Net.WebClient).DownloadFile($url2, $dlLoc)
            }
        }
        else
        {
            Write-Log -Message "Downloading $file from $url to $dlLoc"  -Severity "Warn"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
        }
        cp $path\*.exe $bin -Force
    }
else {
    Write-log -Message "Binary found for $($selVer.name)"
    if ($selVer.name -like "*June 2017 Patch*") {
        if ( -Not (Test-Path $path\Qlik_Sense_update.exe))
            {
                Write-Log -Message "Missing Patch file, downloading..." -Severity "Warn"
                $url = $selVer.url
                $fileName = $url.Substring($url.LastIndexOf("/") + 1)
                $dlLoc = join-path $path $fileName
                Write-Log -Message "Downloading $file from $url to $dlLoc"
                (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
            }
        }
    elseif ($selVer.name -like "*September 2017 Patch*") {
        if ( -Not (Test-Path $path\Qlik_Sense_update.exe))
            { 
                Write-Log -Message "Missing Patch file, downloading..." -Severity "Warn"
                $url = $selVer.url
                $fileName = $url.Substring($url.LastIndexOf("/") + 1)
                $dlLoc = join-path $path $fileName
                Write-Log -Message "Downloading $file from $url to $dlLoc"
                (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
            }
        }
    elseif ($selVer.name -like "*pre-release*") {
        Write-Log -Message "Pre-release software selected, downloading latest version"
        $url = $selVer.url
        $fileName = $url.Substring($url.LastIndexOf("/") + 1)
        $dlLoc = join-path $path $fileName
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Write-Log -Message "Downloading $file from $url to $dlLoc"
        (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
    }
    Write-Log -Message "Copying binary files from $path to $bin"
    cp $path\*.exe $bin -Force
}
