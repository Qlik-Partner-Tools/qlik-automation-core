<#
Module:             qv-getBinary
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
Write-Log -Message "Starting qv-getBinary.ps1"
$defBinary = (Get-Content c:\vagrant\scenario.json -raw | ConvertFrom-Json)
$qvVer = (Get-Content C:\shared-content\binaries\qver.json -raw) | ConvertFrom-Json
if ($defBinary.$("qlik-default-binary") -ne $null){
    $qvVer.name = $defBinary.$("qlik-default-binary")
    $qvVer | ConvertTo-Json | Set-Content c:\shared-content\binaries\qver.json
    $qvVer = (Get-Content C:\shared-content\binaries\qver.json -raw) | ConvertFrom-Json
}
$qvBinaryURL = (Get-Content C:\shared-content\binaries\qBinaryDownload.json -raw) | ConvertFrom-Json
$bin = "c:\shared-content\binaries"
$binLoc = gci $bin
$binaryName = $qvBinaryURL.qlikview | where { $_.name -eq $qvVer.name}
$path = join-path $bin($($binaryName.name))
$selVer = $qvBinaryURL.qlikview | where { $_.name -eq $qvVer.name }
Write-Log -Message "QlikView version to install: $($selVer.name)"
if ( -Not (Test-Path $path\QlikViewServer_x64Setup.exe))
    {
        write-log -Message "Binary not found for $($selVer.name), downloading..."
        $selVer = $qvBinaryURL.qlikview | where { $_.name -eq $qvVer.name }
        if ( -Not (Test-Path $path)){
        New-Item -ItemType directory -Path $path -ea Stop | Out-Null 
        }
        $url = $selVer.url
        $fileName = $url.Substring($url.LastIndexOf("/") + 1)
        $dlLoc = join-path $path QlikViewServer_x64Setup.exe
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
        cp $path\*.exe $bin\QlikViewServer_x64Setup.exe -Force
    }


else {
    write-log -Message "Binary found for $($selVer.name)"
    if ($selVer.name -like "*pre-release*") {
        Write-Log -Message "Pre-release software selected, downloading latest version"
        $url = $selVer.url
        $fileName = $url.Substring($url.LastIndexOf("/") + 1)
        $dlLoc = join-path $path $fileName
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        (New-Object System.Net.WebClient).DownloadFile($url, $dlLoc)
        cp $path\*.exe $bin -Force
    }
    
    cp $path\*.exe $bin -Force
}
