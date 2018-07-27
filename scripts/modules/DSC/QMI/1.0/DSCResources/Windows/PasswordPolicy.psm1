Configuration PasswordPolicy
{
  Param (
    [bool] $ComplexityEnabled
  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration

  Script PasswordPolicy
  {
    SetScript =
    {
      secedit /export /cfg c:\secpol.cfg
      (gc C:\secpol.cfg) -replace "PasswordComplexity = 0|1", [int]$using:ComplexityEnabled | Out-File C:\secpol.cfg
      secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
      rm -force c:\secpol.cfg -confirm:$false
    }

    GetScript =
    {
      secedit /export /cfg c:\secpol.cfg
      $result = (gc C:\secpol.cfg)
      rm -force c:\secpol.cfg -confirm:$false
      return $result
    }

    TestScript =
    {
      secedit /export /cfg c:\secpol.cfg
      $result = (gc C:\secpol.cfg).contains("PasswordComplexity = $([int]$using:ComplexityEnabled)")
      rm -force c:\secpol.cfg -confirm:$false
      return $result
    }
  }
}
