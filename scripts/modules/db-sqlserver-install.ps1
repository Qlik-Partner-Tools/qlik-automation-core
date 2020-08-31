<#
Module:             db-sqlserver-install.ps1
Author:             Vincenzo Esposito
Modified by:        -
Modification History:

Intent: Install and configure sqlserver database.
#>
$url_AW2017="https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak"
$bak_folder="C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\Backup\AdventureWorks2019.bak"

Write-Log -Message "db-sqlserver-install.ps1"
choco install sql-server-express

Write-Log -Message "Download Adventure Workd 2017"
(New-Object System.Net.WebClient).DownloadFile($url_AW2017, $bak_folder)

SQLCMD.EXE -E -S localhost –Q “RESTORE DATABASE Adventureworks FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\Backup\AdventureWorks2019.bak'”



