package window_manager

import "base:intrinsics"
import NS "core:sys/darwin/Foundation"
import "../base"

@(private = "file")
state: struct {
	// One delegate shared by every window, each callback gets the window
	window_delegate: ^NS.WindowDelegate,
	// Only set while get_events runs, so callbacks know where to push events
	event_arena:     ^base.Arena,
	event_list:      ^Event_List,
}

@(private = "file")
push_event :: proc(kind: Event_Kind, window: Window) {
	assert(state.event_list != nil)
	event_list_push(state.event_arena, state.event_list, kind, window)
}

init :: proc() {
	NS.scoped_autoreleasepool()
	app := NS.Application_sharedApplication()
	NS.Application_setActivationPolicy(app, .Regular)

	// Cmd+Q, Dock Quit and logout land here. Report it and let the app decide
	// instead of letting AppKit call exit() on us.
	app_delegate := NS.application_delegate_register_and_alloc(
		{
			applicationShouldTerminate = proc(sender: ^NS.Application) -> NS.ApplicationTerminateReply {
				push_event(.Window_Close, 0)
				return .TerminateCancel
			},
		},
		"Pane_AppDelegate",
		context,
	)
	NS.Application_setDelegate(app, app_delegate)

	state.window_delegate = NS.window_delegate_register_and_alloc(
		{
			windowShouldClose = proc(sender: ^NS.Window) -> NS.BOOL {
				push_event(.Window_Close, Window(uintptr(sender)))
				return false
			},
		},
		"Pane_WindowDelegate",
		context,
	)

	// Without a main menu there is no Cmd+Q
	main_menu := NS.Menu_init(NS.Menu_alloc())
	app_item := NS.MenuItem_init(NS.MenuItem_alloc())
	app_menu := NS.Menu_init(NS.Menu_alloc())
	app_name := NS.ProcessInfo_processName(NS.ProcessInfo_processInfo())
	NS.Menu_addItemWithTitle(
		app_menu,
		NS.String_stringByAppendingString(NS.AT("Quit "), app_name),
		intrinsics.objc_find_selector("terminate:"),
		NS.AT("q"),
	)
	NS.MenuItem_setSubmenu(app_item, app_menu)
	NS.Menu_addItem(main_menu, app_item)
	NS.Application_setMainMenu(app, main_menu)
	NS.release(app_menu)
	NS.release(app_item)
	NS.release(main_menu)

	NS.Application_finishLaunching(app)
}

window_open :: proc(title: string, width, height: i32) -> Window {
	NS.scoped_autoreleasepool()

	// AppKit sizes windows in points, the API takes pixels
	scale := NS.Screen_backingScaleFactor(NS.Screen_mainScreen())
	rect := NS.Rect {
		size = {width = NS.Float(width) / scale, height = NS.Float(height) / scale},
	}
	style := NS.WindowStyleMask{.Titled, .Closable, .Miniaturizable, .Resizable}
	window := NS.Window_initWithContentRect(NS.Window_alloc(), rect, style, .Buffered, false)
	ensure(window != nil)
	NS.Window_setReleasedWhenClosed(window, false)

	// nil for invalid UTF-8, and setTitle: throws on nil. The window copies
	// the title, so the string can be released right away.
	title_string := NS.String_initWithOdinString(NS.String_alloc(), title)
	if title_string != nil {
		NS.Window_setTitle(window, title_string)
		NS.release(title_string)
	} else {
		NS.Window_setTitle(window, NS.AT(""))
	}

	NS.Window_setBackgroundColor(window, NS.Color_blackColor())
	NS.Window_setDelegate(window, state.window_delegate)
	NS.Window_center(window)
	NS.Window_makeKeyAndOrderFront(window, nil)
	NS.Application_activate(NS.Application_sharedApplication())
	return Window(uintptr(window))
}

window_close :: proc(handle: Window) {
	window := (^NS.Window)(uintptr(handle))
	NS.Window_setDelegate(window, nil)
	NS.Window_close(window)
	NS.release(window)
}

get_events :: proc(arena: ^base.Arena, wait: bool) -> Event_List {
	list: Event_List
	state.event_arena = arena
	state.event_list = &list
	defer {
		state.event_arena = nil
		state.event_list = nil
	}

	NS.scoped_autoreleasepool()
	app := NS.Application_sharedApplication()
	// Block for the first event only, then drain whatever else is pending
	until := wait ? NS.Date_distantFuture() : nil
	for {
		event := NS.Application_nextEventMatchingMask(app, NS.EventMaskAny, until, NS.DefaultRunLoopMode, true)
		if event == nil {
			break
		}
		NS.Application_sendEvent(app, event)
		until = nil
	}
	return list
}
