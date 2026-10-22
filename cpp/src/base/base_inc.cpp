#include "base_arena.cpp"

#if OS_WINDOWS
# include "win32/base/win32_base.cpp"
#elif OS_MAC
# include "mac/base/mac_base.cpp"
#elif OS_LINUX
# include "linux/base/linux_base.cpp"
#else
# error base: no backend for this OS yet
#endif
