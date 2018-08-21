Configuration Binary
{
  Param (
    [string] $Name,
    [string] $Patch,
    [string] $SetupUri,
    [string] $PatchUri,
    [string] $SetupFileName = 'Qlik_Sense_setup.exe',
    [string] $PatchFileName = 'Qlik_Sense_update.exe',
    [string] $CachePath = 'C:\shared-content\binaries'
  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration, xPSDesiredStateConfiguration

  File Cache
  {
    Type = 'Directory'
    DestinationPath = Join-Path -Path $CachePath -ChildPath $Name
    Ensure = 'Present'
  }

  $global:SetupFullPath = Join-Path -Path $CachePath -ChildPath $Name | Join-Path -ChildPath $SetupFileName
  xRemoteFile Setup
  {
    DestinationPath = $SetupFullPath
    Uri = $SetupUri
    MatchSource = $false
  }

  if ($PatchUri)
  {
    $global:PatchFullPath = Join-Path -Path $CachePath -ChildPath ($Name, $Patch -join ' ').Trim() | Join-Path -ChildPath $PatchFileName
    xRemoteFile Patch
    {
      DestinationPath = $PatchFullPath
      Uri = $PatchUri
      MatchSource = $false
    }
  }
}
