package window_manager

import "../base"

// The OS window handle. A zero window means the OS asked the whole app to quit
// (Cmd+Q, Dock Quit).
Window :: distinct u64

Event_Kind :: enum {
	Null,
	Window_Close,
}

Event :: struct {
	next:   ^Event,
	kind:   Event_Kind,
	window: Window,
}

Event_List :: struct {
	first: ^Event,
	last:  ^Event,
}

event_list_push :: proc(arena: ^base.Arena, list: ^Event_List, kind: Event_Kind, window: Window) {
	event := base.push_struct(arena, Event)
	event.kind = kind
	event.window = window
	if list.last != nil {
		list.last.next = event
	} else {
		list.first = event
	}
	list.last = event
}

// Implemented per backend in window_manager_<os>.odin:
//
// init :: proc()
// window_open :: proc(title: string, width, height: i32) -> Window
//     width/height are the client area in physical pixels on every OS
// window_close :: proc(window: Window)
// get_events :: proc(arena: ^base.Arena, wait: bool) -> Event_List
//     Events are allocated in `arena`. With `wait`, blocks until the OS has
//     something for us instead of returning an empty list right away.
