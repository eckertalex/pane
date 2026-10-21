#include "window_manager.c"

#if OS_MAC
# include "mac/window_manager/mac_window_manager.m"
#elif OS_WINDOWS
# include "win32/window_manager/win32_window_manager.c"
#elif OS_LINUX
# include "x11/window_manager/x11_window_manager.c"
#else
# error window_manager: no backend for this OS yet
#endif
