#include "window_manager.cpp"

#if OS_MAC
# include "mac/window_manager/mac_window_manager.mm"
#elif OS_WINDOWS
# include "win32/window_manager/win32_window_manager.cpp"
#elif OS_LINUX
# include "linux/window_manager/x11/x11_window_manager.cpp"
#else
# error window_manager: no backend for this OS yet
#endif
