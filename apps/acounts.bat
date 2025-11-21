@echo off
setlocal enabledelayedexpansion

REM ============================
REM SETTINGS
REM ============================
set "URL=https://raw.githubusercontent.com/kbpawer234567/enrollment/refs/heads/main/login.txt"
set "ACCOUNTFILE=%~dp0login.txt"

echo [1/5] Downloading login list...
powershell -Command "Invoke-WebRequest '%URL%' -OutFile '%ACCOUNTFILE%'"

if not exist "%ACCOUNTFILE%" (
    echo ERROR: Could not download login.txt!
    pause
    exit /b 1
)

echo.
echo [2/5] Processing allowed Microsoft accounts...

set "ALLOWEMAILS="
set "ALLOWNAMES="

REM ============================
REM PARSE login.txt
REM ============================
for /F "usebackq tokens=* delims=" %%A in ("%ACCOUNTFILE%") do (
    if not "%%A"=="" (
        set "EMAIL=%%A"

        REM Convert: test@gmail.com → test_gmail_com
        set "SAN=%%A"
        set "SAN=!SAN:@=_!"
        set "SAN=!SAN:.=_!"

        REM Build allowed lists
        if "!ALLOWEMAILS!"=="" (
            set "ALLOWEMAILS=!EMAIL!"
            set "ALLOWNAMES=!SAN!"
        ) else (
            set "ALLOWEMAILS=!ALLOWEMAILS!,!EMAIL!"
            set "ALLOWNAMES=!ALLOWNAMES!,!SAN!"
        )
    )
)

echo Allowed emails:  %ALLOWEMAILS%
echo Allowed names:   %ALLOWNAMES%
echo.

REM ============================
REM ENUMERATE EXISTING PLACEHOLDER USERS
REM ============================
echo [3/5] Scanning existing Microsoft placeholder users...

set "EXISTING="

for /F "skip=1 tokens=1" %%A in ('wmic useraccount get name 2^>nul') do (
    echo %%A | findstr /r "[a-zA-Z0-9_]" >nul
    if !errorlevel! equ 0 (
        REM Check if user is local-only
        net user "%%A" | findstr /i "Local Group Memberships" >nul
        if !errorlevel! equ 0 (
            REM Add to list
            if "!EXISTING!"=="" (
                set "EXISTING=%%A"
            ) else (
                set "EXISTING=!EXISTING!,%%A"
            )
        )
    )
)

echo Existing placeholder users:
echo %EXISTING%
echo.

REM ============================
REM CREATE MISSING USERS
REM ============================
echo [4/5] Creating missing Microsoft accounts...

for %%E in (!ALLOWEMAILS!) do (
    set "EMAIL=%%E"

    REM sanitized name again
    set "SAN=%%E"
    set "SAN=!SAN:@=_!"
    set "SAN=!SAN:.=_!"

    echo %EXISTING% | findstr /i /c:"!SAN!" >nul
    if !errorlevel! neq 0 (
        echo Creating user !SAN! for !EMAIL! ...

        REM Create placeholder
        net user "!SAN!" /add >nul

        REM Set description to MicrosoftAccount reference
        wmic useraccount where name="!SAN!" call rename "MicrosoftAccount\!EMAIL!" >nul 2>&1
    )
)

REM ============================
REM DELETE REMOVED USERS
REM ============================
echo.
echo [5/5] Deleting users not in list...

for %%A in (!EXISTING!) do (
    echo !ALLOWNAMES! | findstr /i /c:"%%A" >nul
    if !errorlevel! neq 0 (
        echo Removing %%A

        REM Delete user
        net user "%%A" /delete >nul

        REM Wipe profile folder
        if exist "C:\Users\%%A" (
            echo Wiping folder C:\Users\%%A
            rmdir /s /q "C:\Users\%%A"
        )
    )
)

echo.
echo DONE!
echo Microsoft account placeholders fully synced to login.txt.
echo Local users preserved.
pause
