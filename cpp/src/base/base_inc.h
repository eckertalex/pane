#ifndef BASE_INC_H
#define BASE_INC_H

#include "base_context_cracking.h"

#include "base_core.h"
#include "base_memory.h"
#include "base_arena.h"

#if OS_WINDOWS
# include "win32/base/win32_base.h"
#elif OS_MAC
# include "mac/base/mac_base.h"
#elif OS_LINUX
# include "linux/base/linux_base.h"
#else
# error base: no backend for this OS yet
#endif

#endif // BASE_INC_H
