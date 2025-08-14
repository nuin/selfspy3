//
//  ModernSelfspyWidget.m
//  SelfspyWidgets
//
//  Modern macOS widget implementation
//

#import "ModernSelfspyWidget.h"

@implementation ModernSelfspyWidget

- (instancetype)initWithPosition:(NSPoint)position {
    NSLog(@"🔧 ModernSelfspyWidget initWithPosition called");
    self = [super init];
    if (self) {
        NSLog(@"🔧 Setting up basic properties...");
        _position = position;
        _size = NSMakeSize(320, 200);
        _title = @"Selfspy Widget";
        _data = [[NSMutableDictionary alloc] init];
        
        NSLog(@"🔧 Setting up window...");
        [self setupWindow];
        NSLog(@"🔧 Setting up content view...");
        [self setupContentView];
        NSLog(@"🔧 Fetching initial data...");
        [self fetchData];
        
        NSLog(@"🔧 Setting up timer...");
        // Set up auto-refresh timer
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                        target:self
                                                      selector:@selector(updateData)
                                                      userInfo:nil
                                                       repeats:YES];
        NSLog(@"🔧 ModernSelfspyWidget initialization complete");
    }
    return self;
}

- (void)dealloc {
    [_updateTimer invalidate];
}

- (void)setupWindow {
    NSRect windowRect = NSMakeRect(self.position.x, self.position.y, 
                                  self.size.width, self.size.height);
    
    // Create modern window with full-size content view
    self.window = [[NSWindow alloc] initWithContentRect:windowRect
                                              styleMask:NSWindowStyleMaskTitled | 
                                                       NSWindowStyleMaskClosable |
                                                       NSWindowStyleMaskMiniaturizable |
                                                       NSWindowStyleMaskResizable |
                                                       NSWindowStyleMaskFullSizeContentView
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    
    // Modern window properties
    [self.window setTitle:self.title];
    [self.window setTitlebarAppearsTransparent:YES];
    [self.window setMovableByWindowBackground:YES];
    [self.window setLevel:NSNormalWindowLevel];
    [self.window setHasShadow:YES];
    
    // Set size constraints
    [self.window setMinSize:NSMakeSize(280, 160)];
    [self.window setMaxSize:NSMakeSize(800, 600)];
    
    // Add visual effect background
    NSVisualEffectView *visualEffectView = [[NSVisualEffectView alloc] init];
    visualEffectView.material = NSVisualEffectMaterialHUDWindow;
    visualEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    visualEffectView.state = NSVisualEffectStateActive;
    visualEffectView.wantsLayer = YES;
    visualEffectView.layer.cornerRadius = 12.0;
    
    [self.window setContentView:visualEffectView];
}

- (void)setupContentView {
    NSLog(@"🔧 Getting effect view...");
    NSVisualEffectView *effectView = (NSVisualEffectView *)self.window.contentView;
    NSLog(@"🔧 Effect view: %@", effectView);
    
    NSLog(@"🔧 Creating content stack...");
    // Create main content stack
    self.contentStack = [[NSStackView alloc] init];
    self.contentStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.contentStack.spacing = 16;
    self.contentStack.edgeInsets = NSEdgeInsetsMake(40, 20, 20, 20); // Top padding for titlebar
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLog(@"🔧 Adding stack to effect view...");
    [effectView addSubview:self.contentStack];
    
    NSLog(@"🔧 Setting up constraints...");
    // Pin stack to edges
    [NSLayoutConstraint activateConstraints:@[
        [self.contentStack.topAnchor constraintEqualToAnchor:effectView.topAnchor],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:effectView.leadingAnchor],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:effectView.trailingAnchor],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:effectView.bottomAnchor]
    ]];
    
    NSLog(@"🔧 Creating title label...");
    // Create title label
    self.titleLabel = [[NSTextField alloc] init];
    self.titleLabel.stringValue = self.title;
    self.titleLabel.font = [NSFont boldSystemFontOfSize:16];
    self.titleLabel.textColor = [NSColor labelColor];
    self.titleLabel.backgroundColor = [NSColor clearColor];
    self.titleLabel.bordered = NO;
    self.titleLabel.editable = NO;
    self.titleLabel.selectable = NO;
    self.titleLabel.alignment = NSTextAlignmentCenter;
    
    NSLog(@"🔧 Adding title to stack...");
    [self.contentStack addArrangedSubview:self.titleLabel];
    
    NSLog(@"🔧 Creating content view from subclass...");
    // Create content view from subclass
    self.contentView = [self createContentView];
    NSLog(@"🔧 Content view created: %@", self.contentView);
    if (self.contentView) {
        NSLog(@"🔧 Adding content view to stack...");
        [self.contentStack addArrangedSubview:self.contentView];
    }
    
    NSLog(@"🔧 Setting up data views...");
    [self setupDataViews];
    NSLog(@"🔧 setupContentView complete");
}

- (void)show {
    NSLog(@"📱 Attempting to show window: %@", self.title);
    NSLog(@"📱 Window object: %@", self.window);
    NSLog(@"📱 Window frame: %@", NSStringFromRect([self.window frame]));
    
    // Activate the application first
    [NSApp activateIgnoringOtherApps:YES];
    
    // Show and bring to front
    [self.window makeKeyAndOrderFront:nil];
    [self.window orderFrontRegardless];
    
    // Make sure it's on the current space
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    
    NSLog(@"📱 Window visible: %@", [self.window isVisible] ? @"YES" : @"NO");
    NSLog(@"📱 Window on screen: %@", [self.window isOnActiveSpace] ? @"YES" : @"NO");
    
    NSLog(@"✅ Showing modern widget: %@", self.title);
}

- (void)hide {
    [self.window orderOut:nil];
}

- (void)updateData {
    [self fetchData];
    [self setupDataViews];
}

// Override in subclasses
- (void)fetchData {
    // Base implementation
}

- (void)setupDataViews {
    // Base implementation - update views with data
}

- (NSView *)createContentView {
    // Base implementation - override in subclasses
    NSView *view = [[NSView alloc] init];
    view.wantsLayer = YES;
    return view;
}

@end