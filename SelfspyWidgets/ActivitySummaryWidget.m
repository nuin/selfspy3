//
//  ActivitySummaryWidget.m
//  SelfspyWidgets
//
//  Activity summary widget implementation
//

#import "ActivitySummaryWidget.h"

@implementation ActivitySummaryWidget

- (instancetype)initWithPosition:(NSPoint)position {
    self = [super initWithPosition:position];
    if (self) {
        self.title = @"📊 Today's Activity";
        self.size = NSMakeSize(300, 180);
        [self updateWindowTitle];  // Update title after setting it
    }
    return self;
}

- (void)fetchData {
    // Simulate fetching real data from Selfspy
    // In a real implementation, this would read from the Selfspy database
    
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

- (void)drawContent:(NSRect)rect {
    CGFloat margin = 16;
    CGFloat y = rect.size.height - margin - 20;
    
    // Title
    NSDictionary *titleAttrs = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:16],
        NSForegroundColorAttributeName: [NSColor labelColor]
    };
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:self.title attributes:titleAttrs];
    [title drawAtPoint:NSMakePoint(margin, y)];
    y -= 35;
    
    // Statistics
    NSDictionary *statsAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:12],
        NSForegroundColorAttributeName: [NSColor secondaryLabelColor]
    };
    
    NSArray *statsLines = @[
        [NSString stringWithFormat:@"⌨️  %@ keystrokes", [self.data objectForKey:@"keystrokes"]],
        [NSString stringWithFormat:@"🖱️  %@ clicks", [self.data objectForKey:@"clicks"]],
        [NSString stringWithFormat:@"⏰ %@ active", [self.data objectForKey:@"active_time"]],
        [NSString stringWithFormat:@"🪟 %@ windows", [self.data objectForKey:@"windows_visited"]],
        [NSString stringWithFormat:@"💻 %@", [self.data objectForKey:@"top_app"]],
        [NSString stringWithFormat:@"📈 %@%% productive", [self.data objectForKey:@"productivity_score"]]
    ];
    
    for (NSString *line in statsLines) {
        NSAttributedString *stat = [[NSAttributedString alloc] initWithString:line attributes:statsAttrs];
        [stat drawAtPoint:NSMakePoint(margin, y)];
        y -= 22;
    }
    
    // Update indicator (green dot in top-right)
    NSRect indicatorRect = NSMakeRect(rect.size.width - 16, rect.size.height - 16, 8, 8);
    [[NSColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:0.8] setFill];
    [[NSBezierPath bezierPathWithOvalInRect:indicatorRect] fill];
    
    // Timestamp
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [NSString stringWithFormat:@"Updated: %@", [formatter stringFromDate:now]];
    
    NSDictionary *timestampAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:9],
        NSForegroundColorAttributeName: [NSColor tertiaryLabelColor]
    };
    NSAttributedString *timestamp = [[NSAttributedString alloc] initWithString:timeString attributes:timestampAttrs];
    [timestamp drawAtPoint:NSMakePoint(8, 8)];
}

@end