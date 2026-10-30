@echo off
setlocal

cd /d "%~dp0"

:: --- Arguments ---------------------------------------------------------------
set mode=debug
for %%a in (%*) do (
    if "%%~a"=="debug" (
        set mode=debug
    ) else if "%%~a"=="release" (
        set mode=release
    ) else (
        echo usage: %~nx0 [debug^|release] 1>&2
        exit /b 2
    )
)

:: --- Flags -------------------------------------------------------------------
set flags_common=-vet
set flags_debug=-debug -o:none
:: No console window in release
set flags_release=-o:speed -disable-assert -subsystem:windows

:: --- Choose Flags ------------------------------------------------------------
if "%mode%"=="debug" (
    set flags=%flags_common% %flags_debug%
) else (
    set flags=%flags_common% %flags_release%
)

:: --- Build -------------------------------------------------------------------
if not exist build mkdir build
odin build src\pane -out:build\pane.exe %flags% || exit /b 1
