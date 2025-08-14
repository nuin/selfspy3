//
//  ModernSelfspyWidget.h
//  SelfspyWidgets
//
//  Modern macOS widget with proper native styling
//

#import <Cocoa/Cocoa.h>

@interface ModernSelfspyWidget : NSObject

@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) NSStackView *contentStack;
@property (strong, nonatomic) NSTextField *titleLabel;
@property (strong, nonatomic) NSView *contentView;
@property (assign, nonatomic) NSPoint position;
@property (assign, nonatomic) NSSize size;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSMutableDictionary *data;
@property (strong, nonatomic) NSTimer *updateTimer;

- (instancetype)initWithPosition:(NSPoint)position;
- (void)setupWindow;
- (void)setupContentView;
- (void)show;
- (void)hide;
- (void)updateData;

// Override in subclasses
- (void)fetchData;
- (void)setupDataViews;
- (NSView *)createContentView;

@end