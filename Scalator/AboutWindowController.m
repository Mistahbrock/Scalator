#import "AboutWindowController.h"
#import "AppDelegate.h"

@implementation AboutWindowController {
    NSImageView *_iconView;
}

+ (void)show {
    static AboutWindowController *instance;
    if (!instance) instance = [[AboutWindowController alloc] init];
    [instance refreshIcon];
    [instance.window center];
    [instance showWindow:nil];
    [instance.window makeKeyAndOrderFront:nil];
}

- (instancetype)init {
    NSRect frame = NSMakeRect(0, 0, 360, 260);
    NSWindowStyleMask style = NSWindowStyleMaskTitled |
                              NSWindowStyleMaskClosable |
                              NSWindowStyleMaskMiniaturizable;
    NSWindow *win = [[NSWindow alloc] initWithContentRect:frame
                                               styleMask:style
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];
    win.title = @"About Scalator";
    win.releasedWhenClosed = NO;

    self = [super initWithWindow:win];
    if (self) {
        [self buildUI];
        [win center];
    }
    return self;
}

- (void)buildUI {
    NSView *v = self.window.contentView;
    v.wantsLayer = YES;
    v.layer.backgroundColor = [NSColor windowBackgroundColor].CGColor;

    // Icon
    _iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(24, 112, 80, 80)];
    _iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
    [self refreshIcon];
    [v addSubview:_iconView];

    // App name
    NSTextField *nameLabel = [NSTextField labelWithString:@"Scalator"];
    nameLabel.font = [NSFont boldSystemFontOfSize:20];
    nameLabel.textColor = [NSColor labelColor];
    nameLabel.frame = NSMakeRect(120, 190, 220, 28);
    [v addSubview:nameLabel];

    // Version
    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSString *version = info[@"CFBundleShortVersionString"] ?: @"1.0";
    NSString *build   = info[@"CFBundleVersion"] ?: @"1";
    NSTextField *verLabel = [NSTextField labelWithString:
        [NSString stringWithFormat:@"Version %@ (%@)", version, build]];
    verLabel.font = [NSFont systemFontOfSize:12];
    verLabel.textColor = [NSColor secondaryLabelColor];
    verLabel.frame = NSMakeRect(120, 166, 220, 18);
    [v addSubview:verLabel];

    // Description
    NSTextField *descLabel = [NSTextField wrappingLabelWithString:
        @"Circular scale generator for VST knob GUIs.\nExports PNG and SVG ready for use in JUCE, iPlug2, or any VST framework."];
    descLabel.font = [NSFont systemFontOfSize:11];
    descLabel.textColor = [NSColor secondaryLabelColor];
    descLabel.frame = NSMakeRect(120, 96, 218, 58);
    [v addSubview:descLabel];

    // Divider
    NSBox *divider = [[NSBox alloc] initWithFrame:NSMakeRect(0, 58, 360, 1)];
    divider.boxType = NSBoxSeparator;
    [v addSubview:divider];

    // Link
    NSButton *websiteButton = [NSButton buttonWithTitle:@"by Rhyno Audio" target:self action:@selector(openWebsite:)];
    websiteButton.bezelStyle = NSBezelStyleInline;
    websiteButton.bordered = NO;
    websiteButton.font = [NSFont systemFontOfSize:11];
    websiteButton.contentTintColor = [NSColor linkColor];
    websiteButton.alignment = NSTextAlignmentLeft;
    websiteButton.frame = NSMakeRect(120, 72, 140, 18);
    [v addSubview:websiteButton];

    NSTextField *copyrightLabel = [NSTextField labelWithString:@"© 2026  —  Built with Cocoa & Core Graphics"];
    copyrightLabel.font = [NSFont systemFontOfSize:10];
    copyrightLabel.textColor = [NSColor tertiaryLabelColor];
    copyrightLabel.frame = NSMakeRect(24, 24, 240, 16);
    [v addSubview:copyrightLabel];

    // Close button
    NSButton *closeBtn = [NSButton buttonWithTitle:@"OK" target:self action:@selector(closeAbout:)];
    closeBtn.frame = NSMakeRect(284, 18, 60, 28);
    closeBtn.keyEquivalent = @"\r";
    [v addSubview:closeBtn];
}

- (void)refreshIcon {
    NSImage *icon = [AppDelegate scalatorApplicationIcon];
    NSApp.applicationIconImage = icon;
    _iconView.image = icon;
}

- (void)openWebsite:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://rhyno-audio.net/wordpress/sample-page/vst-stuff"];
    if (url) {
        [NSWorkspace.sharedWorkspace openURL:url];
    }
}

- (void)closeAbout:(id)sender {
    [self.window orderOut:nil];
}

@end
