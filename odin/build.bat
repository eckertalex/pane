@echo off
setlocal

cd /d "%~dp0"

:: --- Unpack Arguments --------------------------------------------------------
set mode=debug
for %%a in (%*) do (
    if "%%~a"=="debug" (
        set mode=debug
    ) else if "%%~a"=="release" (
        set mode=release
    ) else (
        echo usage: %~nx0 [debug^|release] 1>&2
        exit /b 1
    )
)

:: --- Choose Mode -------------------------------------------------------------
if "%mode%"=="debug" (
    echo [debug mode]
    set mode_flags=-debug -o:none
) else (
    echo [release mode]
    rem No console window
    set mode_flags=-o:speed -disable-assert -subsystem:windows
)

:: --- Build -------------------------------------------------------------------
if not exist build mkdir build
odin build src\pane -out:build\pane.exe -vet %mode_flags%
