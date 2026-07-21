@echo off

mkdir build
pushd build

cl -nologo -Zi -FC ..\win32_handmade.cpp user32.lib

popd
