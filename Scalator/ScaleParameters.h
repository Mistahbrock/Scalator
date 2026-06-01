#import <Cocoa/Cocoa.h>

@interface ScaleParameters : NSObject <NSCopying>

// Geometry (reference diameter for export pixel measurements)
@property CGFloat diameter;

// Angles: degrees clockwise from 12 o'clock (top). -135 = 7:30, +135 = 4:30.
@property CGFloat startAngle;
@property CGFloat endAngle;

// Ticks
@property NSInteger majorTickCount;   // total major ticks including endpoints
@property NSInteger minorTickCount;   // minor ticks between each pair of majors
@property BOOL showMinorTicks;
@property CGFloat tickRadius;         // outer edge of ticks as fraction of radius (0..1)
@property CGFloat majorTickLength;    // pixels in reference space
@property CGFloat minorTickLength;
@property CGFloat majorTickWidth;
@property CGFloat minorTickWidth;

// Labels
@property BOOL showLabels;
@property CGFloat minValue;
@property CGFloat maxValue;
@property CGFloat fontSize;
@property NSInteger decimalPlaces;
@property NSString *labelPrefix;
@property NSString *labelSuffix;
@property CGFloat labelOffset;       // additional spacing from tick marks in reference pixels

// Appearance
@property NSColor *tickColor;
@property NSColor *labelColor;
@property BOOL transparentBackground;
@property NSColor *backgroundColor;
@property BOOL showCenterDot;
@property CGFloat centerDotRadius;
@property NSColor *centerDotColor;

// Label placement
@property BOOL labelsOutside;  // if YES labels sit outside the tick circle

// Export
@property NSInteger imageSize;

@end
