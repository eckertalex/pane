package base

import "base:intrinsics"

ARENA_HEADER_SIZE :: 64

Arena :: struct {
	pos:      u64, // next free byte, as an offset from the arena itself
	cmt:      u64, // bytes committed so far
	res:      u64, // bytes reserved
	cmt_size: u64, // how much to commit each time we grow
}
#assert(size_of(Arena) <= ARENA_HEADER_SIZE)

Temp :: struct {
	arena: ^Arena,
	pos:   u64,
}

arena_alloc :: proc(reserve_size: u64 = 64 * MB, commit_size: u64 = 64 * KB) -> ^Arena {
	page := page_size()
	reserve := align_pow2(reserve_size, page)
	commit := align_pow2(commit_size, page)
	ensure(commit <= reserve)

	base := reserve_memory(reserve)
	ensure(base != nil)
	ensure(commit_memory(base, commit))

	arena := (^Arena)(base)
	arena^ = {
		pos      = ARENA_HEADER_SIZE,
		cmt      = commit,
		res      = reserve,
		cmt_size = commit,
	}
	return arena
}

arena_release :: proc(arena: ^Arena) {
	release_memory(arena, arena.res)
}

arena_push :: proc(arena: ^Arena, size: u64, align: u64) -> rawptr {
	assert(align != 0 && (align & (align - 1)) == 0)
	pos := align_pow2(arena.pos, align)
	ensure(pos <= arena.res && size <= arena.res - pos)
	new_pos := pos + size

	if new_pos > arena.cmt {
		new_cmt := min(align_pow2(new_pos, arena.cmt_size), arena.res)
		ensure(commit_memory(([^]u8)(arena)[arena.cmt:], new_cmt - arena.cmt))
		arena.cmt = new_cmt
	}

	result := ([^]u8)(arena)[pos:]
	intrinsics.mem_zero(result, size)
	arena.pos = new_pos
	return result
}

push_array :: proc(arena: ^Arena, $T: typeid, count: int) -> []T {
	assert(count >= 0)
	size, overflowed := intrinsics.overflow_mul(u64(size_of(T)), u64(count))
	ensure(!overflowed)
	return ([^]T)(arena_push(arena, size, align_of(T)))[:count]
}

push_struct :: proc(arena: ^Arena, $T: typeid) -> ^T {
	return (^T)(arena_push(arena, size_of(T), align_of(T)))
}

arena_pos :: proc(arena: ^Arena) -> u64 {
	return arena.pos
}

arena_pop_to :: proc(arena: ^Arena, pos: u64) {
	clamped := max(pos, ARENA_HEADER_SIZE)
	assert(clamped <= arena.pos)
	arena.pos = clamped
}

arena_clear :: proc(arena: ^Arena) {
	arena_pop_to(arena, 0)
}

temp_begin :: proc(arena: ^Arena) -> Temp {
	return {arena = arena, pos = arena_pos(arena)}
}

temp_end :: proc(temp: Temp) {
	arena_pop_to(temp.arena, temp.pos)
}

@(thread_local)
scratch_arenas: [2]^Arena

// Pass the arenas the caller allocates its results in, so the scratch arena
// is never one of them
scratch_begin :: proc(conflicts: ..^Arena) -> Temp {
	if scratch_arenas[0] == nil {
		for &arena in scratch_arenas {
			arena = arena_alloc()
		}
	}

	for candidate in scratch_arenas {
		conflicted := false
		for conflict in conflicts {
			if conflict == candidate {
				conflicted = true
			}
		}
		if !conflicted {
			return temp_begin(candidate)
		}
	}
	panic("every scratch arena conflicts")
}

scratch_end :: temp_end
