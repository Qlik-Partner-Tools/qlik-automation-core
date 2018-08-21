Configuration SenseConfig
{
  param (
    [string[]] $RootImportPaths,
    [bool] $UserTokenForEveryone = $true,
    [bool] $StreamAccessForEveryone = $true
  )

  Import-DSCResource -ModuleName PSDesiredStateConfiguration,QlikResources

  QlikUser Vagrant
    {
      UserID = 'vagrant'
      UserDirectory = $ENV:computername
      Name = 'Vagrant'
      Roles = 'RootAdmin'
      Ensure = 'Present'
    }
    
  if ($UserTokenForEveryone)
  {
    QlikRule LicenseEveryone
    {
      Name = "Grant Everyone a token"
      Rule = '((user.name like "*"))'
      Category = "License"
      Actions = 1
      Comment = "Rule to set up automatic user access"
      Ensure = "Present"
    }
  }

  if ($StreamAccessForEveryone)
  {
    QlikRule StreamEveryone
    {
      Name = "Grant Everyone access to streams"
      Rule = '((user.name like "*"))'
      ResourceFilter = 'Stream_*'
      Category = "Security"
      Actions = 34
      Comment = "Grant everyone access to all streams"
      Ensure = "Present"
    }
  }

  foreach ($path in $RootImportPaths)
  {
    SenseImport AppsAndExtensions
    {
      RootPath = $path
    }
  }
}
