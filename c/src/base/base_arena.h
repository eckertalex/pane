#ifndef BASE_ARENA_H
#define BASE_ARENA_H

global constexpr u64 ARENA_HEADER_SIZE = 64;

typedef struct Arena {
    u64 pos;      // next free byte, as an offset from the arena itself
    u64 cmt;      // bytes committed so far
    u64 res;      // bytes reserved
    u64 cmt_size; // how much to commit each time we grow
} Arena;
static_assert(sizeof(Arena) <= ARENA_HEADER_SIZE);

typedef struct ArenaParams {
    u64 reserve_size;
    u64 commit_size;
} ArenaParams;

internal Arena *arena_alloc_(ArenaParams params);
// arena_alloc() for defaults, arena_alloc(.reserve_size = GB(1)) to override
#define arena_alloc(...) arena_alloc_((ArenaParams){__VA_ARGS__})
internal void arena_release(Arena *arena);
internal void *arena_push(Arena *arena, u64 size, u64 align);
internal void arena_clear(Arena *arena);

internal u64 array_size(u64 size, u64 count);
#define push_array(arena, T, count)                                            \
    (T *)arena_push((arena), array_size(sizeof(T), (count)), alignof(T))

typedef struct Temp {
    Arena *arena;
    u64 pos;
} Temp;

internal u64 arena_pos(Arena *arena);
internal void arena_pop_to(Arena *arena, u64 pos);

internal Temp temp_begin(Arena *arena);
internal void temp_end(Temp temp);

internal Temp scratch_begin(Arena **conflicts, u64 count);
#define scratch_end(temp) temp_end(temp)

#endif // BASE_ARENA_H
