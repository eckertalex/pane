#include "base_arena.c"

#if OS_WINDOWS
# include "win32/base/win32_base.c"
#elif OS_MAC
# include "mac/base/mac_base.c"
#elif OS_LINUX
# include "linux/base/linux_base.c"
#else
# error base: no backend for this OS yet
#endif
