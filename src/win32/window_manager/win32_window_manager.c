#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>

typedef struct W32_WMState {
  HINSTANCE instance;
  // Only set while wm_get_events runs, so the window proc knows where to push
  Arena *event_arena;
  WM_EventList *event_list;
} W32_WMState;

global W32_WMState w32_wm_state;
global wchar_t const *w32_window_class_name = L"pane_window";

internal LRESULT CALLBACK w32_window_proc(HWND hwnd, UINT message,
                                          WPARAM wparam, LPARAM lparam) {
  switch (message) {
  case WM_CLOSE: {
    // Don't pass to DefWindowProc, it would destroy the window. The app
    // decides and calls wm_window_close.
    if (w32_wm_state.event_list != nullptr) {
      wm_event_list_push(w32_wm_state.event_arena, w32_wm_state.event_list,
                         WM_EventKind_WindowClose, (WM_Window){(u64)hwnd});
    }
    return 0;
  }
  default: {
    return DefWindowProcW(hwnd, message, wparam, lparam);
  }
  }
}

internal void wm_init(void) {
  w32_wm_state.instance = GetModuleHandleW(nullptr);
  WNDCLASSEXW window_class = {
      .cbSize = sizeof(window_class),
      .lpfnWndProc = w32_window_proc,
      .hInstance = w32_wm_state.instance,
      .hCursor = LoadCursorA(nullptr, IDC_ARROW),
      .lpszClassName = w32_window_class_name,
  };
  ATOM atom = RegisterClassExW(&window_class);
  AssertAlways(atom != 0);
}

internal WM_Window wm_window_open(char const *title, i32 width, i32 height) {
  wchar_t title16[256];
  if (MultiByteToWideChar(CP_UTF8, 0, title, -1, title16,
                          (int)ArrayCount(title16)) == 0) {
    title16[0] = 0;
  }

  // width/height are the client area, like NSWindow's contentRect
  DWORD style = WS_OVERLAPPEDWINDOW;
  RECT rect = {0, 0, width, height};
  AdjustWindowRect(&rect, style, FALSE);

  HWND hwnd = CreateWindowExW(0, w32_window_class_name, title16, style,
                              CW_USEDEFAULT, CW_USEDEFAULT,
                              rect.right - rect.left, rect.bottom - rect.top,
                              nullptr, nullptr, w32_wm_state.instance,
                              nullptr);
  AssertAlways(hwnd != nullptr);
  ShowWindow(hwnd, SW_SHOW);
  return (WM_Window){(u64)hwnd};
}

internal void wm_window_close(WM_Window window) {
  DestroyWindow((HWND)window.v[0]);
}

internal WM_EventList wm_get_events(Arena *arena, bool wait) {
  WM_EventList list = {0};
  w32_wm_state.event_arena = arena;
  w32_wm_state.event_list = &list;

  if (wait) {
    WaitMessage();
  }
  MSG message;
  while (PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE)) {
    TranslateMessage(&message);
    DispatchMessageW(&message);
  }

  w32_wm_state.event_arena = nullptr;
  w32_wm_state.event_list = nullptr;
  return list;
}
