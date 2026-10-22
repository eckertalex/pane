package base

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

// MADV_DONTNEED is only a hint on macOS and can leave the old contents in
// place. Mapping fresh pages over the range really frees them and guarantees
// zeros on the next commit.
decommit_memory :: proc(ptr: rawptr, size: u64) {
	posix.mmap(ptr, uint(size), {}, {.PRIVATE, .ANONYMOUS, .FIXED})
}

release_memory :: proc(ptr: rawptr, size: u64) {
	posix.munmap(ptr, uint(size))
}
