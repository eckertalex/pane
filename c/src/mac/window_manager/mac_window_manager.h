#ifndef MAC_WINDOW_MANAGER_H
#define MAC_WINDOW_MANAGER_H

// Apple's system headers use `internal` and `global` as identifiers, which
// collide with our base keyword macros. Hide the macros around the import.
#pragma push_macro("internal")
#pragma push_macro("global")
#undef internal
#undef global
#import <Cocoa/Cocoa.h>
#pragma pop_macro("global")
#pragma pop_macro("internal")

// Built without ARC, so ownership is manual. Each window owns its delegate and
// both are released in wm_window_close. The app delegate lives until exit.
@interface MAC_AppDelegate : NSObject <NSApplicationDelegate>
@end

@interface MAC_WindowDelegate : NSObject <NSWindowDelegate>
@end

typedef struct MAC_WMState {
    MAC_AppDelegate *app_delegate;
    // Only set while wm_get_events runs, so callbacks know where to push events
    Arena *event_arena;
    WM_EventList *event_list;
} MAC_WMState;

#endif // MAC_WINDOW_MANAGER_H
