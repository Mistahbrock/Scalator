#import "ScaleView.h"
#import <math.h>

// Convert visual angle (degrees clockwise from 12 o'clock) to Cocoa math radians
// (CCW from 3 o'clock, y-up coordinate system)
static inline CGFloat visualToMathRad(CGFloat deg) {
    return (90.0 - deg) * M_PI / 180.0;
}

// Convert visual angle to SVG radians (CW from 3 o'clock, y-down coordinate system)
static inline CGFloat visualToSVGRad(CGFloat deg) {
    return (deg - 90.0) * M_PI / 180.0;
}

static NSString *colorToSVGHex(NSColor *c) {
    NSColor *rgb = [c colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    int r = (int)(rgb.redComponent * 255);
    int g = (int)(rgb.greenComponent * 255);
    int b = (int)(rgb.blueComponent * 255);
    return [NSString stringWithFormat:@"#%02X%02X%02X", r, g, b];
}

static inline CGFloat clampCGFloat(CGFloat value, CGFloat minimum, CGFloat maximum) {
    if (minimum > maximum) return (minimum + maximum) / 2.0;
    return MIN(MAX(value, minimum), maximum);
}

@implementation ScaleView

- (instancetype)init {
    self = [super init];
    if (self) {
        _parameters = [[ScaleParameters alloc] init];
        self.wantsLayer = YES;
    }
    return self;
}

- (BOOL)isOpaque { return NO; }
- (BOOL)isFlipped { return NO; }

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    NSRect bounds = self.bounds;
    CGFloat cx = NSMidX(bounds);
    CGFloat cy = NSMidY(bounds);
    CGFloat radius = MIN(bounds.size.width, bounds.size.height) / 2.0 - 2.0;

    if (_parameters.transparentBackground) {
        [self drawCheckerboard:bounds];
    } else {
        [_parameters.backgroundColor setFill];
        NSBezierPath *bg = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:4 yRadius:4];
        [bg fill];
    }

    [self drawScaleAtCenter:NSMakePoint(cx, cy) radius:radius scale:radius * 2.0 / _parameters.diameter];
}

- (void)drawCheckerboard:(NSRect)rect {
    CGFloat size = 8;
    NSColor *c1 = [NSColor colorWithWhite:0.6 alpha:1];
    NSColor *c2 = [NSColor colorWithWhite:0.8 alpha:1];
    NSInteger cols = (NSInteger)(ceil(rect.size.width / size));
    NSInteger rows = (NSInteger)(ceil(rect.size.height / size));
    for (NSInteger r = 0; r < rows; r++) {
        for (NSInteger c = 0; c < cols; c++) {
            NSRect cell = NSMakeRect(rect.origin.x + c * size, rect.origin.y + r * size, size, size);
            cell = NSIntersectionRect(cell, rect);
            [((r + c) % 2 == 0 ? c1 : c2) setFill];
            NSRectFill(cell);
        }
    }
}

- (void)drawScaleAtCenter:(NSPoint)center radius:(CGFloat)radius scale:(CGFloat)scale {
    ScaleParameters *p = _parameters;
    CGFloat cx = center.x, cy = center.y;
    CGFloat maxTickWidth = MAX(p.majorTickWidth, p.showMinorTicks ? p.minorTickWidth : 0.0) * scale;
    CGFloat tickR = MIN(radius * p.tickRadius, radius - maxTickWidth / 2.0);
    tickR = MAX(0, tickR);
    NSRect frameRect = NSMakeRect(cx - radius, cy - radius, radius * 2.0, radius * 2.0);

    CGFloat totalRange = p.endAngle - p.startAngle;
    if (fabs(totalRange) < 0.001) totalRange = 360.0;

    NSInteger majorCount = MAX(2, p.majorTickCount);
    NSInteger minorCount = p.showMinorTicks ? MAX(0, p.minorTickCount) : 0;
    NSInteger totalIntervals = (majorCount - 1) * (minorCount + 1);

    // Draw minor ticks first
    for (NSInteger i = 0; i <= totalIntervals; i++) {
        BOOL isMajor = (i % (minorCount + 1) == 0);
        if (isMajor) continue;

        CGFloat fraction = (CGFloat)i / totalIntervals;
        CGFloat visualAngle = p.startAngle + fraction * totalRange;
        CGFloat rad = visualToMathRad(visualAngle);

        CGFloat len = p.minorTickLength * scale;
        CGFloat width = MAX(0.5, p.minorTickWidth * scale);

        CGFloat x1 = cx + tickR * cos(rad);
        CGFloat y1 = cy + tickR * sin(rad);
        CGFloat x2 = cx + (tickR - len) * cos(rad);
        CGFloat y2 = cy + (tickR - len) * sin(rad);

        NSBezierPath *tick = [NSBezierPath bezierPath];
        tick.lineCapStyle = NSLineCapStyleRound;
        tick.lineWidth = width;
        [tick moveToPoint:NSMakePoint(x1, y1)];
        [tick lineToPoint:NSMakePoint(x2, y2)];
        [p.tickColor setStroke];
        [tick stroke];
    }

    // Draw major ticks and labels
    NSFont *font = p.showLabels ? [NSFont systemFontOfSize:MAX(6, p.fontSize * scale)] : nil;
    NSDictionary *textAttrs = p.showLabels ? @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: p.labelColor
    } : nil;

    for (NSInteger i = 0; i <= totalIntervals; i++) {
        BOOL isMajor = (i % (minorCount + 1) == 0);
        if (!isMajor) continue;

        CGFloat fraction = (CGFloat)i / totalIntervals;
        CGFloat visualAngle = p.startAngle + fraction * totalRange;
        CGFloat rad = visualToMathRad(visualAngle);

        CGFloat len = p.majorTickLength * scale;
        CGFloat width = MAX(0.5, p.majorTickWidth * scale);

        CGFloat x1 = cx + tickR * cos(rad);
        CGFloat y1 = cy + tickR * sin(rad);
        CGFloat x2 = cx + (tickR - len) * cos(rad);
        CGFloat y2 = cy + (tickR - len) * sin(rad);

        NSBezierPath *tick = [NSBezierPath bezierPath];
        tick.lineCapStyle = NSLineCapStyleRound;
        tick.lineWidth = width;
        [tick moveToPoint:NSMakePoint(x1, y1)];
        [tick lineToPoint:NSMakePoint(x2, y2)];
        [p.tickColor setStroke];
        [tick stroke];

        if (p.showLabels) {
            NSInteger majorIndex = i / (minorCount + 1);
            CGFloat vf = (majorCount > 1) ? (CGFloat)majorIndex / (CGFloat)(majorCount - 1) : 0.0;
            CGFloat value = p.minValue + vf * (p.maxValue - p.minValue);

            NSString *lbl;
            if (p.decimalPlaces == 0) {
                lbl = [NSString stringWithFormat:@"%@%ld%@", p.labelPrefix, (long)round(value), p.labelSuffix];
            } else {
                lbl = [NSString stringWithFormat:@"%@%.*f%@", p.labelPrefix, (int)p.decimalPlaces, value, p.labelSuffix];
            }

            CGFloat fontSize = MAX(6, p.fontSize * scale);
            CGFloat labelR;
            CGFloat offset = p.labelOffset * scale;
            if (p.labelsOutside) {
                // Outside: beyond the tick outer edge
                labelR = tickR + fontSize * 0.85 + offset;
            } else {
                // Inside: between tick inner edge and center
                labelR = tickR - len - fontSize * 0.75 - offset;
            }
            CGFloat lx = cx + labelR * cos(rad);
            CGFloat ly = cy + labelR * sin(rad);

            NSSize ts = [lbl sizeWithAttributes:textAttrs];
            CGFloat textX = clampCGFloat(lx - ts.width / 2.0, NSMinX(frameRect), NSMaxX(frameRect) - ts.width);
            CGFloat textY = clampCGFloat(ly - ts.height / 2.0, NSMinY(frameRect), NSMaxY(frameRect) - ts.height);
            NSRect tr = NSMakeRect(textX, textY, ts.width, ts.height);
            [lbl drawInRect:tr withAttributes:textAttrs];
        }
    }

    // Center dot
    if (p.showCenterDot) {
        CGFloat dotR = MAX(1, p.centerDotRadius * scale);
        NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:
            NSMakeRect(cx - dotR, cy - dotR, dotR * 2, dotR * 2)];
        [p.centerDotColor setFill];
        [dot fill];
    }
}

#pragma mark - Export

- (NSImage *)renderImage {
    NSInteger size = _parameters.imageSize;
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(size, size)];
    [image lockFocus];

    NSRect rect = NSMakeRect(0, 0, size, size);
    CGFloat radius = size / 2.0 - 2.0;
    CGFloat scale = (CGFloat)size / _parameters.diameter;

    if (_parameters.transparentBackground) {
        [[NSColor clearColor] setFill];
        NSRectFill(rect);
    } else {
        [_parameters.backgroundColor setFill];
        NSRectFill(rect);
    }

    [self drawScaleAtCenter:NSMakePoint(size / 2.0, size / 2.0) radius:radius scale:scale];

    [image unlockFocus];
    return image;
}

- (NSString *)generateSVG {
    ScaleParameters *p = _parameters;
    NSInteger size = p.imageSize;
    CGFloat cx = size / 2.0, cy = size / 2.0;
    CGFloat radius = size / 2.0 - 2.0;
    CGFloat scale = (CGFloat)size / p.diameter;
    CGFloat maxTickWidth = MAX(p.majorTickWidth, p.showMinorTicks ? p.minorTickWidth : 0.0) * scale;
    CGFloat tickR = MIN(radius * p.tickRadius, radius - maxTickWidth / 2.0);
    tickR = MAX(0, tickR);
    NSRect frameRect = NSMakeRect(cx - radius, cy - radius, radius * 2.0, radius * 2.0);

    CGFloat totalRange = p.endAngle - p.startAngle;
    if (fabs(totalRange) < 0.001) totalRange = 360.0;

    NSInteger majorCount = MAX(2, p.majorTickCount);
    NSInteger minorCount = p.showMinorTicks ? MAX(0, p.minorTickCount) : 0;
    NSInteger totalIntervals = (majorCount - 1) * (minorCount + 1);

    NSMutableString *svg = [NSMutableString string];
    [svg appendFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
    [svg appendFormat:@"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"%ld\" height=\"%ld\">\n", (long)size, (long)size];

    if (!p.transparentBackground) {
        [svg appendFormat:@"  <rect width=\"%ld\" height=\"%ld\" fill=\"%@\"/>\n",
         (long)size, (long)size, colorToSVGHex(p.backgroundColor)];
    }

    NSString *tickHex = colorToSVGHex(p.tickColor);

    // Minor ticks
    for (NSInteger i = 0; i <= totalIntervals; i++) {
        BOOL isMajor = (i % (minorCount + 1) == 0);
        if (isMajor) continue;
        CGFloat fraction = (CGFloat)i / totalIntervals;
        CGFloat visualAngle = p.startAngle + fraction * totalRange;
        CGFloat rad = visualToSVGRad(visualAngle);
        CGFloat len = p.minorTickLength * scale;
        CGFloat w = MAX(0.5, p.minorTickWidth * scale);
        CGFloat x1 = cx + tickR * cos(rad);
        CGFloat y1 = cy + tickR * sin(rad);
        CGFloat x2 = cx + (tickR - len) * cos(rad);
        CGFloat y2 = cy + (tickR - len) * sin(rad);
        [svg appendFormat:@"  <line x1=\"%.2f\" y1=\"%.2f\" x2=\"%.2f\" y2=\"%.2f\" stroke=\"%@\" stroke-width=\"%.2f\" stroke-linecap=\"round\"/>\n",
         x1, y1, x2, y2, tickHex, w];
    }

    // Major ticks and labels
    NSString *labelHex = colorToSVGHex(p.labelColor);
    CGFloat svgFontSize = MAX(6, p.fontSize * scale);

    for (NSInteger i = 0; i <= totalIntervals; i++) {
        BOOL isMajor = (i % (minorCount + 1) == 0);
        if (!isMajor) continue;
        CGFloat fraction = (CGFloat)i / totalIntervals;
        CGFloat visualAngle = p.startAngle + fraction * totalRange;
        CGFloat rad = visualToSVGRad(visualAngle);
        CGFloat len = p.majorTickLength * scale;
        CGFloat w = MAX(0.5, p.majorTickWidth * scale);
        CGFloat x1 = cx + tickR * cos(rad);
        CGFloat y1 = cy + tickR * sin(rad);
        CGFloat x2 = cx + (tickR - len) * cos(rad);
        CGFloat y2 = cy + (tickR - len) * sin(rad);
        [svg appendFormat:@"  <line x1=\"%.2f\" y1=\"%.2f\" x2=\"%.2f\" y2=\"%.2f\" stroke=\"%@\" stroke-width=\"%.2f\" stroke-linecap=\"round\"/>\n",
         x1, y1, x2, y2, tickHex, w];

        if (p.showLabels) {
            NSInteger majorIndex = i / (minorCount + 1);
            CGFloat vf = (majorCount > 1) ? (CGFloat)majorIndex / (CGFloat)(majorCount - 1) : 0.0;
            CGFloat value = p.minValue + vf * (p.maxValue - p.minValue);
            NSString *lbl;
            if (p.decimalPlaces == 0) {
                lbl = [NSString stringWithFormat:@"%@%ld%@", p.labelPrefix, (long)round(value), p.labelSuffix];
            } else {
                lbl = [NSString stringWithFormat:@"%@%.*f%@", p.labelPrefix, (int)p.decimalPlaces, value, p.labelSuffix];
            }
            CGFloat offset = p.labelOffset * scale;
            CGFloat labelR = p.labelsOutside
                ? tickR + svgFontSize * 0.85 + offset
                : tickR - len - svgFontSize * 0.75 - offset;
            CGFloat lx = cx + labelR * cos(rad);
            CGFloat ly = cy + labelR * sin(rad);
            NSDictionary *svgTextAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:svgFontSize]};
            NSSize ts = [lbl sizeWithAttributes:svgTextAttrs];
            lx = clampCGFloat(lx, NSMinX(frameRect) + ts.width / 2.0, NSMaxX(frameRect) - ts.width / 2.0);
            ly = clampCGFloat(ly, NSMinY(frameRect) + ts.height / 2.0, NSMaxY(frameRect) - ts.height / 2.0);
            [svg appendFormat:@"  <text x=\"%.2f\" y=\"%.2f\" font-family=\"system-ui,sans-serif\" font-size=\"%.1f\" fill=\"%@\" text-anchor=\"middle\" dominant-baseline=\"central\">%@</text>\n",
             lx, ly, svgFontSize, labelHex, lbl];
        }
    }

    if (p.showCenterDot) {
        CGFloat dotR = MAX(1, p.centerDotRadius * scale);
        NSString *dotHex = colorToSVGHex(p.centerDotColor);
        [svg appendFormat:@"  <circle cx=\"%.2f\" cy=\"%.2f\" r=\"%.2f\" fill=\"%@\"/>\n",
         cx, cy, dotR, dotHex];
    }

    [svg appendString:@"</svg>\n"];
    return [svg copy];
}

@end
