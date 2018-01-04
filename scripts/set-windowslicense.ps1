Write-Log -Message "Checking for Windows Server License."
$winLicense = (Get-Content c:\shared-content\licenses\win-license.json -raw) | ConvertFrom-Json
if ($winLicense.standardEdition.Length -eq 29)
{
    DISM /online /Set-Edition:ServerStandard /ProductKey:$($winLicense.standardEdition) /AcceptEula /Quiet
}
elseif ($winLicnese.standardEdition.Length -eq 0)
{
    Write-Log -Message "No License found, please enter license into ../shared-content/licenses/win-license.json" -Severity "Warn"
}
else
{
    Write-log -Message "Please check license entered, it does not seem to be valid." -Severity "Error"
}
