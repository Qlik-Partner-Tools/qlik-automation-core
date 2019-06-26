$qsVer = (Get-Content C:\shared-content\binaries\qver.json -raw) | ConvertFrom-Json

write-log -Message "Installing $qsVer.name"
if ( $qsVer.name -like "QlikView Server November 201*" -or $qsVer.name -like "QlikView*2019*") {
    start-process -filepath c:\shared-content\scripts\modules\qv-installNov-iis.bat -wait
}
else
{
    start-process -filepath c:\shared-content\scripts\modules\qv-installPreNov-iis.bat -wait
}

rm c:\shared-content\binaries\*.exe