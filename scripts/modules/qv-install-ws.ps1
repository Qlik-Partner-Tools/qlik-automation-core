$qsVer = (Get-Content C:\shared-content\binaries\qver.json -raw) | ConvertFrom-Json

write-log -Message "Installing $qsVer.name"
if ( $qsVer.name -like "QlikView Server November 201*" -or $qsVer.name -like "QlikView*2019*"  -or $qsVer.name -like "QlikView*202*")  {
    write-log -Message "Install Mode: New"
    start-process -filepath c:\shared-content\scripts\modules\qv-installNov.bat -wait
}
else
{
    write-log -Message "Install Mode: Legacy"
    start-process -filepath c:\shared-content\scripts\modules\qv-installPreNov.bat -wait
}

rm c:\shared-content\binaries\*.exe