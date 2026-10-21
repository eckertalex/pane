#ifndef WINDOW_MANAGER_H
#define WINDOW_MANAGER_H

typedef struct WM_Window { u64 v[1]; } WM_Window;

typedef enum WM_EventKind {
  WM_EventKind_Null,
  WM_EventKind_WindowClose,
  WM_EventKind_COUNT,
} WM_EventKind;

typedef struct WM_Event WM_Event;
struct WM_Event {
  WM_Event *next;
  WM_EventKind kind;
  WM_Window window;
};

typedef struct WM_EventList {
  WM_Event *first;
  WM_Event *last;
} WM_EventList;

// Shared, implemented once in window_manager.c
internal void wm_event_list_push(Arena *arena, WM_EventList *list,
                                 WM_EventKind kind, WM_Window window);

// Per backend
internal void wm_init(void);
internal WM_Window wm_window_open(char const *title, i32 width, i32 height);
internal void wm_window_close(WM_Window window);
// Events are allocated in `arena`. With `wait`, blocks until the OS has
// something for us instead of returning an empty list right away.
internal WM_EventList wm_get_events(Arena *arena, bool wait);

#endif // WINDOW_MANAGER_H
