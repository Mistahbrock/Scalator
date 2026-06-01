#import "AppDelegate.h"
#import "MainWindowController.h"
#import "AboutWindowController.h"

@interface AppDelegate ()
@property (strong) MainWindowController *mainWindowController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self setupMenuBar];
    [self configureApplicationIcon];
    NSColorPanel.sharedColorPanel.continuous = YES;
    self.mainWindowController = [[MainWindowController alloc] init];
    [self.mainWindowController.window center];
    [self.mainWindowController showWindow:nil];
    [self.mainWindowController.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)setupMenuBar {
    NSMenu *bar = [[NSMenu alloc] init];

    // ── Scalator app menu ─────────────────────────────────────────────────────
    NSMenuItem *appItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Scalator"];

    [appMenu addItemWithTitle:@"About Scalator"
                       action:@selector(showAbout:)
                keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *hideItem = [[NSMenuItem alloc]
        initWithTitle:@"Hide Scalator" action:@selector(hide:) keyEquivalent:@"h"];
    [appMenu addItem:hideItem];

    NSMenuItem *hideOthers = [[NSMenuItem alloc]
        initWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    hideOthers.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
    [appMenu addItem:hideOthers];

    [appMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];

    [appMenu addItemWithTitle:@"Quit Scalator"
                       action:@selector(terminate:)
                keyEquivalent:@"q"];
    appItem.submenu = appMenu;
    [bar addItem:appItem];

    // ── File menu ─────────────────────────────────────────────────────────────
    NSMenuItem *fileItem = [[NSMenuItem alloc] init];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    [fileMenu addItemWithTitle:@"Open Project…" action:@selector(openDocument:) keyEquivalent:@"o"];
    [fileMenu addItemWithTitle:@"Save Project" action:@selector(saveDocument:) keyEquivalent:@"s"];
    [fileMenu addItemWithTitle:@"Save Project As…" action:@selector(saveDocumentAs:) keyEquivalent:@"S"];
    [fileMenu addItem:[NSMenuItem separatorItem]];
    [fileMenu addItemWithTitle:@"Export PNG…" action:@selector(exportPNG:) keyEquivalent:@"e"];
    [fileMenu addItemWithTitle:@"Export SVG…" action:@selector(exportSVG:) keyEquivalent:@"E"];
    [fileMenu addItem:[NSMenuItem separatorItem]];
    [fileMenu addItemWithTitle:@"Copy Scale" action:@selector(copyToClipboard:) keyEquivalent:@"c"];
    fileItem.submenu = fileMenu;
    [bar addItem:fileItem];

    // ── Edit menu (required for text field cut/copy/paste) ────────────────────
    NSMenuItem *editItem = [[NSMenuItem alloc] init];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    SEL undoAction = NSSelectorFromString(@"undo:");
    SEL redoAction = NSSelectorFromString(@"redo:");
    [editMenu addItemWithTitle:@"Undo" action:undoAction keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:redoAction keyEquivalent:@"Z"];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Cut"        action:@selector(cut:)       keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy"       action:@selector(copy:)      keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste"      action:@selector(paste:)     keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    editItem.submenu = editMenu;
    [bar addItem:editItem];

    NSApp.mainMenu = bar;
}

- (void)configureApplicationIcon {
    NSApp.applicationIconImage = [AppDelegate scalatorApplicationIcon];
}

+ (NSImage *)scalatorApplicationIcon {
    CGFloat size = 1024.0;
    NSRect bounds = NSMakeRect(0.0, 0.0, size, size);
    NSImage *image = [[NSImage alloc] initWithSize:bounds.size];

    [image lockFocus];

    NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 48.0, 48.0)
                                                                   xRadius:200.0
                                                                   yRadius:200.0];
    NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.08 green:0.45 blue:0.50 alpha:1.0]
                                                                   endingColor:[NSColor colorWithCalibratedRed:0.04 green:0.22 blue:0.26 alpha:1.0]];
    [backgroundGradient drawInBezierPath:backgroundPath angle:90.0];

    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.18] setStroke];
    backgroundPath.lineWidth = 18.0;
    [backgroundPath stroke];

    NSPoint center = NSMakePoint(512.0, 470.0);
    CGFloat arcRadius = 330.0;
    CGFloat startAngle = 220.0;
    CGFloat endAngle = -40.0;

    NSBezierPath *arcPath = [NSBezierPath bezierPath];
    arcPath.lineCapStyle = NSLineCapStyleRound;
    arcPath.lineWidth = 24.0;
    [arcPath appendBezierPathWithArcWithCenter:center
                                        radius:arcRadius
                                    startAngle:startAngle
                                      endAngle:endAngle
                                     clockwise:YES];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.32] setStroke];
    [arcPath stroke];

    NSInteger majorTickCount = 11;
    NSInteger minorTicksPerGap = 4;
    NSInteger totalIntervals = (majorTickCount - 1) * (minorTicksPerGap + 1);
    for (NSInteger i = 0; i <= totalIntervals; i++) {
        BOOL isMajorTick = (i % (minorTicksPerGap + 1) == 0);
        CGFloat fraction = (CGFloat)i / (CGFloat)totalIntervals;
        CGFloat angle = startAngle + fraction * (endAngle - startAngle);
        CGFloat radians = angle * M_PI / 180.0;
        CGFloat outerRadius = arcRadius + 12.0;
        CGFloat innerRadius = arcRadius - (isMajorTick ? 86.0 : 54.0);

        NSPoint outerPoint = NSMakePoint(center.x + cos(radians) * outerRadius,
                                         center.y + sin(radians) * outerRadius);
        NSPoint innerPoint = NSMakePoint(center.x + cos(radians) * innerRadius,
                                         center.y + sin(radians) * innerRadius);

        NSBezierPath *tickPath = [NSBezierPath bezierPath];
        tickPath.lineCapStyle = NSLineCapStyleRound;
        tickPath.lineWidth = isMajorTick ? 26.0 : 16.0;
        [tickPath moveToPoint:outerPoint];
        [tickPath lineToPoint:innerPoint];
        [[NSColor whiteColor] setStroke];
        [tickPath stroke];
    }

    NSBezierPath *knobPath = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(358.0, 316.0, 308.0, 308.0)];
    NSGradient *knobGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.12 green:0.31 blue:0.34 alpha:1.0]
                                                             endingColor:[NSColor colorWithCalibratedRed:0.03 green:0.12 blue:0.14 alpha:1.0]];
    [knobGradient drawInBezierPath:knobPath angle:90.0];

    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.18] setStroke];
    knobPath.lineWidth = 16.0;
    [knobPath stroke];

    CGFloat pointerAngle = 62.0 * M_PI / 180.0;
    NSBezierPath *pointerPath = [NSBezierPath bezierPath];
    pointerPath.lineCapStyle = NSLineCapStyleRound;
    pointerPath.lineWidth = 34.0;
    [pointerPath moveToPoint:center];
    [pointerPath lineToPoint:NSMakePoint(center.x + cos(pointerAngle) * 178.0,
                                         center.y + sin(pointerAngle) * 178.0)];
    [[NSColor colorWithCalibratedRed:1.0 green:0.77 blue:0.22 alpha:1.0] setStroke];
    [pointerPath stroke];

    [image unlockFocus];
    return image;
}

- (void)showAbout:(id)sender {
    [AboutWindowController show];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (!flag) {
        [self.mainWindowController.window center];
        [self.mainWindowController showWindow:nil];
        [self.mainWindowController.window makeKeyAndOrderFront:nil];
    }
    return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    if (self.mainWindowController == nil) {
        self.mainWindowController = [[MainWindowController alloc] init];
    }

    [self.mainWindowController showWindow:nil];
    [self.mainWindowController.window makeKeyAndOrderFront:nil];
    [self.mainWindowController openProjectFromURL:[NSURL fileURLWithPath:filename]];
    return YES;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
