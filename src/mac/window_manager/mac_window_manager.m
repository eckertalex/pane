// Apple's system headers use `internal` and `global` as identifiers, which
// collide with our base keyword macros. Hide the macros around the import.
#pragma push_macro("internal")
#pragma push_macro("global")
#undef internal
#undef global
#import <Cocoa/Cocoa.h>
#pragma pop_macro("global")
#pragma pop_macro("internal")

// Only set while wm_get_events runs, so callbacks know where to push events
typedef struct MAC_WMState {
  Arena *event_arena;
  WM_EventList *event_list;
} MAC_WMState;

global MAC_WMState mac_wm_state;

@interface MAC_WindowDelegate : NSObject <NSWindowDelegate>
@end

@implementation MAC_WindowDelegate
- (BOOL)windowShouldClose:(NSWindow *)sender {
  if (mac_wm_state.event_list != nullptr) {
    wm_event_list_push(mac_wm_state.event_arena, mac_wm_state.event_list,
                       WM_EventKind_WindowClose, (WM_Window){(u64)sender});
  }
  return NO;
}
@end

internal void wm_init(void) {
  [NSApplication sharedApplication];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  [NSApp finishLaunching];
}

internal WM_Window wm_window_open(char const *title, i32 width, i32 height) {
  NSWindowStyleMask style =
      NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
      NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;
  NSWindow *window =
      [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, width, height)
                                  styleMask:style
                                    backing:NSBackingStoreBuffered
                                      defer:NO];
  [window setReleasedWhenClosed:NO];
  [window setTitle:[NSString stringWithUTF8String:title]];
  [window setDelegate:[[MAC_WindowDelegate alloc] init]];
  [window center];
  [window makeKeyAndOrderFront:nil];
  [NSApp activate];
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
