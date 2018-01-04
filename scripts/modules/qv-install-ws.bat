echo Installing QlikView Server
set /p qver=< c:\shared-content\binaries\qver.json

echo %qver%
set qver=%qver:"=%
set "qver=%qver:~1, -1%"
set "qver=%qver:: ==%"
set "%qver:, ="
echo %name%
if "%name%" == "QlikView Server November 2017" (
    echo "Installing %name%"
	START /WAIT "" c:\shared-content\binaries\QlikViewServer_x64Setup.exe /s /v" /qn ADDLOCAL="ALL" IS_NET_API_LOGON_USERNAME="qmi-qv-ws\qservice" IS_NET_API_LOGON_PASSWORD="Qlik1234"" /clone_wait
)
if NOT "%name%" == "QlikView Server November 2017" (
    echo "Installing %name%"
	c:\shared-content\binaries\QlikViewServer_x64Setup.exe /s /v" /qn IS_NET_API_LOGON_USERNAME="qmi-qv-ws\qservice" IS_NET_API_LOGON_PASSWORD="Qlik1234" ADDLOCAL="All" SILENT="1"
)

del c:\shared-content\binaries\*.exe
