@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

:: --- Arguments ---------------------------------------------------------------
:: Versions to build come first, everything else goes to their build.bat
set versions=
set rest=
for %%a in (%*) do (
    if "%%~a"=="c" (
        set versions=!versions! c
    ) else if "%%~a"=="cpp" (
        set versions=!versions! cpp
    ) else if "%%~a"=="odin" (
        set versions=!versions! odin
    ) else (
        set rest=!rest! %%~a
    )
)
if "%versions%"=="" set versions=c cpp odin

:: --- Build -------------------------------------------------------------------
set status=0
for %%v in (%versions%) do (
    echo === %%v ===
    call %%v\build.bat %rest% || set status=1
    echo.
)

exit /b %status%
