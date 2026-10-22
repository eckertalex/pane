package base

import "core:sys/linux"
import "core:sys/posix"

page_size :: proc() -> u64 {
	return u64(posix.sysconf(._PAGESIZE))
}

reserve_memory :: proc(size: u64) -> rawptr {
	result := posix.mmap(nil, uint(size), {}, {.PRIVATE, .ANONYMOUS})
	if result == posix.MAP_FAILED {
		result = nil
	}
	return result
}

commit_memory :: proc(ptr: rawptr, size: u64) -> bool {
	return posix.mprotect(ptr, uint(size), {.READ, .WRITE}) == .OK
}

// glibc's posix_madvise ignores DONTNEED, so call the syscall directly
decommit_memory :: proc(ptr: rawptr, size: u64) {
	linux.madvise(ptr, uint(size), .DONTNEED)
	posix.mprotect(ptr, uint(size), {})
}

release_memory :: proc(ptr: rawptr, size: u64) {
	posix.munmap(ptr, uint(size))
}
