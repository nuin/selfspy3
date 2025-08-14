//
//  SelfspyWidget.m
//  SelfspyWidgets
//
//  Base widget implementation
//

#import "SelfspyWidget.h"

@interface SelfspyWidgetView : NSView
@property (weak, nonatomic) SelfspyWidget *widget;
@end

@implementation SelfspyWidgetView

- (void)drawRect:(NSRect)dirtyRect {
    // Clear background
    [[NSColor clearColor] set];
    NSRectFill(dirtyRect);
    
    // Call widget's draw method
    if (self.widget) {
        [self.widget drawContent:dirtyRect];
    }
}

- (void)mouseDown:(NSEvent *)event {
    // Normal window behavior - no custom dragging needed
    [super mouseDown:event];
}

@end

@implementation SelfspyWidget

- (instancetype)initWithPosition:(NSPoint)position {
    self = [super init];
    if (self) {
        _position = position;
        _size = NSMakeSize(280, 180);  // Default size
        _title = @"Selfspy Widget";
        _data = [[NSMutableDictionary alloc] init];
        
        [self setupWindow];
        [self setupContentView];
        
        // Fetch initial data
        [self fetchData];
        
        NSLog(@"Created widget '%@' at position (%.0f, %.0f) with size (%.0f, %.0f)", 
              self.title, position.x, position.y, self.size.width, self.size.height);
    }
    return self;
}

- (void)setupWindow {
    NSRect windowRect = NSMakeRect(self.position.x, self.position.y, 
                                  self.size.width, self.size.height);
    
    // Create a normal window with title bar and controls
    self.window = [[NSWindow alloc] initWithContentRect:windowRect
                                              styleMask:NSWindowStyleMaskTitled | 
                                                       NSWindowStyleMaskClosable |
                                                       NSWindowStyleMaskMiniaturizable |
                                                       NSWindowStyleMaskResizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    
    // Window properties for small desktop window
    [self.window setTitle:self.title];
    [self.window setLevel:NSNormalWindowLevel];  // Normal window level
    [self.window setOpaque:YES];
    [self.window setBackgroundColor:[NSColor controlBackgroundColor]];
    [self.window setHasShadow:YES];
    [self.window setMovableByWindowBackground:NO];  // Use title bar for moving
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorDefault];
    
    // Set minimum and maximum sizes
    [self.window setMinSize:NSMakeSize(200, 120)];
    [self.window setMaxSize:NSMakeSize(600, 400)];
    
    NSLog(@"Setup window with title '%@' at (%.0f, %.0f)", self.title, windowRect.origin.x, windowRect.origin.y);
}

- (void)setupContentView {
    NSRect contentRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    SelfspyWidgetView *contentView = [[SelfspyWidgetView alloc] initWithFrame:contentRect];
    contentView.widget = self;
    
    // Set up the view appearance for normal window
    [contentView.layer setBackgroundColor:[[NSColor controlBackgroundColor] CGColor]];
    [contentView.layer setCornerRadius:0.0];  // No rounded corners for normal windows
    [contentView.layer setBorderWidth:0.0];   // No border needed
    
    [contentView setWantsLayer:YES];
    [self.window setContentView:contentView];
    self.contentView = contentView;
}

- (void)show {
    [self.window makeKeyAndOrderFront:nil];
    NSLog(@"Showing window '%@' - visible: %@", self.title, [self.window isVisible] ? @"YES" : @"NO");
}

- (void)hide {
    [self.window orderOut:nil];
}

- (void)updateData {
    [self fetchData];
    [self refresh];
}

- (void)refresh {
    [self.contentView setNeedsDisplay:YES];
}

// Override in subclasses
- (void)fetchData {
    // Base implementation - override in subclasses
}

- (void)drawContent:(NSRect)rect {
    // Base implementation - override in subclasses
    NSString *title = self.title;
    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:16],
        NSForegroundColorAttributeName: [NSColor labelColor]
    };
    
    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:title attributes:titleAttributes];
    [titleString drawAtPoint:NSMakePoint(16, rect.size.height - 40)];
}

- (void)updateWindowTitle {
    [self.window setTitle:self.title];
    NSLog(@"Updated window title to '%@'", self.title);
}

@end