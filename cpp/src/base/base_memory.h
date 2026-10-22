#ifndef BASE_MEMORY_H
#define BASE_MEMORY_H

internal u64 page_size(void);
internal void *reserve_memory(u64 size);
internal bool commit_memory(void *ptr, u64 size);
internal void decommit_memory(void *ptr, u64 size);
internal void release_memory(void *ptr, u64 size);

#endif // BASE_MEMORY_H
