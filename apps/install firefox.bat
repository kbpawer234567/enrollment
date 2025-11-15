@echo off
REM Download Ninite Firefox installer
set "URL=https://ninite.com/firefox/ninite.exe"
set "FILE=%TEMP%\ninite_firefox.exe"

echo Downloading Firefox installer...
powershell -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%FILE%'"
echo Instaling Firefox installer...
powershell -Command "Start-Process '%FILE%' -Verb RunAs"
