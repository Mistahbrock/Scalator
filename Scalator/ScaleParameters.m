#import "ScaleParameters.h"

@implementation ScaleParameters

- (instancetype)init {
    self = [super init];
    if (self) {
        _diameter = 200;
        _startAngle = -135;
        _endAngle = 135;
        _majorTickCount = 11;
        _minorTickCount = 4;
        _showMinorTicks = YES;
        _tickRadius = 0.88;
        _majorTickLength = 12;
        _minorTickLength = 6;
        _majorTickWidth = 2.0;
        _minorTickWidth = 1.0;
        _showLabels = YES;
        _minValue = 0;
        _maxValue = 100;
        _fontSize = 10;
        _decimalPlaces = 0;
        _labelPrefix = @"";
        _labelSuffix = @"";
        _labelOffset = 0;
        _tickColor = [NSColor whiteColor];
        _labelColor = [NSColor whiteColor];
        _transparentBackground = NO;
        _backgroundColor = [NSColor colorWithRed:0.18 green:0.18 blue:0.18 alpha:1.0];
        _showCenterDot = YES;
        _centerDotRadius = 3.5;
        _centerDotColor = [NSColor colorWithWhite:0.7 alpha:1.0];
        _labelsOutside = NO;
        _imageSize = 256;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ScaleParameters *copy = [[ScaleParameters alloc] init];
    copy.diameter = self.diameter;
    copy.startAngle = self.startAngle;
    copy.endAngle = self.endAngle;
    copy.majorTickCount = self.majorTickCount;
    copy.minorTickCount = self.minorTickCount;
    copy.showMinorTicks = self.showMinorTicks;
    copy.tickRadius = self.tickRadius;
    copy.majorTickLength = self.majorTickLength;
    copy.minorTickLength = self.minorTickLength;
    copy.majorTickWidth = self.majorTickWidth;
    copy.minorTickWidth = self.minorTickWidth;
    copy.showLabels = self.showLabels;
    copy.minValue = self.minValue;
    copy.maxValue = self.maxValue;
    copy.fontSize = self.fontSize;
    copy.decimalPlaces = self.decimalPlaces;
    copy.labelPrefix = [self.labelPrefix copy];
    copy.labelSuffix = [self.labelSuffix copy];
    copy.labelOffset = self.labelOffset;
    copy.tickColor = [self.tickColor copy];
    copy.labelColor = [self.labelColor copy];
    copy.transparentBackground = self.transparentBackground;
    copy.backgroundColor = [self.backgroundColor copy];
    copy.showCenterDot = self.showCenterDot;
    copy.centerDotRadius = self.centerDotRadius;
    copy.centerDotColor = [self.centerDotColor copy];
    copy.labelsOutside = self.labelsOutside;
    copy.imageSize = self.imageSize;
    return copy;
}

@end
