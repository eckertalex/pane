#include <stdlib.h>
#include <string.h>

internal Arena *arena_alloc(u64 cap) {
  Assert(cap > sizeof(Arena));
  Arena *arena = malloc(cap);
  AssertAlways(arena != nullptr);
  arena->pos = sizeof(Arena);
  arena->cap = cap;
  return arena;
}

internal void *arena_push(Arena *arena, u64 size, u64 align) {
  u64 pos = AlignPow2(arena->pos, align);
  AssertAlways(pos + size <= arena->cap);
  void *result = (u8 *)arena + pos;
  memset(result, 0, size);
  arena->pos = pos + size;
  return result;
}

internal void arena_clear(Arena *arena) {
    arena->pos = sizeof(Arena);
}
