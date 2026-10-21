#ifndef BASE_ARENA_H
#define BASE_ARENA_H

// One fixed-size block. The Arena header lives at the start of the block, so
// pushes start right after it.
typedef struct Arena {
  u64 pos;
  u64 cap;
} Arena;

internal Arena *arena_alloc(u64 cap);
internal void *arena_push(Arena *arena, u64 size, u64 align);
internal void arena_clear(Arena *arena);

#define push_array(arena, T, count) (T *)arena_push((arena), sizeof(T) * (count), alignof(T))

#endif // BASE_ARENA_H
