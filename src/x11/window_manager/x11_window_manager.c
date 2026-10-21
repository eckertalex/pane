#include <string.h>
#include <X11/Xlib.h>

typedef struct X11_WMState {
    Display *display;
    Atom wm_protocols;
    Atom wm_delete_window;
    Atom net_wm_name;
    Atom utf8_string;
} X11_WMState;

global X11_WMState x11_wm_state;

internal void wm_init(void) {
    x11_wm_state.display = XOpenDisplay(nullptr);
    AssertAlways(x11_wm_state.display != nullptr);

    x11_wm_state.wm_protocols = XInternAtom(x11_wm_state.display, "WM_PROTOCOLS", False);
    x11_wm_state.wm_delete_window = XInternAtom(x11_wm_state.display, "WM_DELETE_WINDOW", False);
    x11_wm_state.net_wm_name = XInternAtom(x11_wm_state.display, "_NET_WM_NAME", False);
    x11_wm_state.utf8_string = XInternAtom(x11_wm_state.display, "UTF8_STRING", False);
}

internal WM_Window wm_window_open(char const *title, i32 width, i32 height) {
    Display *display = x11_wm_state.display;
    int screen = DefaultScreen(display);
    Window root = RootWindow(display, screen);

    Window window = XCreateSimpleWindow(display, root, 0, 0,
                                        (u32)width, (u32)height, 0,
                                        BlackPixel(display, screen),
                                        BlackPixel(display, screen));
    XStoreName(display, window, title);

    // Ask the window manager for a ClientMessage instead of killing the
    // connection when the user closes the window
    XSetWMProtocols(display, window, &x11_wm_state.wm_delete_window, 1);
    XChangeProperty(display, window, x11_wm_state.net_wm_name,
                    x11_wm_state.utf8_string, 8, PropModeReplace,
                    (unsigned char const *)title, (int)strlen(title));
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

    // XNextEvent blocks for the first event, then drain whatever else is pending
    while (wait || XPending(display) > 0) {
        wait = false;
        XEvent event;
        XNextEvent(display, &event);

        switch(event.type) {
        case ClientMessage: {
            if (event.xclient.message_type == x11_wm_state.wm_protocols &&
                (Atom)event.xclient.data.l[0] == x11_wm_state.wm_delete_window) {
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
