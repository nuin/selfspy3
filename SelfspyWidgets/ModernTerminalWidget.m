//
//  ModernTerminalWidget.m
//  SelfspyWidgets
//
//  Modern terminal activity widget implementation
//

#import "ModernTerminalWidget.h"

@interface CommandView : NSView
@property (strong, nonatomic) NSTextField *commandLabel;
@property (strong, nonatomic) NSTextField *timeLabel;
@end

@implementation CommandView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [[NSColor textBackgroundColor] CGColor];
        self.layer.cornerRadius = 6.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [[NSColor separatorColor] CGColor];
        
        NSStackView *stack = [[NSStackView alloc] init];
        stack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        stack.spacing = 8;
        stack.edgeInsets = NSEdgeInsetsMake(6, 10, 6, 10);
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Command label
        self.commandLabel = [[NSTextField alloc] init];
        self.commandLabel.font = [NSFont fontWithName:@"SF Mono" size:11] ?: [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
        self.commandLabel.textColor = [NSColor labelColor];
        self.commandLabel.backgroundColor = [NSColor clearColor];
        self.commandLabel.bordered = NO;
        self.commandLabel.editable = NO;
        self.commandLabel.selectable = NO;
        
        // Time label
        self.timeLabel = [[NSTextField alloc] init];
        self.timeLabel.font = [NSFont systemFontOfSize:9];
        self.timeLabel.textColor = [NSColor tertiaryLabelColor];
        self.timeLabel.backgroundColor = [NSColor clearColor];
        self.timeLabel.bordered = NO;
        self.timeLabel.editable = NO;
        self.timeLabel.selectable = NO;
        [self.timeLabel setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
        
        [stack addArrangedSubview:self.commandLabel];
        [stack addArrangedSubview:self.timeLabel];
        
        [self addSubview:stack];
        
        [NSLayoutConstraint activateConstraints:@[
            [stack.topAnchor constraintEqualToAnchor:self.topAnchor],
            [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [self.heightAnchor constraintGreaterThanOrEqualToConstant:28]
        ]];
    }
    return self;
}

- (void)setCommand:(NSString *)command time:(NSString *)time {
    self.commandLabel.stringValue = [NSString stringWithFormat:@"$ %@", command];
    self.timeLabel.stringValue = time;
}

@end

@implementation ModernTerminalWidget

- (instancetype)initWithPosition:(NSPoint)position {
    self = [super initWithPosition:position];
    if (self) {
        self.title = @"🔧 Terminal Activity";
        self.size = NSMakeSize(400, 300);
        [self.window setTitle:self.title];
    }
    return self;
}

- (void)fetchData {
    // Simulate terminal data
    NSInteger commandsToday = 142 + (arc4random() % 20);
    
    [self.data setObject:@(commandsToday) forKey:@"commands_today"];
    [self.data setObject:@"git" forKey:@"most_used_command"];
    [self.data setObject:@"selfspy3" forKey:@"current_project"];
    [self.data setObject:@[@"git status", @"uv run pytest", @"code .", @"git add .", @"make clean && make", @"./SelfspyWidgets", @"git commit -m"] 
                  forKey:@"recent_commands"];
}

- (NSView *)createContentView {
    NSStackView *mainStack = [[NSStackView alloc] init];
    mainStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    mainStack.spacing = 12;
    
    // Summary section
    NSView *summaryView = [[NSView alloc] init];
    summaryView.wantsLayer = YES;
    summaryView.layer.backgroundColor = [[NSColor controlAccentColor] colorWithAlphaComponent:0.1].CGColor;
    summaryView.layer.cornerRadius = 8.0;
    
    NSTextField *summaryLabel = [[NSTextField alloc] init];
    summaryLabel.font = [NSFont systemFontOfSize:12];
    summaryLabel.textColor = [NSColor labelColor];
    summaryLabel.backgroundColor = [NSColor clearColor];
    summaryLabel.bordered = NO;
    summaryLabel.editable = NO;
    summaryLabel.selectable = NO;
    summaryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [summaryView addSubview:summaryLabel];
    [NSLayoutConstraint activateConstraints:@[
        [summaryLabel.topAnchor constraintEqualToAnchor:summaryView.topAnchor constant:8],
        [summaryLabel.leadingAnchor constraintEqualToAnchor:summaryView.leadingAnchor constant:12],
        [summaryLabel.trailingAnchor constraintEqualToAnchor:summaryView.trailingAnchor constant:-12],
        [summaryLabel.bottomAnchor constraintEqualToAnchor:summaryView.bottomAnchor constant:-8]
    ]];
    
    // Recent commands section
    NSTextField *recentLabel = [[NSTextField alloc] init];
    recentLabel.stringValue = @"Recent Commands";
    recentLabel.font = [NSFont boldSystemFontOfSize:13];
    recentLabel.textColor = [NSColor labelColor];
    recentLabel.backgroundColor = [NSColor clearColor];
    recentLabel.bordered = NO;
    recentLabel.editable = NO;
    recentLabel.selectable = NO;
    
    // Commands scroll view
    self.commandScrollView = [[NSScrollView alloc] init];
    self.commandScrollView.hasVerticalScroller = YES;
    self.commandScrollView.hasHorizontalScroller = NO;
    self.commandScrollView.borderType = NSNoBorder;
    self.commandScrollView.backgroundColor = [NSColor clearColor];
    
    self.commandStack = [[NSStackView alloc] init];
    self.commandStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.commandStack.spacing = 4;
    self.commandStack.edgeInsets = NSEdgeInsetsMake(4, 4, 4, 4);
    
    [self.commandScrollView setDocumentView:self.commandStack];
    
    [mainStack addArrangedSubview:summaryView];
    [mainStack addArrangedSubview:recentLabel];
    [mainStack addArrangedSubview:self.commandScrollView];
    
    // Store reference to summary label for updates
    [self.data setObject:summaryLabel forKey:@"summary_label"];
    
    return mainStack;
}

- (void)setupDataViews {
    // Update summary
    NSTextField *summaryLabel = [self.data objectForKey:@"summary_label"];
    if (summaryLabel) {
        NSString *summary = [NSString stringWithFormat:@"📊 %@ commands today  •  🏆 %@  •  📁 %@",
                            [self.data objectForKey:@"commands_today"],
                            [self.data objectForKey:@"most_used_command"],
                            [self.data objectForKey:@"current_project"]];
        summaryLabel.stringValue = summary;
    }
    
    // Clear existing command views
    for (NSView *view in [self.commandStack.arrangedSubviews copy]) {
        [self.commandStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    // Add recent commands
    NSArray *recentCommands = [self.data objectForKey:@"recent_commands"];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm"];
    
    for (int i = 0; i < MIN([recentCommands count], 8); i++) {
        NSString *command = recentCommands[i];
        
        CommandView *commandView = [[CommandView alloc] init];
        
        // Generate fake recent times
        NSDate *commandTime = [NSDate dateWithTimeIntervalSinceNow:-(i * 300)]; // 5 min intervals
        NSString *timeString = [timeFormatter stringFromDate:commandTime];
        
        [commandView setCommand:command time:timeString];
        [self.commandStack addArrangedSubview:commandView];
    }
}

@end