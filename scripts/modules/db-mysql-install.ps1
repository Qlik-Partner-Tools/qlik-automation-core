<#
Module:             db-mysql-install.ps1
Author:             Vincenzo Esposito
Modified by:        -
Modification History:

Intent: Install and configure mysql database.
#>

$db_northwind_sql="https://raw.githubusercontent.com/dalers/mywind/master/northwind.sql"
$db_northwind_data="https://raw.githubusercontent.com/dalers/mywind/master/northwind-data.sql"
$db_northwind_currTimestamp="https://raw.githubusercontent.com/dalers/mywind/master/northwind-default-current-timestamp.sql"

$local_folder_sql="C:\tools\northwind.sql"
$local_folder_data="C:\tools\northwind-data.sql"
$local_folder_currTimestamp="C:\tools\northwind-default-current-timestamp.sql"

Write-Log -Message "db-mysql-install.ps1"
choco install mysql

C:\tools\mysql\mysql-8.0.21-winx64\bin\mysql.exe -u root < $db_northwind_sql

Write-Log -Message "Download northwind.sql"
(New-Object System.Net.WebClient).DownloadFile($db_northwind_sql, $local_folder_sql)
Write-Log -Message "Download northwind-data.sql"
(New-Object System.Net.WebClient).DownloadFile($db_northwind_data, $local_folder_data)
Write-Log -Message "Download northwind-default-current-timestamp.sql"
(New-Object System.Net.WebClient).DownloadFile($db_northwind_currTimestamp, $local_folder_currTimestamp)