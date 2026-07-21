@echo off
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -property installationPath`) do set vsPath=%%i

call "%vsPath%\VC\Auxiliary\Build\vcvarsall.bat" x64
