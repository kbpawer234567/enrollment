@echo off
setlocal enabledelayedexpansion

REM === URL of the allowlist ===
set "URL=https://raw.githubusercontent.com/kbpawer234567/enrollment/refs/heads/main/login.txt"
set "LOCALFILE=%~dp0login.txt"

echo [1/4] Downloading login list...
powershell -Command "Invoke-WebRequest '%URL%' -OutFile '%LOCALFILE%'"

if not exist "%LOCALFILE%" (
    echo ERROR: login.txt could not be downloaded.
    pause
    exit /b 1
)

echo [2/4] Processing allowlist...

set "ALLOWLIST="

REM Read and convert entries
for /F "usebackq tokens=* delims=" %%A in ("%LOCALFILE%") do (
    if not "%%A"=="" (
        set "LINE=%%A"

        REM If entry contains @, treat it as an Microsoft Account email
        echo !LINE! | find "@" >nul
        if !errorlevel! == 0 (
            set "LINE=MicrosoftAccount\%%A"
        )

        if defined ALLOWLIST (
            set "ALLOWLIST=!ALLOWLIST!,!LINE!"
        ) else (
            set "ALLOWLIST=!LINE!"
        )
    )
)

echo [3/4] Adding ALL local accounts...

REM Enumerate local accounts
for /F "skip=1 tokens=1,*" %%A in ('wmic useraccount where "localaccount=true" get name 2^>nul') do (
    if not "%%A"=="" (
        set "LOCALACC=.\%%A"
        if defined ALLOWLIST (
            set "ALLOWLIST=!ALLOWLIST!,!LOCALACC!"
        ) else (
            set "ALLOWLIST=!LOCALACC!"
        )
    )
)

echo Allow list will be:
echo %ALLOWLIST%
echo.

REM === Update Local Security Policy ===

echo [4/4] Updating Local Security Policy...
secedit /export /cfg "%~dp0secpol.cfg" >nul 2>&1

powershell -Command ^
    "(Get-Content '%~dp0secpol.cfg') ^
    -replace 'SeInteractiveLogonRight =.*', 'SeInteractiveLogonRight = %ALLOWLIST%' ^
    | Set-Content '%~dp0secpol.cfg'"

secedit /configure /db secedit.sdb /cfg "%~dp0secpol.cfg" /areas USER_RIGHTS >nul 2>&1

echo.
echo DONE!
echo Local login is now allowed for:
echo   - ALL local accounts
echo   - The email accounts listed in login.txt
echo.
echo Restart recommended.
pause
