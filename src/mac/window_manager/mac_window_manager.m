global MAC_WMState mac_wm_state;

internal void mac_push_event(WM_EventKind kind, WM_Window window) {
    Assert(mac_wm_state.event_list != nullptr);
    wm_event_list_push(mac_wm_state.event_arena, mac_wm_state.event_list, kind,
                       window);
}

@implementation MAC_AppDelegate
// Cmd+Q, Dock Quit and logout land here. Report it and let the app decide
// instead of letting AppKit call exit() on us.
- (NSApplicationTerminateReply)applicationShouldTerminate:
    (NSApplication *)sender {
    mac_push_event(WM_EventKind_WindowClose, (WM_Window){0});
    return NSTerminateCancel;
}
@end

@implementation MAC_WindowDelegate
- (BOOL)windowShouldClose:(NSWindow *)sender {
    mac_push_event(WM_EventKind_WindowClose, (WM_Window){(u64)sender});
    return NO;
}
@end

internal void wm_init(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        mac_wm_state.app_delegate = [[MAC_AppDelegate alloc] init];
        [NSApp setDelegate:mac_wm_state.app_delegate];

        // Without a main menu there is no Cmd+Q
        NSMenu *main_menu = [[NSMenu alloc] init];
        NSMenuItem *app_item = [[NSMenuItem alloc] init];
        NSMenu *app_menu = [[NSMenu alloc] init];
        NSString *app_name = [[NSProcessInfo processInfo] processName];
        [app_menu addItemWithTitle:[@"Quit " stringByAppendingString:app_name]
                            action:@selector(terminate:)
                     keyEquivalent:@"q"];
        [app_item setSubmenu:app_menu];
        [main_menu addItem:app_item];
        [NSApp setMainMenu:main_menu];
        [app_menu release];
        [app_item release];
        [main_menu release];

        [NSApp finishLaunching];
    }
}

internal WM_Window wm_window_open(char const *title, i32 width, i32 height) {
    NSWindow *window = nil;
    @autoreleasepool {
        // AppKit sizes windows in points, the API takes pixels
        CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
        NSRect rect =
            NSMakeRect(0, 0, (CGFloat)width / scale, (CGFloat)height / scale);
        NSWindowStyleMask style =
            NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
            NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;
        window = [[NSWindow alloc] initWithContentRect:rect
                                             styleMask:style
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
        AssertAlways(window != nil);
        [window setReleasedWhenClosed:NO];
        // nil for invalid UTF-8, and setTitle: throws on nil
        NSString *title_string = [NSString stringWithUTF8String:title];
        [window setTitle:title_string != nil ? title_string : @""];
        [window setBackgroundColor:[NSColor blackColor]];
        [window setDelegate:[[MAC_WindowDelegate alloc] init]];
        [window center];
        [window makeKeyAndOrderFront:nil];
        [NSApp activate];
    }
    return (WM_Window){(u64)window};
}

internal void wm_window_close(WM_Window handle) {
    NSWindow *window = (NSWindow *)handle.v[0];
    id delegate = [window delegate];
    [window setDelegate:nil];
    [delegate release];
    [window close];
    [window release];
}

internal WM_EventList wm_get_events(Arena *arena, bool wait) {
    WM_EventList list = {0};
    mac_wm_state.event_arena = arena;
    mac_wm_state.event_list = &list;

    @autoreleasepool {
        // Block for the first event only, then drain whatever else is pending
        NSDate *until = wait ? [NSDate distantFuture] : nil;
        for (;;) {
            NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                                untilDate:until
                                                   inMode:NSDefaultRunLoopMode
                                                  dequeue:YES];
            if (event == nil) {
                break;
            }
            [NSApp sendEvent:event];
            until = nil;
        }
    }

    mac_wm_state.event_arena = nullptr;
    mac_wm_state.event_list = nullptr;
    return list;
}
