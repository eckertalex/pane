package window_manager

import "base:runtime"
import "core:fmt"
import x "vendor:x11/xlib"
import "../base"

@(private = "file")
state: struct {
	display:          ^x.Display,
	wm_protocols:     x.Atom,
	wm_delete_window: x.Atom,
	net_wm_name:      x.Atom,
	utf8_string:      x.Atom,
	// The error handler is called by Xlib, so it runs with the context
	// captured in init
	ctx:              runtime.Context,
}

// The default handler prints the error and calls exit(), so one bad request
// would end the app behind its back. Log it and keep going instead. Losing the
// connection itself still exits: Xlib requires its IO error handler to never
// return, and without a display there is nothing left to recover.
@(private = "file")
error_handler :: proc "c" (display: ^x.Display, event: ^x.XErrorEvent) -> i32 {
	context = state.ctx
	text: [256]u8
	x.GetErrorText(display, i32(event.error_code), raw_data(&text), len(text))
	fmt.eprintfln("X11 error: %s (request %d)", cstring(raw_data(&text)), event.request_code)
	return 0
}

init :: proc() {
	state.ctx = context
	x.SetErrorHandler(error_handler)
	state.display = x.OpenDisplay(nil)
	ensure(state.display != nil)

	state.wm_protocols = x.InternAtom(state.display, "WM_PROTOCOLS", false)
	state.wm_delete_window = x.InternAtom(state.display, "WM_DELETE_WINDOW", false)
	state.net_wm_name = x.InternAtom(state.display, "_NET_WM_NAME", false)
	state.utf8_string = x.InternAtom(state.display, "UTF8_STRING", false)
}

window_open :: proc(title: string, width, height: i32) -> Window {
	display := state.display
	screen := x.DefaultScreen(display)
	root := x.RootWindow(display, screen)

	// Creation failures arrive asynchronously through error_handler
	window := x.CreateSimpleWindow(
		display,
		root,
		0,
		0,
		u32(width),
		u32(height),
		0,
		x.BlackPixel(display, screen),
		x.BlackPixel(display, screen),
	)

	// Xlib wants a terminated string, the push zeroes the extra byte
	scratch := base.scratch_begin()
	defer base.scratch_end(scratch)
	title_bytes := base.push_array(scratch.arena, u8, len(title) + 1)
	copy(title_bytes, title)
	title_cstring := cstring(raw_data(title_bytes))

	// WM_NAME converted from UTF-8 for window managers that only read the old
	// property, plus WM_CLASS so taskbars can group and name the window
	class_hint := x.XClassHint {
		res_name  = "pane",
		res_class = "pane",
	}
	x.utf8SetWMProperties(display, window, title_cstring, title_cstring, nil, 0, nil, nil, &class_hint)
	// Modern window managers read the title from here, as UTF-8
	x.ChangeProperty(
		display,
		window,
		state.net_wm_name,
		state.utf8_string,
		8,
		x.PropModeReplace,
		raw_data(title),
		i32(len(title)),
	)

	// Ask the window manager for a ClientMessage instead of killing the
	// connection when the user closes the window
	x.SetWMProtocols(display, window, &state.wm_delete_window, 1)
	x.MapWindow(display, window)
	x.Flush(display)
	return Window(window)
}

window_close :: proc(window: Window) {
	x.DestroyWindow(state.display, x.Window(window))
	x.Flush(state.display)
}

get_events :: proc(arena: ^base.Arena, wait: bool) -> Event_List {
	list: Event_List
	display := state.display

	// NextEvent blocks for the first event, then drain whatever else is pending
	wait := wait
	for wait || x.Pending(display) > 0 {
		wait = false
		event: x.XEvent
		x.NextEvent(display, &event)

		#partial switch event.type {
		case .ClientMessage:
			if event.xclient.message_type == state.wm_protocols &&
			   x.Atom(event.xclient.data.l[0]) == state.wm_delete_window {
				event_list_push(arena, &list, .Window_Close, Window(event.xclient.window))
			}
		}
	}
	return list
}
