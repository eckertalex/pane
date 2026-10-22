#ifndef X11_WINDOW_MANAGER_H
#define X11_WINDOW_MANAGER_H

#include <X11/Xlib.h>
#include <X11/Xutil.h>

typedef struct X11_WMState {
    Display *display;
    Atom wm_protocols;
    Atom wm_delete_window;
    Atom net_wm_name;
    Atom utf8_string;
} X11_WMState;

#endif // X11_WINDOW_MANAGER_H
