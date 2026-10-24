@echo off
setlocal

cd /d "%~dp0"

:: --- Unpack Arguments --------------------------------------------------------
:: clang++ is the only compiler on Windows, matching the clang-only C build
set mode=debug
for %%a in (%*) do (
    if "%%~a"=="debug" (
        set mode=debug
    ) else if "%%~a"=="release" (
        set mode=release
    ) else if not "%%~a"=="clang++" (
        echo usage: %~nx0 [debug^|release] [clang++] 1>&2
        exit /b 1
    )
)

:: --- Choose Mode -------------------------------------------------------------
set flags=-xc++ -std=c++20 -fno-exceptions -fno-rtti -Isrc -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wundef -Wno-unused-function -D_GNU_SOURCE

echo [clang++ compile]
if "%mode%"=="debug" (
    echo [debug mode]
    set mode_flags=-O0 -g -DBUILD_DEBUG=1
    set link_flags=
) else (
    echo [release mode]
    set mode_flags=-O2 -g -DBUILD_DEBUG=0
    rem No console window, but keep main as the entry point
    set link_flags=-Wl,/subsystem:windows -Wl,/entry:mainCRTStartup
)

:: --- Build -------------------------------------------------------------------
:: Libraries are linked with #pragma comment(lib, ...) next to the code using them
if not exist build mkdir build
clang++ %flags% %mode_flags% src\pane\pane_main.cpp -o build\pane.exe %link_flags%
