$scenario = (Get-Content c:\vagrant\scenario.json -raw) | ConvertFrom-Json
$ipv4address = (gwmi Win32_NetworkAdapterConfiguration | ? { $_.IPAddress -ne $null }).ipaddress | where { $_ -like "192.168.56.*" }
if(!(Test-Path c:\qmi\QMIError)){
    $response = "_  Success! $($scenario.description) has been provisioned"
}
else
{
    $response = "_  Failure! $($scenario.description) has been not provisioned successfully"
}
Write-Host "_ "
Write-Host $("_" * $response.length)
Write-Host "_ "
Write-Host $response
Write-Host "_ "
Write-Host "_     IP address: $($ipv4address), DNS name: $($env:computername.ToLower())"
Write-Host "_     Username: Qlik"
Write-Host "_     Password: Qlik1234"
Write-Host "_ "
if ($scenario.resources.count -gt 0) {
Write-Host "_  Available resources:"
Write-Host "_ "
    foreach($obj in $scenario.resources)
    {
        Write-Host "_     $($obj.name): $($obj.url)"
    }
    Write-Host "_"
}
