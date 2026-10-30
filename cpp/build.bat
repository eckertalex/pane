@echo off
setlocal

cd /d "%~dp0"

:: --- Arguments ---------------------------------------------------------------
:: clang++ is the only compiler on Windows, matching the clang-only C build
set mode=debug
for %%a in (%*) do (
    if "%%~a"=="debug" (
        set mode=debug
    ) else if "%%~a"=="release" (
        set mode=release
    ) else if not "%%~a"=="clang++" (
        echo usage: %~nx0 [debug^|release] [clang++] 1>&2
        exit /b 2
    )
)

:: --- Flags -------------------------------------------------------------------
set cxx_common=-xc++ -std=c++20 -fno-exceptions -fno-rtti -Isrc -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wundef -Wno-unused-function -D_GNU_SOURCE
set cxx_debug=-O0 -g -DBUILD_DEBUG=1
set cxx_release=-O2 -g -DBUILD_DEBUG=0
:: No console window in release, but keep main as the entry point
set link_release=-Wl,/subsystem:windows -Wl,/entry:mainCRTStartup

:: --- Choose Flags ------------------------------------------------------------
if "%mode%"=="debug" (
    set compile=clang++ %cxx_common% %cxx_debug%
    set link_flags=
) else (
    set compile=clang++ %cxx_common% %cxx_release%
    set link_flags=%link_release%
)

:: --- Build -------------------------------------------------------------------
:: Libraries are linked with #pragma comment(lib, ...) next to the code using them
if not exist build mkdir build
%compile% src\pane\pane_main.cpp -o build\pane.exe %link_flags% || exit /b 1
