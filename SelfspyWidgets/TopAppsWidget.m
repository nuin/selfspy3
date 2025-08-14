//
//  TopAppsWidget.m
//  SelfspyWidgets
//
//  Top applications widget implementation
//

#import "TopAppsWidget.h"

@implementation TopAppsWidget

- (instancetype)initWithPosition:(NSPoint)position {
    self = [super initWithPosition:position];
    if (self) {
        self.title = @"🏆 Top Applications";
        self.size = NSMakeSize(320, 220);
        [self updateWindowTitle];  // Update title after setting it
    }
    return self;
}

- (void)fetchData {
    // Simulate top apps data
    NSArray *apps = @[
        @{@"name": @"Visual Studio Code", @"time": @"2h 15m", @"percentage": @52},
        @{@"name": @"Terminal", @"time": @"1h 8m", @"percentage": @26},
        @{@"name": @"Safari", @"time": @"45m", @"percentage": @17},
        @{@"name": @"Finder", @"time": @"12m", @"percentage": @5}
    ];
    
    [self.data setObject:apps forKey:@"apps"];
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
    
    // App list
    NSArray *apps = [self.data objectForKey:@"apps"];
    
    for (int i = 0; i < [apps count] && i < 4; i++) {
        NSDictionary *app = apps[i];
        
        // App name
        NSString *nameText = [NSString stringWithFormat:@"%d. %@", i+1, app[@"name"]];
        NSDictionary *nameAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:12],
            NSForegroundColorAttributeName: [NSColor labelColor]
        };
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:nameText attributes:nameAttrs];
        [name drawAtPoint:NSMakePoint(margin, y)];
        
        // Time
        NSDictionary *timeAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:11],
            NSForegroundColorAttributeName: [NSColor secondaryLabelColor]
        };
        NSAttributedString *time = [[NSAttributedString alloc] initWithString:app[@"time"] attributes:timeAttrs];
        [time drawAtPoint:NSMakePoint(margin + 140, y)];
        
        y -= 16;
        
        // Progress bar
        CGFloat barWidth = 200;
        CGFloat barHeight = 4;
        NSRect barRect = NSMakeRect(margin, y - 4, barWidth, barHeight);
        
        // Background
        [[NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] setFill];
        [NSBezierPath fillRect:barRect];
        
        // Fill
        CGFloat fillWidth = ([app[@"percentage"] floatValue] / 100.0) * barWidth;
        NSRect fillRect = NSMakeRect(margin, y - 4, fillWidth, barHeight);
        [[NSColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0] setFill];
        [NSBezierPath fillRect:fillRect];
        
        y -= 20;
    }
}

@end