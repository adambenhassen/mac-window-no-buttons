// Hides the native close, minimise and zoom buttons on every window of the
// host app. Replaces the host's libSystem dependency and re-exports it.

#import <AppKit/AppKit.h>
#import <objc/runtime.h>

static const NSWindowButton kButtons[] = {
    NSWindowCloseButton, NSWindowMiniaturizeButton, NSWindowZoomButton};

// AppKit and Chromium re-show the buttons on layout and fullscreen changes,
// so force -setHidden: to YES on the button classes themselves.
static void PinHidden(Class cls) {
    SEL sel = @selector(setHidden:);
    Method m = class_getInstanceMethod(cls, sel);
    void (*orig)(id, SEL, BOOL) = (void (*)(id, SEL, BOOL))method_getImplementation(m);
    IMP imp = imp_implementationWithBlock(^(id self, BOOL hidden) {
        orig(self, sel, YES);
    });
    class_replaceMethod(cls, sel, imp, method_getTypeEncoding(m));
}

static void HideButtons(NSWindow *window) {
    static NSMutableSet<Class> *pinned;
    if (!pinned) pinned = [NSMutableSet set];
    for (size_t i = 0; i < sizeof(kButtons) / sizeof(kButtons[0]); i++) {
        NSButton *button = [window standardWindowButton:kButtons[i]];
        if (!button) continue;
        if (![pinned containsObject:button.class]) {
            [pinned addObject:button.class];
            PinHidden(button.class);
        }
        button.hidden = YES;
    }
}

__attribute__((constructor)) static void Init(void) {
    NSNotificationName names[] = {
        NSWindowDidUpdateNotification,
        NSWindowDidBecomeKeyNotification,
        NSWindowDidResizeNotification,
        NSWindowDidEnterFullScreenNotification,
        NSWindowDidExitFullScreenNotification,
    };
    NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    for (size_t i = 0; i < sizeof(names) / sizeof(names[0]); i++) {
        [nc addObserverForName:names[i] object:nil queue:nil
                    usingBlock:^(NSNotification *note) {
            HideButtons(note.object);
        }];
    }
}
