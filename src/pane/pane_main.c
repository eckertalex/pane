// includes
#include <stdio.h>
#include "base/base_inc.h"
#include "window_manager/window_manager_inc.h"

// implementations
#include "base/base_inc.c"
#include "window_manager/window_manager_inc.c"

int main([[maybe_unused]] int argc, [[maybe_unused]] char **argv) {
    if(BUILD_DEBUG) {
        printf("[debug build]\n");
    }

    Arena *frame_arena = arena_alloc(MB(64));
    wm_init();
    WM_Window window = wm_window_open("pane", 1280, 720);
    for (bool running = true; running;) {
        arena_clear(frame_arena);
        WM_EventList events = wm_get_events(frame_arena, true);
        for (WM_Event *event = events.first; event != nullptr; event = event->next) {
            if(event->kind == WM_EventKind_WindowClose) {
                running = false;
            }
        }
    }
    wm_window_close(window);

    return 0;
}
