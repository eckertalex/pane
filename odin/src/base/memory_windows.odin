package base

import win32 "core:sys/windows"

page_size :: proc() -> u64 {
	info: win32.SYSTEM_INFO
	win32.GetSystemInfo(&info)
	return u64(info.dwPageSize)
}

reserve_memory :: proc(size: u64) -> rawptr {
	return win32.VirtualAlloc(nil, uint(size), win32.MEM_RESERVE, win32.PAGE_NOACCESS)
}

commit_memory :: proc(ptr: rawptr, size: u64) -> bool {
	return win32.VirtualAlloc(ptr, uint(size), win32.MEM_COMMIT, win32.PAGE_READWRITE) != nil
}

decommit_memory :: proc(ptr: rawptr, size: u64) {
	win32.VirtualFree(ptr, uint(size), win32.MEM_DECOMMIT)
}

release_memory :: proc(ptr: rawptr, size: u64) {
	win32.VirtualFree(ptr, 0, win32.MEM_RELEASE)
}
