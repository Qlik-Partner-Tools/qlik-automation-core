echo Installing QlikView Server
echo Installing QlikView Server
set /p qver=< c:\shared-content\binaries\qver.json

echo %qver%
set qver=%qver:"=%
set "qver=%qver:~1, -1%"
set "qver=%qver:: ==%"
set "%qver:, =" & set "%"
echo %name%
if "%name%" == "QlikView Server November 2017" (
    START /WAIT "" c:\shared-content\binaries\QlikViewServer_x64Setup.exe /s /v" /qn IS_NET_API_LOGON_USERNAME="qmi-qv-iis\qservice" IS_NET_API_LOGON_PASSWORD="Qlik1234" ADDLOCAL="QVS,DistributionService,ManagementService,DirectoryServiceConnector,QvsClients,Plugin,AjaxZfc,MsIIS,QvTunnel,SupportTools,QvsDocs" DEFAULTWEBSITE="1" SILENT="1"" /clone_wait
)
if NOT "%name%" == "QlikView Server November 2017" (
    c:\shared-content\binaries\QlikViewServer_x64Setup.exe /s /v" /qn IS_NET_API_LOGON_USERNAME="qmi-qv-iis\qservice" IS_NET_API_LOGON_PASSWORD="Qlik1234" ADDLOCAL="QVS,DistributionService,ManagementService,DirectoryServiceConnector,QvsClients,Plugin,AjaxZfc,MsIIS,QvTunnel,SupportTools,QvsDocs" DEFAULTWEBSITE="1" SILENT="1"
)

del c:\shared-content\binaries\*.exe