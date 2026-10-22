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

// MADV_DONTNEED is only a hint on macOS and can leave the old contents in
// place. Mapping fresh pages over the range really frees them and guarantees
// zeros on the next commit.
internal void decommit_memory(void *ptr, u64 size) {
    mmap(ptr, size, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
}

internal void release_memory(void *ptr, u64 size) {
    munmap(ptr, size);
}
