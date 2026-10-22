internal u64 page_size(void) {
    return (u64)sysconf(_SC_PAGESIZE);
}

internal void *reserve_memory(u64 size) {
    void *result =
        mmap(nullptr, size, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

    if (result == MAP_FAILED) {
        result = nullptr;
    }

    return result;
}

internal bool commit_memory(void *ptr, u64 size) {
    return mprotect(ptr, size, PROT_READ | PROT_WRITE) == 0;
}

internal void decommit_memory(void *ptr, u64 size) {
    madvise(ptr, size, MADV_DONTNEED);
    mprotect(ptr, size, PROT_NONE);
}

internal void release_memory(void *ptr, u64 size) {
    munmap(ptr, size);
}
