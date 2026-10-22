package base

import "core:testing"

@(test)
decommit_returns_zeroed_pages :: proc(t: ^testing.T) {
	page := page_size()
	memory := ([^]u8)(reserve_memory(64 * GB))
	testing.expect(t, memory != nil)
	defer release_memory(memory, 64 * GB)

	testing.expect(t, commit_memory(memory, page))
	memory[0] = 42
	decommit_memory(memory, page)
	testing.expect(t, commit_memory(memory, page))
	testing.expect_value(t, memory[0], 0)
}

@(test)
push_commits_past_the_first_chunk :: proc(t: ^testing.T) {
	arena := arena_alloc()
	defer arena_release(arena)

	big := push_array(arena, u8, MB)
	big[MB - 1] = 7
	testing.expect(t, arena.cmt >= arena.pos)
	testing.expect_value(t, arena.cmt % (64 * KB), 0)
}

@(test)
push_aligns_to_the_requested_boundary :: proc(t: ^testing.T) {
	arena := arena_alloc()
	defer arena_release(arena)

	push_array(arena, u8, 1)
	aligned := arena_push(arena, 16, 4096)
	testing.expect_value(t, uintptr(aligned) & 4095, 0)
}

@(test)
temp_end_frees_and_push_rezeroes :: proc(t: ^testing.T) {
	arena := arena_alloc()
	defer arena_release(arena)

	keep := push_struct(arena, u64)
	keep^ = 7
	before := arena_pos(arena)

	temp := temp_begin(arena)
	scratch := push_array(arena, u8, 200 * KB)
	scratch[0] = 1
	temp_end(temp)

	testing.expect_value(t, arena_pos(arena), before)
	testing.expect_value(t, keep^, 7)
	reused := push_array(arena, u8, 1)
	testing.expect(t, raw_data(reused) == raw_data(scratch))
	testing.expect_value(t, reused[0], 0)
}

@(test)
clear_keeps_the_header :: proc(t: ^testing.T) {
	arena := arena_alloc()
	defer arena_release(arena)

	push_array(arena, u8, 100)
	arena_clear(arena)
	testing.expect_value(t, arena_pos(arena), ARENA_HEADER_SIZE)
}

@(test)
scratch_avoids_conflicting_arenas :: proc(t: ^testing.T) {
	outer := scratch_begin()
	defer scratch_end(outer)
	keep := push_struct(outer.arena, u64)
	keep^ = 7

	inner := scratch_begin(outer.arena)
	testing.expect(t, inner.arena != outer.arena)
	tmp := push_array(inner.arena, u64, 1000)
	tmp[999] = 1
	scratch_end(inner)

	testing.expect_value(t, keep^, 7)
}
