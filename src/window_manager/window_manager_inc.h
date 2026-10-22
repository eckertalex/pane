#ifndef WINDOW_MANAGER_INC_H
#define WINDOW_MANAGER_INC_H

#include "window_manager.h"

#if OS_MAC
# include "mac/window_manager/mac_window_manager.h"
#elif OS_WINDOWS
# include "win32/window_manager/win32_window_manager.h"
#elif OS_LINUX
# include "linux/window_manager/x11/x11_window_manager.h"
#else
# error window_manager: no backend for this OS yet
#endif

#endif // WINDOW_MANAGER_INC_H
