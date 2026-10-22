global X11_WMState x11_wm_state;

// The default handler prints the error and calls exit(), so one bad request
// would end the app behind its back. Log it and keep going instead. Losing the
// connection itself still exits: Xlib requires its IO error handler to never
// return, and without a display there is nothing left to recover.
internal int x11_error_handler(Display *display, XErrorEvent *event) {
    char text[256];
    XGetErrorText(display, event->error_code, text, (int)ArrayCount(text));
    fprintf(stderr, "X11 error: %s (request %d)\n", text, event->request_code);
    return 0;
}

internal void wm_init(void) {
    XSetErrorHandler(x11_error_handler);
    x11_wm_state.display = XOpenDisplay(nullptr);
    AssertAlways(x11_wm_state.display != nullptr);

    Display *display = x11_wm_state.display;
    x11_wm_state.wm_protocols = XInternAtom(display, "WM_PROTOCOLS", False);
    x11_wm_state.wm_delete_window =
        XInternAtom(display, "WM_DELETE_WINDOW", False);
    x11_wm_state.net_wm_name = XInternAtom(display, "_NET_WM_NAME", False);
    x11_wm_state.utf8_string = XInternAtom(display, "UTF8_STRING", False);
}

internal WM_Window wm_window_open(char const *title, i32 width, i32 height) {
    Display *display = x11_wm_state.display;
    int screen = DefaultScreen(display);
    Window root = RootWindow(display, screen);

    // Creation failures arrive asynchronously through x11_error_handler
    Window window = XCreateSimpleWindow(
        display, root, 0, 0, (u32)width, (u32)height, 0,
        BlackPixel(display, screen), BlackPixel(display, screen));

    // WM_NAME converted from UTF-8 for window managers that only read the old
    // property, plus WM_CLASS so taskbars can group and name the window
    XClassHint class_hint = {.res_name = "pane", .res_class = "pane"};
    Xutf8SetWMProperties(display, window, title, title, nullptr, 0, nullptr,
                         nullptr, &class_hint);
    // Modern window managers read the title from here, as UTF-8
    XChangeProperty(display, window, x11_wm_state.net_wm_name,
                    x11_wm_state.utf8_string, 8, PropModeReplace,
                    (unsigned char const *)title, (int)strlen(title));

    // Ask the window manager for a ClientMessage instead of killing the
    // connection when the user closes the window
    XSetWMProtocols(display, window, &x11_wm_state.wm_delete_window, 1);
    XMapWindow(display, window);
    XFlush(display);
    return (WM_Window){(u64)window};
}

internal void wm_window_close(WM_Window window) {
    XDestroyWindow(x11_wm_state.display, (Window)window.v[0]);
    XFlush(x11_wm_state.display);
}

internal WM_EventList wm_get_events(Arena *arena, bool wait) {
    WM_EventList list = {0};
    Display *display = x11_wm_state.display;

    // XNextEvent blocks for the first event, then drain whatever else is
    // pending
    while (wait || XPending(display) > 0) {
        wait = false;
        XEvent event;
        XNextEvent(display, &event);

        switch (event.type) {
        case ClientMessage: {
            if (event.xclient.message_type == x11_wm_state.wm_protocols &&
                (Atom)event.xclient.data.l[0] ==
                    x11_wm_state.wm_delete_window) {
                wm_event_list_push(arena, &list, WM_EventKind_WindowClose,
                                   (WM_Window){(u64)event.xclient.window});
            }
        } break;
        default: {
        } break;
        }
    }

    return list;
}
