internal Arena *arena_alloc_(ArenaParams params) {
    u64 page = page_size();
    u64 reserve = params.reserve_size != 0 ? params.reserve_size : MB(64);
    u64 commit = params.commit_size != 0 ? params.commit_size : KB(64);
    reserve = AlignPow2(reserve, page);
    commit = AlignPow2(commit, page);
    AssertAlways(commit <= reserve);

    void *base = reserve_memory(reserve);
    AssertAlways(base != nullptr);
    AssertAlways(commit_memory(base, commit));

    Arena *arena = base;
    arena->pos = ARENA_HEADER_SIZE;
    arena->cmt = commit;
    arena->res = reserve;
    arena->cmt_size = commit;
    return arena;
}

internal void *arena_push(Arena *arena, u64 size, u64 align) {
    Assert(align != 0 && (align & (align - 1)) == 0);
    u64 pos = AlignPow2(arena->pos, align);
    AssertAlways(pos <= arena->res && size <= arena->res - pos);
    u64 new_pos = pos + size;

    if (new_pos > arena->cmt) {
        u64 new_cmt = AlignPow2(new_pos, arena->cmt_size);
        if (new_cmt > arena->res) {
            new_cmt = arena->res;
        }
        AssertAlways(
            commit_memory((u8 *)arena + arena->cmt, new_cmt - arena->cmt));
        arena->cmt = new_cmt;
    }

    void *result = (u8 *)arena + pos;
    MemoryZero(result, size);
    arena->pos = new_pos;
    return result;
}

internal void arena_release(Arena *arena) {
    release_memory(arena, arena->res);
}

internal void arena_clear(Arena *arena) {
    arena_pop_to(arena, 0);
}

internal u64 array_size(u64 size, u64 count) {
    u64 result;
    AssertAlways(!ckd_mul(&result, size, count));
    return result;
}

internal u64 arena_pos(Arena *arena) {
    return arena->pos;
}

internal void arena_pop_to(Arena *arena, u64 pos) {
    if (pos < ARENA_HEADER_SIZE) {
        pos = ARENA_HEADER_SIZE;
    }
    Assert(pos <= arena->pos);
    arena->pos = pos;
}

internal Temp temp_begin(Arena *arena) {
    return (Temp){.arena = arena, .pos = arena_pos(arena)};
}

internal void temp_end(Temp temp) {
    arena_pop_to(temp.arena, temp.pos);
}

thread_local Arena *scratch_arenas[2];

internal Temp scratch_begin(Arena **conflicts, u64 count) {
    if (scratch_arenas[0] == nullptr) {
        for (u64 i = 0; i < ArrayCount(scratch_arenas); i += 1) {
            scratch_arenas[i] = arena_alloc();
        }
    }

    Arena *result = nullptr;
    for (u64 i = 0; i < ArrayCount(scratch_arenas) && result == nullptr;
         i += 1) {
        Arena *candidate = scratch_arenas[i];
        bool conflicted = false;
        for (u64 j = 0; j < count; j += 1) {
            if (conflicts[j] == candidate) {
                conflicted = true;
            }
        }

        if (!conflicted) {
            result = candidate;
        }
    }

    AssertAlways(result != nullptr);
    return temp_begin(result);
}
