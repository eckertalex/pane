package pane

import "core:fmt"
import "../base"
import wm "../window_manager"

main :: proc() {
	if ODIN_DEBUG {
		fmt.println("[debug build]")
	}

	frame_arena := base.arena_alloc()
	wm.init()
	window := wm.window_open("pane", 1280, 720)
	for running := true; running; {
		base.arena_clear(frame_arena)
		events := wm.get_events(frame_arena, true)
		for event := events.first; event != nil; event = event.next {
			if event.kind == .Window_Close {
				running = false
			}
		}
	}
	wm.window_close(window)
}
