@echo off
REM ==========================================
REM DIY Enrollment Script
REM Fully self-hosted, runs all BAT files from GitHub repo as admin
REM ==========================================

REM Set working directories
set "TEMP_DIR=%TEMP%\enrollment"
set "ZIP_PATH=%TEMP_DIR%\enrollment.zip"
set "LOG_FILE=%TEMP_DIR%\enrollment_log.txt"

REM Create temp folder
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

echo ========================================== >> "%LOG_FILE%"
echo Enrollment started at %DATE% %TIME% >> "%LOG_FILE%"

REM Download GitHub repo as ZIP
echo Downloading repository...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/kbpawer234567/enrollment/archive/refs/heads/main.zip' -OutFile '%ZIP_PATH%'" >> "%LOG_FILE%" 2>&1

if exist "%ZIP_PATH%" (
    echo Download complete >> "%LOG_FILE%"
) else (
    echo ERROR: Failed to download ZIP >> "%LOG_FILE%"
    pause
    exit /b 1
)

REM Extract ZIP
echo Extracting files...
powershell -Command "Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%TEMP_DIR%' -Force" >> "%LOG_FILE%" 2>&1

set "APPS_DIR=%TEMP_DIR%\enrollment-main\apps"

if not exist "%APPS_DIR%" (
    echo ERROR: Apps folder not found! >> "%LOG_FILE%"
    pause
    exit /b 1
)

REM Loop through all .bat files and run them as admin
for %%F in ("%APPS_DIR%\*.bat") do (
    echo Running %%F as administrator...
    powershell -Command "Start-Process -FilePath '%%~fF' -Verb RunAs"
    echo %%F executed at %DATE% %TIME% >> "%LOG_FILE%"
)

echo Enrollment finished at %DATE% %TIME% >> "%LOG_FILE%"
echo ========================================== >> "%LOG_FILE%"

pause
exit

