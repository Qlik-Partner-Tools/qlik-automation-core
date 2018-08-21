Configuration Background
{
  Param (
    [string] $BGIFile,
    [string] $Wallpaper
  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration

  Script Background
  {
    SetScript =
    {
      Write-Log -Message "Starting q-background.ps1"
      # credit https://github.com/StefanScherer/adfs2

      ### Download BGInfo
      Write-Log -Message "Downloading BgInfo"
      if (!(Test-Path 'c:\sysinternals\bginfo64.exe')) {
        New-Item -ItemType directory -Path 'c:\sysinternals' | Out-Null
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        (New-Object System.Net.WebClient).DownloadFile('http://live.sysinternals.com/bginfo64.exe', 'c:\sysinternals\bginfo64.exe')
      }

      $vbsScript = @'
WScript.Sleep 15000
Dim objShell
Set objShell = WScript.CreateObject( "WScript.Shell" )
objShell.Run("""c:\sysinternals\bginfo64.exe"" /nolicprompt ""c:\sysinternals\qmiDefault.bgi"" /silent /timer:0")
'@

      $vbsScript | Out-File 'c:\sysinternals\bginfo.vbs'

      write-Log -Message "Copying BgInfo script"
      Copy-Item $using:BGIFile 'c:\sysinternals\qmiDefault.bgi'
      Copy-Item $using:Wallpaper 'c:\sysinternals\Qlik-Wallpaper-dark-01.jpg'

      Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name bginfo -Value 'wscript "c:\sysinternals\bginfo.vbs"'
      write-Log -Message "Setting background and BgInfo"
    }

    GetScript =
    {
      return Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run | ? bginfo -ne $null
    }

    TestScript =
    {
      if (!(Test-Path 'c:\sysinternals\bginfo64.exe')) { return $false }
      if (!(Test-Path 'c:\sysinternals\bginfo.vbs')) { return $false }
      if (!(Test-Path 'c:\sysinternals\qmiDefault.bgi')) { return $false }
      if (!(Test-Path 'c:\sysinternals\Qlik-Wallpaper-dark-01.jpg')) { return $false }
      $run = Get-Item HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
      if (!($run.Property -Contains 'bginfo')) { return $false }
      if (($run | Get-ItemProperty).bginfo -ne 'wscript "c:\sysinternals\bginfo.vbs"') { return $false }

      return $true
    }
  }
}
