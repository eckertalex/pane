internal void wm_event_list_push(Arena *arena, WM_EventList *list,
                                 WM_EventKind kind, WM_Window window) {
  WM_Event *event = push_array(arena, WM_Event, 1);
  event->kind = kind;
  event->window = window;
  if (list->last) {
    list->last->next = event;
  } else {
    list->first = event;
  }
  list->last = event;
}
