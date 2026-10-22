global W32_WMState w32_wm_state;
global wchar_t const *const w32_window_class_name = L"pane_window";

internal void w32_push_event(WM_EventKind kind, WM_Window window) {
    Assert(w32_wm_state.event_list != nullptr);
    wm_event_list_push(w32_wm_state.event_arena, w32_wm_state.event_list, kind,
                       window);
}

internal LRESULT CALLBACK w32_window_proc(HWND hwnd, UINT message,
                                          WPARAM wparam, LPARAM lparam) {
    switch (message) {
    case WM_CLOSE: {
        // Don't pass to DefWindowProc, it would destroy the window. The app
        // decides and calls wm_window_close.
        w32_push_event(WM_EventKind_WindowClose, (WM_Window){(u64)hwnd});
        return 0;
    }
    case WM_PAINT: {
        // Nothing renders yet, so clear to black like the other backends.
        // Without this, resizing shows whatever was on screen before.
        PAINTSTRUCT paint;
        HDC dc = BeginPaint(hwnd, &paint);
        FillRect(dc, &paint.rcPaint, (HBRUSH)GetStockObject(BLACK_BRUSH));
        EndPaint(hwnd, &paint);
        return 0;
    }
    case WM_DPICHANGED: {
        // Moved to a monitor with a different scale. Take the size Windows
        // suggests so the window keeps its physical size on screen.
        RECT const *rect = (RECT const *)lparam;
        SetWindowPos(hwnd, nullptr, rect->left, rect->top,
                     rect->right - rect->left, rect->bottom - rect->top,
                     SWP_NOZORDER | SWP_NOACTIVATE);
        return 0;
    }
    default: {
        return DefWindowProcW(hwnd, message, wparam, lparam);
    }
    }
}

internal void wm_init(void) {
    // Without this Windows scales the window as a bitmap and sizes are not in
    // physical pixels
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

    w32_wm_state.instance = GetModuleHandleW(nullptr);
    WNDCLASSEXW window_class = {
        .cbSize = sizeof(window_class),
        .style = CS_HREDRAW | CS_VREDRAW,
        .lpfnWndProc = w32_window_proc,
        .hInstance = w32_wm_state.instance,
        .hCursor = LoadCursorA(nullptr, IDC_ARROW),
        .lpszClassName = w32_window_class_name,
    };
    ATOM atom = RegisterClassExW(&window_class);
    AssertAlways(atom != 0);
}

internal WM_Window wm_window_open(char const *title, i32 width, i32 height) {
    Temp scratch = scratch_begin(nullptr, 0);
    // With -1 the count includes the terminator, so the result is
    // null-terminated
    int count = MultiByteToWideChar(CP_UTF8, 0, title, -1, nullptr, 0);
    wchar_t *title16 =
        push_array(scratch.arena, wchar_t, (u64)(count > 0 ? count : 1));
    MultiByteToWideChar(CP_UTF8, 0, title, -1, title16, count);

    // width/height are the client area, so grow the rect by the window frame
    DWORD style = WS_OVERLAPPEDWINDOW;
    RECT rect = {0, 0, width, height};
    AdjustWindowRectExForDpi(&rect, style, FALSE, 0, GetDpiForSystem());

    HWND hwnd = CreateWindowExW(
        0, w32_window_class_name, title16, style, CW_USEDEFAULT, CW_USEDEFAULT,
        rect.right - rect.left, rect.bottom - rect.top, nullptr, nullptr,
        w32_wm_state.instance, nullptr);
    AssertAlways(hwnd != nullptr);
    ShowWindow(hwnd, SW_SHOW);
    scratch_end(scratch);
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
