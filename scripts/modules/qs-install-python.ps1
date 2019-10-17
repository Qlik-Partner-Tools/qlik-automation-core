<#
Module:             qs-install-python
Author:             Clint Carr
Modified by:        
Modification History:
    - Updated SciPy, Numpy and Pyflux
    - Updated for Python 3.7
last updated:       09/18/2018
Intent: Configure and install Python and modules for AAI
#>

Trap {
	Write-Log -Message $_.Exception.Message -Severity "Error"
  	Break
}

#install Python 3.6
Write-Log -Message "Starting qs-install-python.ps1"

copy-item c:\vagrant\files\start-python*.bat 'c:\users\all users\desktop'

Write-Log -Message "Installing Python 3.6"
cinst python3 | Out-Null

#create a new folder for python environments
Write-Log -Message "Creating folder path for Qlik Sense AAI"
New-Item -ItemType directory -Path C:\python\venv\QlikSenseAAI\arima -ea Stop | Out-Null
New-Item -ItemType directory -Path C:\python\venv\QlikSenseAAI\sentiment -ea Stop | Out-Null
New-Item -ItemType directory -Path C:\python\venv\QlikSenseAAI\geocoding -ea Stop | Out-Null


#create a python virtual environment called QlikSenseAAI
Write-Log -Message "Creating Python Virtual Environment"
c:\python37\python -m venv c:\python\venv\QlikSenseAAI
cd c:\python\venv\QlikSenseAAI

#Activate the virtual environment
Write-Log -Message "Activating the QlikSenseAAI Virtual Environment"
.\Scripts\Activate QlikSenseAAI 

#upgrade the setuptools
Write-Log -Message "Updating Python Setup Tools"
pip install --upgrade setuptools | Out-Null

# Write-Log -Message "Downloading Python wheel files for numpy and scipy"
# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# (New-Object System.Net.WebClient).DownloadFile('https://qmi.qlik.com/downloads/files/scipy-1.0.0-cp36-cp36m-win_amd64.whl', 'c:\tmp\scipy-1.0.0-cp36-cp36m-win_amd64.whl')
# (New-Object System.Net.WebClient).DownloadFile('https://qmi.qlik.com/downloads/files/numpy-1.13.3+mkl-cp36-cp36m-win_amd64.whl', 'c:\tmp\numpy-1.13.3+mkl-cp36-cp36m-win_amd64.whl')

Write-Log -Message "Installing Numpy with MKL"
# pip install c:\tmp\numpy-1.13.3+mkl-cp36-cp36m-win_amd64.whl | Out-Null
pip install numpy

Write-Log -Message "Installing SCIPY"
# pip install c:\tmp\scipy-1.0.0-cp36-cp36m-win_amd64.whl | Out-Null
pip install scipy

# install build tools
Write-Log -Message "Installing Visual Studio 2015 Build Tools (C++)"
cinst vcbuildtools  | Out-Null

Write-Log "Installing PANDAS"
pip install pandas | Out-Null

Write-Log -Message "Installing Pyflux"
# pip install pyflux  | Out-Null
pip install c:\vagrant\files\pyflux-0.4.17-cp37-cp37m-win_amd64.whl | Out-Null

Write-Log -Message "Installing GRPCIO"
pip install grpcio  | Out-Null

Write-Log -Message "Installing Vader Sentiment"
pip install vaderSentiment | Out-Null

Write-Log -Message "Installing geopy"
pip install geopy

Write-Log -Message "Installing requests"
pip install requests

Connect-Qlik $env:COMPUTERNAME -UseDefaultCredentials  | Out-Null

$json = (@{
name = "PythonForecasting";
host = "localhost";
port = 50151;
reconnectTimeout= 10;
requestTimeout= 20;
} | ConvertTo-Json -Compress -Depth 10)
Write-Log -Message "Creating Python Forecasting Analytic Connection on port 50151 in the QMC"
invoke-qlikpost "/qrs/AnalyticConnection" $json  | Out-Null  | Out-Null

Write-Log -Message "Extracting arima examples"
Expand-Archive 'C:\vagrant\files\DPI - MODULE - Qlik Sense AAI & Python ARIMA Forecasting.zip' c:\tmp\ -force | Out-Null 

Write-Log -Message "Copying content"
Copy-Item 'c:\tmp\DPI - MODULE - Qlik Sense AAI & Python ARIMA Forecasting\DPI - Python ARIMA Forecasting\*' c:\python\venv\QlikSenseAAI\arima\

### Import scenario applications
Write-Log -Message "Connecting as user Qlik to QRS"
gci cert:\CurrentUser\My | where {$_.issuer -eq $cert} | Connect-Qlik -username "$env:COMPUTERNAME\qlik" | Out-Null

Write-Log -Message "Importing applications"
If (Test-Path "c:\python\venv\QlikSenseAAI\arima\") {
    gci c:\\python\\venv\\QlikSenseAAI\\arima\\*.qvf | foreach { 
    Write-Log -Message "Importing $_.BaseName";
    Import-QlikApp -name $_.BaseName -file $_.FullName -upload | Out-Null
    }   
}

# sentiment analysis

Connect-Qlik $env:COMPUTERNAME -UseDefaultCredentials  | Out-Null

$json = (@{
name = "PythonSentiment";
host = "localhost";
port = 50055;
reconnectTimeout= 10;
requestTimeout= 20;
} | ConvertTo-Json -Compress -Depth 10)
Write-Log -Message "Creating Python Sentiment Analytic Connection on port 50055 in the QMC"
invoke-qlikpost "/qrs/AnalyticConnection" $json  | Out-Null  | Out-Null

Write-Log -Message "Extracting sentiment examples"
Expand-Archive 'C:\vagrant\files\DPI - MODULE - Qlik Sense AAI & Python Sentiment Analysis.zip' c:\tmp\ -force | Out-Null 

Write-Log -Message "Copying content"
Copy-Item 'c:\tmp\DPI - MODULE - Qlik Sense AAI & Python Sentiment Analysis\Sentiment\*' c:\python\venv\QlikSenseAAI\sentiment\

Write-Log -Message "Connecting as user Qlik to QRS"

gci cert:\CurrentUser\My | where {$_.issuer -eq $cert} | Connect-Qlik -username "$env:COMPUTERNAME\qlik" | Out-Null

Write-Log -Message "Importing applications"
If (Test-Path "c:\python\venv\QlikSenseAAI\sentiment\") {
    gci c:\\python\\venv\\QlikSenseAAI\\sentiment\\*.qvf | foreach { 
    Write-Log -Message "Importing $_.BaseName";
    Import-QlikApp -name $_.BaseName -file $_.FullName -upload | Out-Null
    }   
}

# Geocoding

Connect-Qlik $env:COMPUTERNAME -UseDefaultCredentials  | Out-Null

$json = (@{
name = "PythonGeo";
host = "localhost";
port = 50052;
reconnectTimeout= 10;
requestTimeout= 20;
} | ConvertTo-Json -Compress -Depth 10)
Write-Log -Message "Creating Python GeoCoding Analytic Connection on port 50052 in the QMC"
invoke-qlikpost "/qrs/AnalyticConnection" $json  | Out-Null  | Out-Null

Write-Log -Message "Extracting geocoding examples"
Expand-Archive 'C:\vagrant\files\DPI - Module - Qlik Sense AAI & Python Geocoding.zip' c:\tmp\ -force | Out-Null 

Write-Log -Message "Copying content"
Copy-Item 'c:\tmp\DPI - MODULE - Qlik Sense AAI & Python Geocoding\Geocoding\*' c:\python\venv\QlikSenseAAI\geocoding\

Write-Log -Message "Connecting as user Qlik to QRS"
gci cert:\CurrentUser\My | where {$_.issuer -eq $cert} | Connect-Qlik -username "$env:COMPUTERNAME\qlik" | Out-Null

Write-Log -Message "Importing applications"
If (Test-Path "c:\python\venv\QlikSenseAAI\geocoding\") {
    gci c:\\python\\venv\\QlikSenseAAI\\geocoding\\*.qvf | foreach { 
    Write-Log -Message "Importing $_.BaseName";
    Import-QlikApp -name $_.BaseName -file $_.FullName -upload | Out-Null
    }   
}


Write-Log -Message "Creating a new shell to run the Python Forecasting Extension"
start powershell { c:\shared-content\scripts\modules\qs-python-arima.ps1 }

Write-Log -Message "Creating a new shell to run the Python Sentiment Extension"
start powershell { c:\shared-content\scripts\modules\qs-python-sentiment.ps1 }

Write-Log -Message "Creating a new shell to run the Python Geocoding Extension"
start powershell { c:\shared-content\scripts\modules\qs-python-geocoding.ps1 }


Write-Log "Restarting Qlik Sense Engine Service"
net stop QlikSenseEngineService | Out-Null
start-sleep -s 10
net start QlikSenseEngineService | Out-Null
