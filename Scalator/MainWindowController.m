#import "MainWindowController.h"
#import "ScaleView.h"
#import "ScaleParameters.h"
@import UniformTypeIdentifiers;

// ─── Tag constants for controls ──────────────────────────────────────────────
typedef NS_ENUM(NSInteger, CtrlTag) {
    TagStartAngle = 100, TagStartAngleVal,
    TagEndAngle,         TagEndAngleVal,
    TagTickRadius,       TagTickRadiusVal,
    TagMajorCount,       TagMajorCountVal,
    TagMinorCount,       TagMinorCountVal,
    TagShowMinorTicks,
    TagMajorLen,         TagMajorLenVal,
    TagMinorLen,         TagMinorLenVal,
    TagMajorWidth,       TagMajorWidthVal,
    TagMinorWidth,       TagMinorWidthVal,
    TagShowLabels,
    TagLabelsOutside,
    TagMinValue,
    TagMaxValue,
    TagFontSize,         TagFontSizeVal,
    TagLabelOffset,      TagLabelOffsetVal,
    TagDecimalPlaces,    TagDecimalPlacesVal,
    TagPrefix,
    TagSuffix,
    TagTickColor,
    TagLabelColor,
    TagTransparentBg,
    TagBgColor,
    TagShowCenterDot,
    TagCenterDotSize,    TagCenterDotSizeVal,
    TagCenterDotColor,
    TagImageSize,
};

@interface MainWindowController () <NSTextFieldDelegate>
@end

@implementation MainWindowController {
    ScaleParameters *_params;
    ScaleView       *_scaleView;
    NSURL           *_projectURL;

    NSSlider      *_startAngleSlider,  *_endAngleSlider,   *_tickRadiusSlider;
    NSTextField   *_startAngleVal,     *_endAngleVal,      *_tickRadiusVal;
    NSSlider      *_majorCountSlider,  *_minorCountSlider;
    NSTextField   *_majorCountVal,     *_minorCountVal;
    NSButton      *_showMinorTicksCheck;
    NSSlider      *_majorLenSlider,    *_minorLenSlider;
    NSTextField   *_majorLenVal,       *_minorLenVal;
    NSSlider      *_majorWidthSlider,  *_minorWidthSlider;
    NSTextField   *_majorWidthVal,     *_minorWidthVal;
    NSButton      *_showLabelsCheck;
    NSButton      *_labelsOutsideCheck;
    NSTextField   *_minValueField,     *_maxValueField;
    NSSlider      *_fontSizeSlider;
    NSTextField   *_fontSizeVal;
    NSSlider      *_labelOffsetSlider;
    NSTextField   *_labelOffsetVal;
    NSSlider      *_decimalPlacesSlider;
    NSTextField   *_decimalPlacesVal;
    NSTextField   *_prefixField,       *_suffixField;
    NSColorWell   *_tickColorWell,     *_labelColorWell;
    NSButton      *_transparentBgCheck;
    NSColorWell   *_bgColorWell;
    NSButton      *_showCenterDotCheck;
    NSSlider      *_centerDotSizeSlider;
    NSTextField   *_centerDotSizeVal;
    NSColorWell   *_centerDotColorWell;
    NSPopUpButton *_imageSizePopup;
}

static UTType *ScalatorProjectContentType(void) {
    UTType *type = [UTType typeWithIdentifier:@"com.developer.scalator.project"];
    if (type == nil) {
        type = [UTType typeWithFilenameExtension:@"scalator" conformingToType:UTTypeJSON];
    }
    return type ?: UTTypeJSON;
}

// ─── Init ─────────────────────────────────────────────────────────────────────

- (instancetype)init {
    NSRect frame = NSMakeRect(0, 0, 940, 700);
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                              NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;
    NSWindow *win = [[NSWindow alloc] initWithContentRect:frame
                                               styleMask:style
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];
    win.title = @"Scalator — Knob Scale Generator";
    win.minSize = NSMakeSize(700, 500);

    self = [super initWithWindow:win];
    if (self) {
        _params = [[ScaleParameters alloc] init];
        [self buildUI];
        [win center];
    }
    return self;
}

// ─── UI construction ─────────────────────────────────────────────────────────

- (void)buildUI {
    NSView *content = self.window.contentView;
    content.wantsLayer = YES;
    content.layer.backgroundColor = [NSColor colorWithWhite:0.14 alpha:1].CGColor;

    // Divider between panel and preview
    NSView *divider = [[NSView alloc] init];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.wantsLayer = YES;
    divider.layer.backgroundColor = [NSColor colorWithWhite:0.08 alpha:1].CGColor;
    [content addSubview:divider];

    // Control scroll view on the left
    NSScrollView *scroll = [[NSScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.drawsBackground = NO;
    scroll.hasVerticalScroller = YES;
    scroll.hasHorizontalScroller = NO;
    scroll.autohidesScrollers = YES;
    [content addSubview:scroll];

    NSStackView *stack = [self buildControlStack];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.documentView = stack;
    [stack.widthAnchor constraintEqualToAnchor:scroll.contentView.widthAnchor].active = YES;

    // Preview area on the right
    NSView *preview = [[NSView alloc] init];
    preview.translatesAutoresizingMaskIntoConstraints = NO;
    preview.wantsLayer = YES;
    preview.layer.backgroundColor = [NSColor colorWithWhite:0.11 alpha:1].CGColor;
    [content addSubview:preview];

    _scaleView = [[ScaleView alloc] init];
    _scaleView.translatesAutoresizingMaskIntoConstraints = NO;
    _scaleView.parameters = _params;
    [preview addSubview:_scaleView];

    // Layout
    [content addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
        @"H:|[scroll(280)][divider(1)][preview]|"
        options:0 metrics:nil views:@{@"scroll":scroll,@"divider":divider,@"preview":preview}]];
    [content addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
        @"V:|[scroll]|" options:0 metrics:nil views:@{@"scroll":scroll}]];
    [content addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
        @"V:|[divider]|" options:0 metrics:nil views:@{@"divider":divider}]];
    [content addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
        @"V:|[preview]|" options:0 metrics:nil views:@{@"preview":preview}]];

    // ScaleView: square, centered, fills preview with margin
    [_scaleView.centerXAnchor constraintEqualToAnchor:preview.centerXAnchor].active = YES;
    [_scaleView.centerYAnchor constraintEqualToAnchor:preview.centerYAnchor].active = YES;
    [_scaleView.widthAnchor constraintEqualToAnchor:_scaleView.heightAnchor].active = YES;

    NSLayoutConstraint *fitW = [_scaleView.widthAnchor constraintLessThanOrEqualToAnchor:preview.widthAnchor constant:-40];
    fitW.active = YES;
    NSLayoutConstraint *fitH = [_scaleView.heightAnchor constraintLessThanOrEqualToAnchor:preview.heightAnchor constant:-40];
    fitH.active = YES;
    NSLayoutConstraint *expandW = [_scaleView.widthAnchor constraintEqualToAnchor:preview.widthAnchor constant:-40];
    expandW.priority = NSLayoutPriorityDefaultHigh - 1;
    expandW.active = YES;
}

- (NSStackView *)buildControlStack {
    NSStackView *stack = [[NSStackView alloc] init];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 3;
    stack.edgeInsets = NSEdgeInsetsMake(14, 12, 14, 12);

    void (^add)(NSView *) = ^(NSView *v) { [stack addArrangedSubview:v]; };

    // ── Presets ───────────────────────────────────────────────────────────────
    add([self sectionHeader:@"PRESETS"]);
    NSStackView *presetRow = [NSStackView stackViewWithViews:@[
        [self presetButton:@"Standard"],
        [self presetButton:@"Wide 300°"],
        [self presetButton:@"Pan"],
        [self presetButton:@"0–10"]
    ]];
    presetRow.spacing = 4;
    presetRow.distribution = NSStackViewDistributionFillEqually;
    add(presetRow);
    add([self spacer:6]);

    // ── Angles ────────────────────────────────────────────────────────────────
    add([self sectionHeader:@"ANGLES"]);
    _startAngleSlider = [self sliderMin:-360 max:360 value:_params.startAngle tag:TagStartAngle];
    _startAngleVal    = [self valueLabel:@"-135°" tag:TagStartAngleVal];
    add([self row:@"Start" control:_startAngleSlider valueView:_startAngleVal]);

    _endAngleSlider = [self sliderMin:-360 max:360 value:_params.endAngle tag:TagEndAngle];
    _endAngleVal    = [self valueLabel:@"135°" tag:TagEndAngleVal];
    add([self row:@"End" control:_endAngleSlider valueView:_endAngleVal]);

    add([self spacer:6]);

    // ── Ticks ─────────────────────────────────────────────────────────────────
    add([self sectionHeader:@"TICKS"]);
    _tickRadiusSlider = [self sliderMin:0.5 max:1.0 value:_params.tickRadius tag:TagTickRadius];
    _tickRadiusSlider.numberOfTickMarks = 0;
    _tickRadiusVal    = [self valueLabel:@"0.88" tag:TagTickRadiusVal];
    add([self row:@"Radius" control:_tickRadiusSlider valueView:_tickRadiusVal]);

    _majorCountSlider = [self sliderMin:2 max:21 value:_params.majorTickCount tag:TagMajorCount];
    _majorCountSlider.numberOfTickMarks = 20;
    _majorCountSlider.allowsTickMarkValuesOnly = YES;
    _majorCountVal    = [self valueLabel:@"11" tag:TagMajorCountVal];
    add([self row:@"Major ticks" control:_majorCountSlider valueView:_majorCountVal]);

    _showMinorTicksCheck = [NSButton checkboxWithTitle:@"Show minor ticks" target:self action:@selector(controlChanged:)];
    _showMinorTicksCheck.state = _params.showMinorTicks ? NSControlStateValueOn : NSControlStateValueOff;
    _showMinorTicksCheck.tag = TagShowMinorTicks;
    add(_showMinorTicksCheck);

    _minorCountSlider = [self sliderMin:0 max:9 value:_params.minorTickCount tag:TagMinorCount];
    _minorCountSlider.numberOfTickMarks = 10;
    _minorCountSlider.allowsTickMarkValuesOnly = YES;
    _minorCountVal    = [self valueLabel:@"4" tag:TagMinorCountVal];
    add([self row:@"Minor/gap" control:_minorCountSlider valueView:_minorCountVal]);

    _majorLenSlider = [self sliderMin:2 max:30 value:_params.majorTickLength tag:TagMajorLen];
    _majorLenVal    = [self valueLabel:@"12" tag:TagMajorLenVal];
    add([self row:@"Major len" control:_majorLenSlider valueView:_majorLenVal]);

    _minorLenSlider = [self sliderMin:1 max:20 value:_params.minorTickLength tag:TagMinorLen];
    _minorLenVal    = [self valueLabel:@"6" tag:TagMinorLenVal];
    add([self row:@"Minor len" control:_minorLenSlider valueView:_minorLenVal]);

    _majorWidthSlider = [self sliderMin:0.5 max:6 value:_params.majorTickWidth tag:TagMajorWidth];
    _majorWidthVal    = [self valueLabel:@"2.0" tag:TagMajorWidthVal];
    add([self row:@"Major width" control:_majorWidthSlider valueView:_majorWidthVal]);

    _minorWidthSlider = [self sliderMin:0.5 max:4 value:_params.minorTickWidth tag:TagMinorWidth];
    _minorWidthVal    = [self valueLabel:@"1.0" tag:TagMinorWidthVal];
    add([self row:@"Minor width" control:_minorWidthSlider valueView:_minorWidthVal]);
    [self updateMinorTickControlsEnabled];

    add([self spacer:6]);

    // ── Labels ────────────────────────────────────────────────────────────────
    add([self sectionHeader:@"LABELS"]);
    _showLabelsCheck = [NSButton checkboxWithTitle:@"Show labels" target:self action:@selector(controlChanged:)];
    _showLabelsCheck.state = _params.showLabels ? NSControlStateValueOn : NSControlStateValueOff;
    _showLabelsCheck.tag = TagShowLabels;
    add(_showLabelsCheck);

    _labelsOutsideCheck = [NSButton checkboxWithTitle:@"Labels outside dial" target:self action:@selector(controlChanged:)];
    _labelsOutsideCheck.state = _params.labelsOutside ? NSControlStateValueOn : NSControlStateValueOff;
    _labelsOutsideCheck.tag = TagLabelsOutside;
    add(_labelsOutsideCheck);

    _minValueField = [self editableField:[NSString stringWithFormat:@"%.0f", _params.minValue] tag:TagMinValue];
    add([self row:@"Min value" control:_minValueField valueView:nil]);

    _maxValueField = [self editableField:[NSString stringWithFormat:@"%.0f", _params.maxValue] tag:TagMaxValue];
    add([self row:@"Max value" control:_maxValueField valueView:nil]);

    _fontSizeSlider = [self sliderMin:6 max:24 value:_params.fontSize tag:TagFontSize];
    _fontSizeVal    = [self valueLabel:@"10" tag:TagFontSizeVal];
    add([self row:@"Font size" control:_fontSizeSlider valueView:_fontSizeVal]);

    _labelOffsetSlider = [self sliderMin:0 max:40 value:_params.labelOffset tag:TagLabelOffset];
    _labelOffsetVal    = [self valueLabel:@"0" tag:TagLabelOffsetVal];
    add([self row:@"Label offset" control:_labelOffsetSlider valueView:_labelOffsetVal]);

    _decimalPlacesSlider = [self sliderMin:0 max:3 value:_params.decimalPlaces tag:TagDecimalPlaces];
    _decimalPlacesSlider.numberOfTickMarks = 4;
    _decimalPlacesSlider.allowsTickMarkValuesOnly = YES;
    _decimalPlacesVal    = [self valueLabel:@"0" tag:TagDecimalPlacesVal];
    add([self row:@"Decimals" control:_decimalPlacesSlider valueView:_decimalPlacesVal]);

    _prefixField = [self editableField:_params.labelPrefix tag:TagPrefix];
    add([self row:@"Prefix" control:_prefixField valueView:nil]);

    _suffixField = [self editableField:_params.labelSuffix tag:TagSuffix];
    add([self row:@"Suffix" control:_suffixField valueView:nil]);

    add([self spacer:6]);

    // ── Colors ────────────────────────────────────────────────────────────────
    add([self sectionHeader:@"COLORS"]);
    _tickColorWell = [self colorWell:_params.tickColor tag:TagTickColor];
    add([self row:@"Ticks" control:_tickColorWell valueView:nil]);

    _labelColorWell = [self colorWell:_params.labelColor tag:TagLabelColor];
    add([self row:@"Labels" control:_labelColorWell valueView:nil]);

    _transparentBgCheck = [NSButton checkboxWithTitle:@"Transparent background" target:self action:@selector(controlChanged:)];
    _transparentBgCheck.state = _params.transparentBackground ? NSControlStateValueOn : NSControlStateValueOff;
    _transparentBgCheck.tag = TagTransparentBg;
    [self styleLabel:_transparentBgCheck.cell];
    add(_transparentBgCheck);

    _bgColorWell = [self colorWell:_params.backgroundColor tag:TagBgColor];
    add([self row:@"Background" control:_bgColorWell valueView:nil]);

    _showCenterDotCheck = [NSButton checkboxWithTitle:@"Center dot" target:self action:@selector(controlChanged:)];
    _showCenterDotCheck.state = _params.showCenterDot ? NSControlStateValueOn : NSControlStateValueOff;
    _showCenterDotCheck.tag = TagShowCenterDot;
    [self styleLabel:_showCenterDotCheck.cell];
    add(_showCenterDotCheck);

    _centerDotSizeSlider = [self sliderMin:1 max:12 value:_params.centerDotRadius tag:TagCenterDotSize];
    _centerDotSizeVal    = [self valueLabel:@"3.5" tag:TagCenterDotSizeVal];
    add([self row:@"Dot radius" control:_centerDotSizeSlider valueView:_centerDotSizeVal]);

    _centerDotColorWell = [self colorWell:_params.centerDotColor tag:TagCenterDotColor];
    add([self row:@"Dot color" control:_centerDotColorWell valueView:nil]);

    add([self spacer:10]);

    // ── Export ────────────────────────────────────────────────────────────────
    add([self sectionHeader:@"EXPORT"]);

    _imageSizePopup = [[NSPopUpButton alloc] init];
    [_imageSizePopup addItemsWithTitles:@[@"128", @"256", @"512", @"1024"]];
    [_imageSizePopup selectItemWithTitle:@"256"];
    _imageSizePopup.tag = TagImageSize;
    _imageSizePopup.target = self;
    _imageSizePopup.action = @selector(controlChanged:);
    add([self row:@"Size (px)" control:_imageSizePopup valueView:nil]);

    NSStackView *exportRow = [NSStackView stackViewWithViews:@[
        [self exportButton:@"Export PNG" action:@selector(exportPNG:)],
        [self exportButton:@"Export SVG" action:@selector(exportSVG:)],
        [self exportButton:@"Copy PNG"   action:@selector(copyToClipboard:)]
    ]];
    exportRow.spacing = 4;
    exportRow.distribution = NSStackViewDistributionFillEqually;
    add(exportRow);

    return stack;
}

// ─── Control helpers ──────────────────────────────────────────────────────────

- (NSView *)sectionHeader:(NSString *)title {
    NSTextField *lbl = [NSTextField labelWithString:title];
    lbl.font = [NSFont boldSystemFontOfSize:9.5];
    lbl.textColor = [NSColor colorWithRed:0.4 green:0.7 blue:1.0 alpha:0.85];
    return lbl;
}

- (NSView *)spacer:(CGFloat)h {
    NSView *v = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 10, h)];
    [v.heightAnchor constraintEqualToConstant:h].active = YES;
    return v;
}

- (NSSlider *)sliderMin:(CGFloat)mn max:(CGFloat)mx value:(CGFloat)val tag:(NSInteger)tag {
    NSSlider *s = [[NSSlider alloc] init];
    s.minValue = mn;
    s.maxValue = mx;
    s.floatValue = val;
    s.tag = tag;
    s.target = self;
    s.action = @selector(controlChanged:);
    s.continuous = YES;
    s.controlSize = NSControlSizeSmall;
    return s;
}

- (NSTextField *)valueLabel:(NSString *)str tag:(NSInteger)tag {
    NSTextField *lbl = [[NSTextField alloc] init];
    lbl.stringValue = str;
    lbl.font = [NSFont monospacedDigitSystemFontOfSize:10 weight:NSFontWeightRegular];
    lbl.textColor = [NSColor colorWithWhite:0.9 alpha:1];
    lbl.alignment = NSTextAlignmentRight;
    lbl.tag = tag;
    lbl.delegate = self;
    lbl.target = self;
    lbl.action = @selector(valueFieldChanged:);
    lbl.controlSize = NSControlSizeSmall;
    lbl.bezelStyle = NSTextFieldSquareBezel;
    lbl.backgroundColor = [NSColor colorWithWhite:0.2 alpha:1];
    lbl.focusRingType = NSFocusRingTypeExterior;
    [(NSTextFieldCell *)lbl.cell setSendsActionOnEndEditing:YES];
    [lbl.widthAnchor constraintEqualToConstant:46].active = YES;
    return lbl;
}

- (NSTextField *)editableField:(NSString *)str tag:(NSInteger)tag {
    NSTextField *f = [[NSTextField alloc] init];
    f.stringValue = str;
    f.tag = tag;
    f.delegate = self;
    f.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
    f.controlSize = NSControlSizeSmall;
    f.bezelStyle = NSTextFieldSquareBezel;
    f.backgroundColor = [NSColor colorWithWhite:0.22 alpha:1];
    f.textColor = [NSColor colorWithWhite:0.9 alpha:1];
    return f;
}

- (NSColorWell *)colorWell:(NSColor *)color tag:(NSInteger)tag {
    NSColorWell *w = [[NSColorWell alloc] initWithFrame:NSMakeRect(0, 0, 44, 22)];
    w.color = color;
    w.tag = tag;
    w.target = self;
    w.action = @selector(controlChanged:);
    [w.widthAnchor constraintEqualToConstant:44].active = YES;
    [w.heightAnchor constraintEqualToConstant:22].active = YES;
    return w;
}

- (NSButton *)exportButton:(NSString *)title action:(SEL)sel {
    NSButton *btn = [NSButton buttonWithTitle:title target:self action:sel];
    btn.font = [NSFont systemFontOfSize:10];
    btn.controlSize = NSControlSizeSmall;
    btn.bezelStyle = NSBezelStyleRounded;
    return btn;
}

- (NSButton *)presetButton:(NSString *)title {
    NSButton *btn = [NSButton buttonWithTitle:title target:self action:@selector(presetChosen:)];
    btn.font = [NSFont systemFontOfSize:10];
    btn.controlSize = NSControlSizeSmall;
    btn.bezelStyle = NSBezelStyleRounded;
    return btn;
}

- (void)styleLabel:(id)cell { (void)cell; }

- (NSView *)row:(NSString *)label control:(NSView *)ctrl valueView:(NSView *)val {
    NSStackView *row = [[NSStackView alloc] init];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.alignment = NSLayoutAttributeCenterY;
    row.spacing = 6;

    NSTextField *lbl = [NSTextField labelWithString:label];
    lbl.font = [NSFont systemFontOfSize:11];
    lbl.textColor = [NSColor colorWithWhite:0.78 alpha:1];
    [lbl.widthAnchor constraintEqualToConstant:78].active = YES;

    [row addArrangedSubview:lbl];
    [row addArrangedSubview:ctrl];
    [ctrl setContentHuggingPriority:NSLayoutPriorityDefaultLow
                     forOrientation:NSLayoutConstraintOrientationHorizontal];
    if (val) {
        [row addArrangedSubview:val];
    }
    return row;
}

// ─── Control change handler ───────────────────────────────────────────────────

- (CGFloat)clampedValue:(CGFloat)value forSlider:(NSSlider *)slider {
    return MIN(MAX(value, slider.minValue), slider.maxValue);
}

- (void)setValueField:(NSTextField *)field stringValue:(NSString *)stringValue {
    if (field.currentEditor == nil) {
        field.stringValue = stringValue;
    }
}

- (void)valueFieldChanged:(NSTextField *)sender {
    [self applyValueFieldToSlider:sender];
    [self readControlsIntoParams];
    [_scaleView setNeedsDisplay:YES];
}

- (void)applyValueFieldToSlider:(NSTextField *)field {
    switch (field.tag) {
        case TagStartAngleVal:
            _startAngleSlider.floatValue = [self clampedValue:field.floatValue forSlider:_startAngleSlider];
            break;
        case TagEndAngleVal:
            _endAngleSlider.floatValue = [self clampedValue:field.floatValue forSlider:_endAngleSlider];
            break;
        case TagTickRadiusVal:
            _tickRadiusSlider.floatValue = [self clampedValue:field.floatValue forSlider:_tickRadiusSlider];
            break;
        case TagMajorCountVal:
            _majorCountSlider.integerValue = (NSInteger)round([self clampedValue:field.floatValue forSlider:_majorCountSlider]);
            break;
        case TagMinorCountVal:
            _minorCountSlider.integerValue = (NSInteger)round([self clampedValue:field.floatValue forSlider:_minorCountSlider]);
            break;
        case TagMajorLenVal:
            _majorLenSlider.floatValue = [self clampedValue:field.floatValue forSlider:_majorLenSlider];
            break;
        case TagMinorLenVal:
            _minorLenSlider.floatValue = [self clampedValue:field.floatValue forSlider:_minorLenSlider];
            break;
        case TagMajorWidthVal:
            _majorWidthSlider.floatValue = [self clampedValue:field.floatValue forSlider:_majorWidthSlider];
            break;
        case TagMinorWidthVal:
            _minorWidthSlider.floatValue = [self clampedValue:field.floatValue forSlider:_minorWidthSlider];
            break;
        case TagFontSizeVal:
            _fontSizeSlider.floatValue = [self clampedValue:field.floatValue forSlider:_fontSizeSlider];
            break;
        case TagLabelOffsetVal:
            _labelOffsetSlider.floatValue = [self clampedValue:field.floatValue forSlider:_labelOffsetSlider];
            break;
        case TagDecimalPlacesVal:
            _decimalPlacesSlider.integerValue = (NSInteger)round([self clampedValue:field.floatValue forSlider:_decimalPlacesSlider]);
            break;
        case TagCenterDotSizeVal:
            _centerDotSizeSlider.floatValue = [self clampedValue:field.floatValue forSlider:_centerDotSizeSlider];
            break;
        default:
            break;
    }
}

- (void)controlChanged:(id)sender {
    [self readControlsIntoParams];
    [_scaleView setNeedsDisplay:YES];
}

- (void)updateMinorTickControlsEnabled {
    BOOL enabled = (_showMinorTicksCheck.state == NSControlStateValueOn);
    _minorCountSlider.enabled = enabled;
    _minorCountVal.enabled = enabled;
    _minorLenSlider.enabled = enabled;
    _minorLenVal.enabled = enabled;
    _minorWidthSlider.enabled = enabled;
    _minorWidthVal.enabled = enabled;
}

- (void)controlTextDidChange:(NSNotification *)note {
    id object = note.object;
    if ([object isKindOfClass:NSTextField.class]) {
        [self applyValueFieldToSlider:object];
    }
    [self readControlsIntoParams];
    [_scaleView setNeedsDisplay:YES];
}

- (void)controlTextDidEndEditing:(NSNotification *)note {
    id object = note.object;
    if ([object isKindOfClass:NSTextField.class]) {
        [self applyValueFieldToSlider:object];
    }
    [self readControlsIntoParams];
    [_scaleView setNeedsDisplay:YES];
}

- (void)readControlsIntoParams {
    _params.startAngle = _startAngleSlider.floatValue;
    [self setValueField:_startAngleVal stringValue:[NSString stringWithFormat:@"%.0f°", _params.startAngle]];

    _params.endAngle = _endAngleSlider.floatValue;
    [self setValueField:_endAngleVal stringValue:[NSString stringWithFormat:@"%.0f°", _params.endAngle]];

    _params.tickRadius = _tickRadiusSlider.floatValue;
    [self setValueField:_tickRadiusVal stringValue:[NSString stringWithFormat:@"%.2f", _params.tickRadius]];

    _params.majorTickCount = MAX(2, (NSInteger)round(_majorCountSlider.floatValue));
    [self setValueField:_majorCountVal stringValue:[NSString stringWithFormat:@"%ld", (long)_params.majorTickCount]];

    _params.showMinorTicks = (_showMinorTicksCheck.state == NSControlStateValueOn);
    _params.minorTickCount = MAX(0, (NSInteger)round(_minorCountSlider.floatValue));
    [self setValueField:_minorCountVal stringValue:[NSString stringWithFormat:@"%ld", (long)_params.minorTickCount]];
    [self updateMinorTickControlsEnabled];

    _params.majorTickLength = _majorLenSlider.floatValue;
    [self setValueField:_majorLenVal stringValue:[NSString stringWithFormat:@"%.1f", _params.majorTickLength]];

    _params.minorTickLength = _minorLenSlider.floatValue;
    [self setValueField:_minorLenVal stringValue:[NSString stringWithFormat:@"%.1f", _params.minorTickLength]];

    _params.majorTickWidth = _majorWidthSlider.floatValue;
    [self setValueField:_majorWidthVal stringValue:[NSString stringWithFormat:@"%.1f", _params.majorTickWidth]];

    _params.minorTickWidth = _minorWidthSlider.floatValue;
    [self setValueField:_minorWidthVal stringValue:[NSString stringWithFormat:@"%.1f", _params.minorTickWidth]];

    _params.showLabels    = (_showLabelsCheck.state    == NSControlStateValueOn);
    _params.labelsOutside = (_labelsOutsideCheck.state == NSControlStateValueOn);
    _params.minValue = _minValueField.floatValue;
    _params.maxValue = _maxValueField.floatValue;
    _params.fontSize = _fontSizeSlider.floatValue;
    [self setValueField:_fontSizeVal stringValue:[NSString stringWithFormat:@"%.0f", _params.fontSize]];
    _params.labelOffset = _labelOffsetSlider.floatValue;
    [self setValueField:_labelOffsetVal stringValue:[NSString stringWithFormat:@"%.0f", _params.labelOffset]];
    _params.decimalPlaces = (NSInteger)round(_decimalPlacesSlider.floatValue);
    [self setValueField:_decimalPlacesVal stringValue:[NSString stringWithFormat:@"%ld", (long)_params.decimalPlaces]];
    _params.labelPrefix = _prefixField.stringValue;
    _params.labelSuffix = _suffixField.stringValue;

    _params.tickColor = _tickColorWell.color;
    _params.labelColor = _labelColorWell.color;
    _params.transparentBackground = (_transparentBgCheck.state == NSControlStateValueOn);
    _params.backgroundColor = _bgColorWell.color;
    _params.showCenterDot = (_showCenterDotCheck.state == NSControlStateValueOn);
    _params.centerDotRadius = _centerDotSizeSlider.floatValue;
    [self setValueField:_centerDotSizeVal stringValue:[NSString stringWithFormat:@"%.1f", _params.centerDotRadius]];
    _params.centerDotColor = _centerDotColorWell.color;

    _params.imageSize = [_imageSizePopup titleOfSelectedItem].integerValue;
}

- (void)writeParamsToControls {
    _startAngleSlider.floatValue = _params.startAngle;
    _startAngleVal.stringValue = [NSString stringWithFormat:@"%.0f°", _params.startAngle];
    _endAngleSlider.floatValue = _params.endAngle;
    _endAngleVal.stringValue = [NSString stringWithFormat:@"%.0f°", _params.endAngle];
    _tickRadiusSlider.floatValue = _params.tickRadius;
    _tickRadiusVal.stringValue = [NSString stringWithFormat:@"%.2f", _params.tickRadius];
    _majorCountSlider.floatValue = _params.majorTickCount;
    _majorCountVal.stringValue = [NSString stringWithFormat:@"%ld", (long)_params.majorTickCount];
    _showMinorTicksCheck.state = _params.showMinorTicks ? NSControlStateValueOn : NSControlStateValueOff;
    _minorCountSlider.floatValue = _params.minorTickCount;
    _minorCountVal.stringValue = [NSString stringWithFormat:@"%ld", (long)_params.minorTickCount];
    _majorLenSlider.floatValue = _params.majorTickLength;
    _majorLenVal.stringValue = [NSString stringWithFormat:@"%.1f", _params.majorTickLength];
    _minorLenSlider.floatValue = _params.minorTickLength;
    _minorLenVal.stringValue = [NSString stringWithFormat:@"%.1f", _params.minorTickLength];
    _majorWidthSlider.floatValue = _params.majorTickWidth;
    _majorWidthVal.stringValue = [NSString stringWithFormat:@"%.1f", _params.majorTickWidth];
    _minorWidthSlider.floatValue = _params.minorTickWidth;
    _minorWidthVal.stringValue = [NSString stringWithFormat:@"%.1f", _params.minorTickWidth];
    _showLabelsCheck.state    = _params.showLabels    ? NSControlStateValueOn : NSControlStateValueOff;
    _labelsOutsideCheck.state = _params.labelsOutside ? NSControlStateValueOn : NSControlStateValueOff;
    _minValueField.stringValue = [NSString stringWithFormat:@"%.0f", _params.minValue];
    _maxValueField.stringValue = [NSString stringWithFormat:@"%.0f", _params.maxValue];
    _fontSizeSlider.floatValue = _params.fontSize;
    _fontSizeVal.stringValue = [NSString stringWithFormat:@"%.0f", _params.fontSize];
    _labelOffsetSlider.floatValue = _params.labelOffset;
    _labelOffsetVal.stringValue = [NSString stringWithFormat:@"%.0f", _params.labelOffset];
    _decimalPlacesSlider.floatValue = _params.decimalPlaces;
    _decimalPlacesVal.stringValue = [NSString stringWithFormat:@"%ld", (long)_params.decimalPlaces];
    _prefixField.stringValue = _params.labelPrefix;
    _suffixField.stringValue = _params.labelSuffix;
    _tickColorWell.color = _params.tickColor;
    _labelColorWell.color = _params.labelColor;
    _transparentBgCheck.state = _params.transparentBackground ? NSControlStateValueOn : NSControlStateValueOff;
    _bgColorWell.color = _params.backgroundColor;
    _showCenterDotCheck.state = _params.showCenterDot ? NSControlStateValueOn : NSControlStateValueOff;
    _centerDotSizeSlider.floatValue = _params.centerDotRadius;
    _centerDotSizeVal.stringValue = [NSString stringWithFormat:@"%.1f", _params.centerDotRadius];
    _centerDotColorWell.color = _params.centerDotColor;
    [_imageSizePopup selectItemWithTitle:[NSString stringWithFormat:@"%ld", (long)_params.imageSize]];
    [self updateMinorTickControlsEnabled];
}

// ─── Presets ──────────────────────────────────────────────────────────────────

- (void)presetChosen:(NSButton *)sender {
    NSString *name = sender.title;
    if ([name isEqualToString:@"Standard"]) {
        _params.startAngle = -135; _params.endAngle = 135;
        _params.majorTickCount = 11; _params.minorTickCount = 4; _params.showMinorTicks = YES;
        _params.minValue = 0; _params.maxValue = 100;
        _params.tickRadius = 0.88;
    } else if ([name isEqualToString:@"Wide 300°"]) {
        _params.startAngle = -150; _params.endAngle = 150;
        _params.majorTickCount = 11; _params.minorTickCount = 4; _params.showMinorTicks = YES;
        _params.minValue = 0; _params.maxValue = 100;
        _params.tickRadius = 0.88;
    } else if ([name isEqualToString:@"Pan"]) {
        _params.startAngle = -135; _params.endAngle = 135;
        _params.majorTickCount = 3; _params.minorTickCount = 0; _params.showMinorTicks = NO;
        _params.minValue = -100; _params.maxValue = 100;
        _params.labelPrefix = @""; _params.labelSuffix = @"";
        _params.decimalPlaces = 0;
        _params.tickRadius = 0.88;
    } else if ([name isEqualToString:@"0–10"]) {
        _params.startAngle = -135; _params.endAngle = 135;
        _params.majorTickCount = 11; _params.minorTickCount = 4; _params.showMinorTicks = YES;
        _params.minValue = 0; _params.maxValue = 10;
        _params.decimalPlaces = 0;
        _params.tickRadius = 0.88;
    }
    [self writeParamsToControls];
    [_scaleView setNeedsDisplay:YES];
}

// ─── Project files ─────────────────────────────────────────────────────────────

- (void)saveDocument:(id)sender {
    if (_projectURL == nil) {
        [self saveDocumentAs:sender];
        return;
    }

    [self saveProjectToURL:_projectURL];
}

- (void)saveDocumentAs:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedContentTypes = @[ScalatorProjectContentType()];
    panel.allowsOtherFileTypes = NO;
    panel.canSelectHiddenExtension = YES;
    panel.extensionHidden = NO;
    panel.nameFieldStringValue = _projectURL.lastPathComponent ?: @"Untitled.scalator";

    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        [self saveProjectToURL:panel.URL];
    }];
}

- (void)openDocument:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[ScalatorProjectContentType()];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = NO;
    panel.canChooseFiles = YES;

    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        [self openProjectFromURL:panel.URL];
    }];
}

- (void)saveProjectToURL:(NSURL *)url {
    [self.window makeFirstResponder:nil];
    [self readControlsIntoParams];

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self projectDictionary]
                                                   options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys
                                                     error:&error];
    if (data == nil || ![data writeToURL:url options:NSDataWritingAtomic error:&error]) {
        [self presentFileError:error message:@"The project could not be saved."];
        return;
    }

    _projectURL = url;
    self.window.representedURL = url;
}

- (void)openProjectFromURL:(NSURL *)url {
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    NSDictionary *project = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&error] : nil;
    if (![project isKindOfClass:NSDictionary.class] || ![self applyProjectDictionary:project]) {
        [self presentFileError:error message:@"The project could not be opened."];
        return;
    }

    _projectURL = url;
    self.window.representedURL = url;
    [self writeParamsToControls];
    [_scaleView setNeedsDisplay:YES];
}

- (NSDictionary *)projectDictionary {
    return @{
        @"format": @"com.scalator.project",
        @"version": @1,
        @"diameter": @(_params.diameter),
        @"startAngle": @(_params.startAngle),
        @"endAngle": @(_params.endAngle),
        @"majorTickCount": @(_params.majorTickCount),
        @"minorTickCount": @(_params.minorTickCount),
        @"showMinorTicks": @(_params.showMinorTicks),
        @"tickRadius": @(_params.tickRadius),
        @"majorTickLength": @(_params.majorTickLength),
        @"minorTickLength": @(_params.minorTickLength),
        @"majorTickWidth": @(_params.majorTickWidth),
        @"minorTickWidth": @(_params.minorTickWidth),
        @"showLabels": @(_params.showLabels),
        @"labelsOutside": @(_params.labelsOutside),
        @"minValue": @(_params.minValue),
        @"maxValue": @(_params.maxValue),
        @"fontSize": @(_params.fontSize),
        @"decimalPlaces": @(_params.decimalPlaces),
        @"labelPrefix": _params.labelPrefix ?: @"",
        @"labelSuffix": _params.labelSuffix ?: @"",
        @"labelOffset": @(_params.labelOffset),
        @"tickColor": [self dictionaryForColor:_params.tickColor],
        @"labelColor": [self dictionaryForColor:_params.labelColor],
        @"transparentBackground": @(_params.transparentBackground),
        @"backgroundColor": [self dictionaryForColor:_params.backgroundColor],
        @"showCenterDot": @(_params.showCenterDot),
        @"centerDotRadius": @(_params.centerDotRadius),
        @"centerDotColor": [self dictionaryForColor:_params.centerDotColor],
        @"imageSize": @(_params.imageSize)
    };
}

- (BOOL)applyProjectDictionary:(NSDictionary *)project {
    if (![project[@"format"] isEqualToString:@"com.scalator.project"]) {
        return NO;
    }

    _params.diameter = [self doubleFromProject:project key:@"diameter" defaultValue:_params.diameter];
    _params.startAngle = [self doubleFromProject:project key:@"startAngle" defaultValue:_params.startAngle];
    _params.endAngle = [self doubleFromProject:project key:@"endAngle" defaultValue:_params.endAngle];
    _params.majorTickCount = [self integerFromProject:project key:@"majorTickCount" defaultValue:_params.majorTickCount];
    _params.minorTickCount = [self integerFromProject:project key:@"minorTickCount" defaultValue:_params.minorTickCount];
    _params.showMinorTicks = [self boolFromProject:project key:@"showMinorTicks" defaultValue:_params.showMinorTicks];
    _params.tickRadius = [self doubleFromProject:project key:@"tickRadius" defaultValue:_params.tickRadius];
    _params.majorTickLength = [self doubleFromProject:project key:@"majorTickLength" defaultValue:_params.majorTickLength];
    _params.minorTickLength = [self doubleFromProject:project key:@"minorTickLength" defaultValue:_params.minorTickLength];
    _params.majorTickWidth = [self doubleFromProject:project key:@"majorTickWidth" defaultValue:_params.majorTickWidth];
    _params.minorTickWidth = [self doubleFromProject:project key:@"minorTickWidth" defaultValue:_params.minorTickWidth];
    _params.showLabels = [self boolFromProject:project key:@"showLabels" defaultValue:_params.showLabels];
    _params.labelsOutside = [self boolFromProject:project key:@"labelsOutside" defaultValue:_params.labelsOutside];
    _params.minValue = [self doubleFromProject:project key:@"minValue" defaultValue:_params.minValue];
    _params.maxValue = [self doubleFromProject:project key:@"maxValue" defaultValue:_params.maxValue];
    _params.fontSize = [self doubleFromProject:project key:@"fontSize" defaultValue:_params.fontSize];
    _params.decimalPlaces = [self integerFromProject:project key:@"decimalPlaces" defaultValue:_params.decimalPlaces];
    _params.labelPrefix = [project[@"labelPrefix"] isKindOfClass:NSString.class] ? project[@"labelPrefix"] : @"";
    _params.labelSuffix = [project[@"labelSuffix"] isKindOfClass:NSString.class] ? project[@"labelSuffix"] : @"";
    _params.labelOffset = [self doubleFromProject:project key:@"labelOffset" defaultValue:_params.labelOffset];
    _params.tickColor = [self colorFromProject:project key:@"tickColor" defaultColor:_params.tickColor];
    _params.labelColor = [self colorFromProject:project key:@"labelColor" defaultColor:_params.labelColor];
    _params.transparentBackground = [self boolFromProject:project key:@"transparentBackground" defaultValue:_params.transparentBackground];
    _params.backgroundColor = [self colorFromProject:project key:@"backgroundColor" defaultColor:_params.backgroundColor];
    _params.showCenterDot = [self boolFromProject:project key:@"showCenterDot" defaultValue:_params.showCenterDot];
    _params.centerDotRadius = [self doubleFromProject:project key:@"centerDotRadius" defaultValue:_params.centerDotRadius];
    _params.centerDotColor = [self colorFromProject:project key:@"centerDotColor" defaultColor:_params.centerDotColor];
    _params.imageSize = [self integerFromProject:project key:@"imageSize" defaultValue:_params.imageSize];
    return YES;
}

- (NSDictionary *)dictionaryForColor:(NSColor *)color {
    NSColor *rgb = [color colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace] ?: NSColor.whiteColor;
    return @{
        @"red": @(rgb.redComponent),
        @"green": @(rgb.greenComponent),
        @"blue": @(rgb.blueComponent),
        @"alpha": @(rgb.alphaComponent)
    };
}

- (NSColor *)colorFromProject:(NSDictionary *)project key:(NSString *)key defaultColor:(NSColor *)defaultColor {
    NSDictionary *color = project[key];
    if (![color isKindOfClass:NSDictionary.class]) {
        return defaultColor;
    }

    return [NSColor colorWithCalibratedRed:[self doubleFromProject:color key:@"red" defaultValue:1.0]
                                     green:[self doubleFromProject:color key:@"green" defaultValue:1.0]
                                      blue:[self doubleFromProject:color key:@"blue" defaultValue:1.0]
                                     alpha:[self doubleFromProject:color key:@"alpha" defaultValue:1.0]];
}

- (CGFloat)doubleFromProject:(NSDictionary *)project key:(NSString *)key defaultValue:(CGFloat)defaultValue {
    id value = project[key];
    return [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : defaultValue;
}

- (NSInteger)integerFromProject:(NSDictionary *)project key:(NSString *)key defaultValue:(NSInteger)defaultValue {
    id value = project[key];
    return [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : defaultValue;
}

- (BOOL)boolFromProject:(NSDictionary *)project key:(NSString *)key defaultValue:(BOOL)defaultValue {
    id value = project[key];
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}

- (void)presentFileError:(NSError *)error message:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = message;
    alert.informativeText = error.localizedDescription ?: @"The selected file is not a valid Scalator project.";
    alert.alertStyle = NSAlertStyleWarning;
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

// ─── Export ───────────────────────────────────────────────────────────────────

- (void)writeScaleToURL:(NSURL *)url {
    NSString *extension = url.pathExtension.lowercaseString;

    if ([extension isEqualToString:@"svg"]) {
        NSString *svg = [_scaleView generateSVG];
        NSError *error = nil;
        if (![svg writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            [self presentSaveError:error];
        }
        return;
    }

    NSImage *img = [_scaleView renderImage];
    NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[img TIFFRepresentation]];
    NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    NSError *error = nil;
    if (![pngData writeToURL:url options:NSDataWritingAtomic error:&error]) {
        [self presentSaveError:error];
    }
}

- (void)presentSaveError:(NSError *)error {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"The file could not be saved.";
    alert.informativeText = error.localizedDescription ?: @"An unknown error occurred.";
    alert.alertStyle = NSAlertStyleWarning;
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void)exportPNG:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedContentTypes = @[[UTType typeWithIdentifier:@"public.png"]];
    panel.nameFieldStringValue = @"knob_scale.png";

    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        NSImage *img = [self->_scaleView renderImage];
        NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[img TIFFRepresentation]];
        NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        [pngData writeToURL:panel.URL atomically:YES];
    }];
}

- (void)exportSVG:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedContentTypes = @[[UTType typeWithIdentifier:@"public.svg-image"]];
    panel.nameFieldStringValue = @"knob_scale.svg";

    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        NSString *svg = [self->_scaleView generateSVG];
        [svg writeToURL:panel.URL atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }];
}

- (void)copyToClipboard:(id)sender {
    NSImage *img = [_scaleView renderImage];
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb writeObjects:@[img]];
}

@end
