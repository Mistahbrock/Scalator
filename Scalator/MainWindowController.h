#import <Cocoa/Cocoa.h>

@interface MainWindowController : NSWindowController
- (void)openDocument:(id)sender;
- (void)openProjectFromURL:(NSURL *)url;
- (void)saveDocument:(id)sender;
- (void)saveDocumentAs:(id)sender;
- (void)exportPNG:(id)sender;
- (void)exportSVG:(id)sender;
- (void)copyToClipboard:(id)sender;
@end
