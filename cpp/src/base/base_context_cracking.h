#ifndef BASE_CONTEXT_CRACKING_H
#define BASE_CONTEXT_CRACKING_H

#if defined(__clang__)
# define COMPILER_CLANG 1
#elif defined(_MSC_VER)
# error MSVC is not supported, the code relies on clang and gcc builtins. Use clang.
#elif defined(__GNUC__)
# define COMPILER_GCC 1
#else
# error Unsupported compiler
#endif

#if defined(_WIN32)
# define OS_WINDOWS 1
#elif defined(__APPLE__)
# define OS_MAC 1
#elif defined(__linux__)
# define OS_LINUX 1
#else
# error Unsupported OS
#endif

#if defined(__x86_64__) || defined(_M_X64)
# define ARCH_X64 1
#elif defined(__aarch64__) || defined(_M_ARM64)
# define ARCH_ARM64 1
#else
# error Unsupported architecture
#endif

#if !defined(BUILD_DEBUG)
# define BUILD_DEBUG 1
#endif

#if !defined(COMPILER_CLANG)
# define COMPILER_CLANG 0
#endif
#if !defined(COMPILER_GCC)
# define COMPILER_GCC 0
#endif
#if !defined(OS_WINDOWS)
# define OS_WINDOWS 0
#endif
#if !defined(OS_MAC)
# define OS_MAC 0
#endif
#if !defined(OS_LINUX)
# define OS_LINUX 0
#endif
#if !defined(ARCH_X64)
# define ARCH_X64 0
#endif
#if !defined(ARCH_ARM64)
# define ARCH_ARM64 0
#endif

#endif // BASE_CONTEXT_CRACKING_H
