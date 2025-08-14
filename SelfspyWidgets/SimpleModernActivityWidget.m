//
//  SimpleModernActivityWidget.m
//  SelfspyWidgets
//
//  Simplified modern activity widget implementation
//

#import "SimpleModernActivityWidget.h"

@implementation SimpleModernActivityWidget

- (instancetype)initWithPosition:(NSPoint)position {
    NSLog(@"📊 SimpleModernActivityWidget initWithPosition called");
    self = [super initWithPosition:position];
    if (self) {
        NSLog(@"📊 Setting simple activity widget properties...");
        self.title = @"📊 Activity Summary";
        self.size = NSMakeSize(300, 200);
        [self.window setTitle:self.title];
        NSLog(@"📊 SimpleModernActivityWidget initialization complete");
    }
    return self;
}

- (void)fetchData {
    NSLog(@"📊 Fetching data for simple activity widget");
    // Simple mock data
    [self.data setObject:@"2,847" forKey:@"keystrokes"];
    [self.data setObject:@"892" forKey:@"clicks"];
    [self.data setObject:@"4h 23m" forKey:@"active_time"];
    [self.data setObject:@"Visual Studio Code" forKey:@"top_app"];
}

- (NSView *)createContentView {
    NSLog(@"📊 Creating simple content view");
    
    // Just create a simple stack with text labels
    NSStackView *stack = [[NSStackView alloc] init];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.spacing = 8;
    stack.distribution = NSStackViewDistributionFillEqually;
    
    return stack;
}

- (void)setupDataViews {
    NSLog(@"📊 Setting up simple data views");
    
    NSStackView *stack = (NSStackView *)self.contentView;
    
    // Clear existing views
    for (NSView *view in [stack.arrangedSubviews copy]) {
        [stack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    // Create simple text labels for each stat
    NSArray *stats = @[
        [NSString stringWithFormat:@"⌨️  %@ keystrokes", [self.data objectForKey:@"keystrokes"]],
        [NSString stringWithFormat:@"🖱️  %@ clicks", [self.data objectForKey:@"clicks"]],
        [NSString stringWithFormat:@"⏰ %@ active", [self.data objectForKey:@"active_time"]],
        [NSString stringWithFormat:@"💻 %@", [self.data objectForKey:@"top_app"]]
    ];
    
    for (NSString *statText in stats) {
        NSTextField *label = [[NSTextField alloc] init];
        label.stringValue = statText;
        label.font = [NSFont systemFontOfSize:14];
        label.textColor = [NSColor labelColor];
        label.backgroundColor = [NSColor clearColor];
        label.bordered = NO;
        label.editable = NO;
        label.selectable = NO;
        
        [stack addArrangedSubview:label];
    }
    
    NSLog(@"📊 Simple data views setup complete");
}

@end