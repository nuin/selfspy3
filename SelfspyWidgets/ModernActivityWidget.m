//
//  ModernActivityWidget.m
//  SelfspyWidgets
//
//  Modern activity summary widget implementation
//

#import "ModernActivityWidget.h"

@interface StatView : NSView
@property (strong, nonatomic) NSTextField *valueLabel;
@property (strong, nonatomic) NSTextField *titleLabel;
@property (strong, nonatomic) NSImageView *iconView;
@end

@implementation StatView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [[NSColor controlAccentColor] colorWithAlphaComponent:0.1].CGColor;
        self.layer.cornerRadius = 8.0;
        
        // Create stack for content
        NSStackView *stack = [[NSStackView alloc] init];
        stack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        stack.spacing = 8;
        stack.edgeInsets = NSEdgeInsetsMake(8, 12, 8, 12);
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Icon
        self.iconView = [[NSImageView alloc] init];
        [self.iconView setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
        
        // Text stack
        NSStackView *textStack = [[NSStackView alloc] init];
        textStack.orientation = NSUserInterfaceLayoutOrientationVertical;
        textStack.spacing = 2;
        textStack.alignment = NSLayoutAttributeLeading;
        
        // Value label
        self.valueLabel = [[NSTextField alloc] init];
        self.valueLabel.font = [NSFont boldSystemFontOfSize:18];
        self.valueLabel.textColor = [NSColor labelColor];
        self.valueLabel.backgroundColor = [NSColor clearColor];
        self.valueLabel.bordered = NO;
        self.valueLabel.editable = NO;
        self.valueLabel.selectable = NO;
        
        // Title label
        self.titleLabel = [[NSTextField alloc] init];
        self.titleLabel.font = [NSFont systemFontOfSize:11];
        self.titleLabel.textColor = [NSColor secondaryLabelColor];
        self.titleLabel.backgroundColor = [NSColor clearColor];
        self.titleLabel.bordered = NO;
        self.titleLabel.editable = NO;
        self.titleLabel.selectable = NO;
        
        [textStack addArrangedSubview:self.valueLabel];
        [textStack addArrangedSubview:self.titleLabel];
        
        [stack addArrangedSubview:self.iconView];
        [stack addArrangedSubview:textStack];
        
        [self addSubview:stack];
        
        [NSLayoutConstraint activateConstraints:@[
            [stack.topAnchor constraintEqualToAnchor:self.topAnchor],
            [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [self.heightAnchor constraintGreaterThanOrEqualToConstant:50]
        ]];
    }
    return self;
}

- (void)setIcon:(NSString *)iconName value:(NSString *)value title:(NSString *)title {
    // Use SF Symbols or emoji
    if ([iconName hasPrefix:@"sf:"]) {
        NSString *symbolName = [iconName substringFromIndex:3];
        if (@available(macOS 11.0, *)) {
            self.iconView.image = [NSImage imageWithSystemSymbolName:symbolName 
                                            accessibilityDescription:title];
            self.iconView.symbolConfiguration = [NSImageSymbolConfiguration configurationWithPointSize:20 weight:NSFontWeightMedium];
        }
    } else {
        // Use emoji or text as icon
        NSTextField *emojiLabel = [[NSTextField alloc] init];
        emojiLabel.stringValue = iconName;
        emojiLabel.font = [NSFont systemFontOfSize:20];
        emojiLabel.backgroundColor = [NSColor clearColor];
        emojiLabel.bordered = NO;
        emojiLabel.editable = NO;
        emojiLabel.selectable = NO;
        emojiLabel.alignment = NSTextAlignmentCenter;
        [emojiLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
        
        // Replace the icon view
        NSView *parent = self.iconView.superview;
        [self.iconView removeFromSuperview];
        [parent addSubview:emojiLabel positioned:NSWindowBelow relativeTo:nil];
        
        [NSLayoutConstraint activateConstraints:@[
            [emojiLabel.widthAnchor constraintEqualToConstant:30],
            [emojiLabel.centerYAnchor constraintEqualToAnchor:parent.centerYAnchor]
        ]];
    }
    
    self.valueLabel.stringValue = value;
    self.titleLabel.stringValue = title;
}

@end

@implementation ModernActivityWidget

- (instancetype)initWithPosition:(NSPoint)position {
    NSLog(@"📊 ModernActivityWidget initWithPosition called");
    self = [super initWithPosition:position];
    if (self) {
        NSLog(@"📊 Setting activity widget properties...");
        self.title = @"📊 Today's Activity";
        self.size = NSMakeSize(340, 280);
        self.statViews = [[NSMutableArray alloc] init];
        [self.window setTitle:self.title];
        NSLog(@"📊 ModernActivityWidget initialization complete");
    }
    return self;
}

- (void)fetchData {
    // Simulate fetching real data from Selfspy
    NSInteger keystrokes = 2847 + (arc4random() % 100);
    NSInteger clicks = 892 + (arc4random() % 20);
    NSInteger productivity = 78 + (arc4random() % 20);
    
    [self.data setObject:@(keystrokes) forKey:@"keystrokes"];
    [self.data setObject:@(clicks) forKey:@"clicks"];
    [self.data setObject:@"4h 23m" forKey:@"active_time"];
    [self.data setObject:@(47) forKey:@"windows_visited"];
    [self.data setObject:@(productivity) forKey:@"productivity_score"];
    [self.data setObject:@"Visual Studio Code" forKey:@"top_app"];
}

- (NSView *)createContentView {
    // Create grid of stat views
    self.statsStack = [[NSStackView alloc] init];
    self.statsStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.statsStack.spacing = 8;
    self.statsStack.distribution = NSStackViewDistributionFillEqually;
    
    return self.statsStack;
}

- (void)setupDataViews {
    // Clear existing views
    for (NSView *view in self.statViews) {
        [self.statsStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    [self.statViews removeAllObjects];
    
    // Create stat views
    NSArray *stats = @[
        @{@"icon": @"⌨️", @"value": [self.data objectForKey:@"keystrokes"], @"title": @"Keystrokes"},
        @{@"icon": @"🖱️", @"value": [self.data objectForKey:@"clicks"], @"title": @"Mouse Clicks"},
        @{@"icon": @"⏰", @"value": [self.data objectForKey:@"active_time"], @"title": @"Active Time"},
        @{@"icon": @"🪟", @"value": [self.data objectForKey:@"windows_visited"], @"title": @"Windows"},
        @{@"icon": @"📈", @"value": [NSString stringWithFormat:@"%@%%", [self.data objectForKey:@"productivity_score"]], @"title": @"Productivity"}
    ];
    
    for (NSDictionary *stat in stats) {
        StatView *statView = [[StatView alloc] init];
        [statView setIcon:stat[@"icon"] 
                    value:[stat[@"value"] description]
                    title:stat[@"title"]];
        
        [self.statsStack addArrangedSubview:statView];
        [self.statViews addObject:statView];
    }
    
    // Add timestamp
    NSTextField *timestampLabel = [[NSTextField alloc] init];
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    timestampLabel.stringValue = [NSString stringWithFormat:@"Updated: %@", [formatter stringFromDate:now]];
    timestampLabel.font = [NSFont systemFontOfSize:9];
    timestampLabel.textColor = [NSColor tertiaryLabelColor];
    timestampLabel.backgroundColor = [NSColor clearColor];
    timestampLabel.bordered = NO;
    timestampLabel.editable = NO;
    timestampLabel.selectable = NO;
    timestampLabel.alignment = NSTextAlignmentCenter;
    
    [self.statsStack addArrangedSubview:timestampLabel];
    [self.statViews addObject:timestampLabel];
}

@end