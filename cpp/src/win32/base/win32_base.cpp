internal u64 page_size(void) {
    SYSTEM_INFO info;
    GetSystemInfo(&info);
    return info.dwPageSize;
}

internal void *reserve_memory(u64 size) {
    return VirtualAlloc(nullptr, size, MEM_RESERVE, PAGE_NOACCESS);
}

internal bool commit_memory(void *ptr, u64 size) {
    return VirtualAlloc(ptr, size, MEM_COMMIT, PAGE_READWRITE) != nullptr;
}

internal void decommit_memory(void *ptr, u64 size) {
    VirtualFree(ptr, size, MEM_DECOMMIT);
}

internal void release_memory(void *ptr, [[maybe_unused]] u64 size) {
    VirtualFree(ptr, 0, MEM_RELEASE);
}
