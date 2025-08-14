//
//  SelfspyWidget.h
//  SelfspyWidgets
//
//  Base class for all desktop widgets
//

#import <Cocoa/Cocoa.h>

@interface SelfspyWidget : NSObject

@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) NSView *contentView;
@property (assign, nonatomic) NSPoint position;
@property (assign, nonatomic) NSSize size;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSMutableDictionary *data;

- (instancetype)initWithPosition:(NSPoint)position;
- (void)setupWindow;
- (void)setupContentView;
- (void)show;
- (void)hide;
- (void)updateData;
- (void)refresh;

// Override in subclasses
- (void)fetchData;
- (void)drawContent:(NSRect)rect;

// Utility methods
- (void)updateWindowTitle;

@end