Configuration Windows
{
  Param (
    [bool] $PasswordComplexityEnabled = $false,
    [string] $Wallpaper = 'C:\shared-content\files\wallpaper\Qlik-Wallpaper-dark-01.jpg',
    [string] $BackgroundInfo = 'C:\shared-content\files\bgInfo\qmiDefault.bgi',
    [PSObject[]] $Hosts
  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration, xNetworking

  PasswordPolicy Local {
    ComplexityEnabled = $PasswordComplexityEnabled
  }

  Background bginfo {
    BGIFile = $BackgroundInfo
    Wallpaper = $Wallpaper
  }

  $Hosts | foreach {
    xHostsFile $_.name
    {
      HostName = $_.name
      IPAddress = $_.ip
      Ensure = "Present"
    }
  }
}
