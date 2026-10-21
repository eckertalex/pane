@echo off
setlocal

cd /d "%~dp0"
if not exist build mkdir build

if not defined CC set CC=clang

set mode=%1
if "%mode%"=="" set mode=debug

if "%mode%"=="debug" (
    echo [debug mode]
    set mode_flags=-O0 -g -DBUILD_DEBUG=1
    set link_flags=
) else if "%mode%"=="release" (
    echo [release mode]
    set mode_flags=-O2 -g -DBUILD_DEBUG=0
    rem No console window, but keep main as the entry point
    set link_flags=-Wl,/subsystem:windows -Wl,/entry:mainCRTStartup
) else (
    echo usage: %~nx0 [debug^|release] 1>&2
    exit /b 1
)

%CC% @compile_flags.txt %mode_flags% src\pane\pane_main.c -o build\pane.exe -luser32 %link_flags%
