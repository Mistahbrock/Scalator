#import <Cocoa/Cocoa.h>
#import "ScaleParameters.h"

@interface ScaleView : NSView

@property (strong) ScaleParameters *parameters;

// Render to an NSImage at the export size specified in parameters
- (NSImage *)renderImage;

// Generate SVG string at export size
- (NSString *)generateSVG;

@end
