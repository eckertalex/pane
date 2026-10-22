package window_manager

import "base:runtime"
import win32 "core:sys/windows"
import "../base"

@(private = "file")
WINDOW_CLASS_NAME :: win32.wstring("pane_window")

@(private = "file")
state: struct {
	instance:    win32.HINSTANCE,
	// The window proc is called by Windows, so it runs with the context
	// captured in init
	ctx:         runtime.Context,
	// Only set while get_events runs, so the window proc knows where to push
	event_arena: ^base.Arena,
	event_list:  ^Event_List,
}

@(private = "file")
push_event :: proc(kind: Event_Kind, window: Window) {
	assert(state.event_list != nil)
	event_list_push(state.event_arena, state.event_list, kind, window)
}

@(private = "file")
window_proc :: proc "system" (
	hwnd: win32.HWND,
	message: win32.UINT,
	wparam: win32.WPARAM,
	lparam: win32.LPARAM,
) -> win32.LRESULT {
	context = state.ctx
	switch message {
	case win32.WM_CLOSE:
		// Don't pass to DefWindowProc, it would destroy the window. The app
		// decides and calls window_close.
		push_event(.Window_Close, Window(uintptr(hwnd)))
		return 0
	case win32.WM_PAINT:
		// Nothing renders yet, so clear to black like the other backends.
		// Without this, resizing shows whatever was on screen before.
		paint: win32.PAINTSTRUCT
		dc := win32.BeginPaint(hwnd, &paint)
		win32.FillRect(dc, &paint.rcPaint, win32.HBRUSH(win32.GetStockObject(win32.BLACK_BRUSH)))
		win32.EndPaint(hwnd, &paint)
		return 0
	case win32.WM_DPICHANGED:
		// Moved to a monitor with a different scale. Take the size Windows
		// suggests so the window keeps its physical size on screen.
		rect := (^win32.RECT)(uintptr(lparam))
		win32.SetWindowPos(
			hwnd,
			nil,
			rect.left,
			rect.top,
			rect.right - rect.left,
			rect.bottom - rect.top,
			win32.SWP_NOZORDER | win32.SWP_NOACTIVATE,
		)
		return 0
	}
	return win32.DefWindowProcW(hwnd, message, wparam, lparam)
}

init :: proc() {
	state.ctx = context

	// Without this Windows scales the window as a bitmap and sizes are not in
	// physical pixels
	win32.SetProcessDpiAwarenessContext(win32.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)

	state.instance = win32.HINSTANCE(win32.GetModuleHandleW(nil))
	window_class := win32.WNDCLASSEXW {
		cbSize        = size_of(win32.WNDCLASSEXW),
		style         = win32.CS_HREDRAW | win32.CS_VREDRAW,
		lpfnWndProc   = window_proc,
		hInstance     = state.instance,
		hCursor       = win32.LoadCursorA(nil, win32.IDC_ARROW),
		lpszClassName = WINDOW_CLASS_NAME,
	}
	ensure(win32.RegisterClassExW(&window_class) != 0)
}

window_open :: proc(title: string, width, height: i32) -> Window {
	scratch := base.scratch_begin()
	defer base.scratch_end(scratch)

	// The length is explicit, so the count excludes the terminator. Push one
	// more for it, zeroed by the push.
	count := win32.MultiByteToWideChar(win32.CP_UTF8, 0, raw_data(title), i32(len(title)), nil, 0)
	title16 := base.push_array(scratch.arena, u16, int(count) + 1)
	win32.MultiByteToWideChar(win32.CP_UTF8, 0, raw_data(title), i32(len(title)), raw_data(title16), count)

	// width/height are the client area, so grow the rect by the window frame
	style := win32.WS_OVERLAPPEDWINDOW
	rect := win32.RECT{0, 0, width, height}
	win32.AdjustWindowRectExForDpi(&rect, style, false, 0, win32.GetDpiForSystem())

	hwnd := win32.CreateWindowExW(
		0,
		WINDOW_CLASS_NAME,
		win32.wstring(raw_data(title16)),
		style,
		win32.CW_USEDEFAULT,
		win32.CW_USEDEFAULT,
		rect.right - rect.left,
		rect.bottom - rect.top,
		nil,
		nil,
		state.instance,
		nil,
	)
	ensure(hwnd != nil)
	win32.ShowWindow(hwnd, win32.SW_SHOW)
	return Window(uintptr(hwnd))
}

window_close :: proc(window: Window) {
	win32.DestroyWindow(win32.HWND(uintptr(window)))
}

get_events :: proc(arena: ^base.Arena, wait: bool) -> Event_List {
	list: Event_List
	state.event_arena = arena
	state.event_list = &list
	defer {
		state.event_arena = nil
		state.event_list = nil
	}

	if wait {
		win32.WaitMessage()
	}
	message: win32.MSG
	for win32.PeekMessageW(&message, nil, 0, 0, win32.PM_REMOVE) {
		win32.TranslateMessage(&message)
		win32.DispatchMessageW(&message)
	}
	return list
}
