#ifndef WIN32_WINDOW_MANAGER_H
#define WIN32_WINDOW_MANAGER_H

#pragma comment(lib, "user32")
#pragma comment(lib, "gdi32")

typedef struct W32_WMState {
    HINSTANCE instance;
    // Only set while wm_get_events runs, so the window proc knows where to push
    Arena *event_arena;
    WM_EventList *event_list;
} W32_WMState;

#endif // WIN32_WINDOW_MANAGER_H
