$qsVer = (Get-Content C:\shared-content\binaries\qver.json -raw) | ConvertFrom-Json

write-log -Message "Installing $qsVer.name"
if ( $qsVer.name -eq "QlikView Server November 2017"){
    start-process -filepath c:\shared-content\scripts\modules\qv-installNov.bat -wait
}
else
{
    start-process -filepath c:\shared-content\scripts\modules\qv-installPreNov.bat -wait
}

rm c:\shared-content\binaries\*.exe