Configuration SenseImport
{
  Param (
    [Parameter(Mandatory)]
    [string] $RootPath,
    [string] $AppDirectory = 'apps',
    [string] $ExtensionDirectory = 'extensions'
  )

  Import-DscResource -ModuleName QlikResources

  foreach ($file in Get-ChildItem -Path (Join-Path -Path $RootPath -ChildPath $ExtensionDirectory) -Filter '*.zip')
  {
    QlikExtension $file.FullName
    {
      Name = $file.BaseName
      Source = $file.FullName
      Ensure = 'Present'
    }
  }

  foreach ($file in Get-ChildItem -Path (Join-Path -Path $RootPath -ChildPath $AppDirectory) -Filter '*.qvf')
  {
    QlikApp $file.FullName
    {
      Name = $file.BaseName
      Stream = '.'
      Source = $file.FullName
      Ensure = 'Present'
    }
  }

  foreach ($dir in Get-ChildItem -Path (Join-Path -Path $RootPath -ChildPath $AppDirectory) -Directory)
  {
    QlikStream $dir.BaseName
    {
      Name = $dir.BaseName
      Ensure = 'Present'
    }

    foreach ($file in Get-ChildItem -Path $dir.FullName -Filter '*.qvf')
    {
      QlikApp $file.FullName
      {
        Name = $file.BaseName
        Stream = $dir.BaseName
        Source = $file.FullName
        Ensure = 'Present'
      }
    }
  }
}
