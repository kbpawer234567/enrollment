@echo off
setlocal enabledelayedexpansion

REM =====================================================
REM SETTINGS
REM =====================================================

set "URL=https://raw.githubusercontent.com/kbpawer234567/enrollment/refs/heads/main/login.txt"
set "ACCOUNTFILE=%~dp0login.txt"

echo [1/4] Downloading login list...
powershell -Command "Invoke-WebRequest '%URL%' -OutFile '%ACCOUNTFILE%'"

if not exist "%ACCOUNTFILE%" (
    echo ERROR: login.txt could not be downloaded!
    pause
    exit /b 1
)

echo.
echo [2/4] Loading allowed Microsoft accounts...

set "MSLIST="

REM ================================================
REM READ MICROSOFT ACCOUNTS FROM login.txt
REM ================================================
for /F "usebackq tokens=* delims=" %%A in ("%ACCOUNTFILE%") do (
    if not "%%A"=="" (
        set "EMAIL=%%A"
        set "MSEntry=MicrosoftAccount\%%A"

        if "!MSLIST!"=="" (
            set "MSLIST=!MSEntry!"
        ) else (
            set "MSLIST=!MSLIST!,!MSEntry!"
        )
    )
)

echo Allowed Microsoft Accounts:
echo !MSLIST!
echo.

REM ================================================
REM ENUMERATE EXISTING MICROSOFT ACCOUNTS
REM ================================================
echo [3/4] Checking existing Microsoft accounts...

set "EXISTINGMS="

for /F "skip=1 tokens=1,*" %%A in ('wmic useraccount get name 2^>nul') do (
    echo %%A | findstr /i "MicrosoftAccount\\" >nul
    if !errorlevel! == 0 (
        if "!EXISTINGMS!"=="" (
            set "EXISTINGMS=%%A"
        ) else (
            set "EXISTINGMS=!EXISTINGMS!,%%A"
        )
    )
)

echo Existing Microsoft Accounts:
echo !EXISTINGMS!
echo.

REM ================================================
REM ADD MISSING MICROSOFT ACCOUNTS
REM ================================================
echo Adding missing Microsoft accounts...

for %%A in (!MSLIST!) do (
    echo !EXISTINGMS! | findstr /i /c:"%%A" >nul
    if !errorlevel! neq 0 (
        echo Adding %%A ...
        net user "%%A" /add >nul 2>&1
    )
)

REM ================================================
REM DELETE MICROSOFT ACCOUNTS NOT IN LIST
REM ================================================
echo Deleting unlisted Microsoft accounts...

for %%A in (!EXISTINGMS!) do (
    echo !MSLIST! | findstr /i /c:"%%A" >nul
    if !errorlevel! neq 0 (
        echo Removing Microsoft account %%A ...

        REM Remove user
        net user "%%A" /delete >nul 2>&1

        REM Extract local folder name by stripping prefix
        set "FOLDER=%%A"
        set "FOLDER=!FOLDER:MicrosoftAccount\=!"

        REM Wipe profile folder
        if exist "C:\Users\!FOLDER!" (
            echo Wiping profile folder: C:\Users\!FOLDER!
            rmdir /s /q "C:\Users\!FOLDER!"
        )
    )
)

echo.
echo [4/4] DONE!
echo Microsoft accounts are now fully synced to login.txt.
echo Local users preserved.
pause
