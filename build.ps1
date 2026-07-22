mkdir build -Force | Out-Null
pushd build

cl -nologo -Zi -FC ..\win32_handmade.cpp user32.lib Gdi32.lib

popd
