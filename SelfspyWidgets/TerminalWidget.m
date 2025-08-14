//
//  TerminalWidget.m
//  SelfspyWidgets
//
//  Terminal activity widget implementation
//

#import "TerminalWidget.h"

@implementation TerminalWidget

- (instancetype)initWithPosition:(NSPoint)position {
    self = [super initWithPosition:position];
    if (self) {
        self.title = @"🔧 Terminal Activity";
        self.size = NSMakeSize(350, 200);
        [self updateWindowTitle];  // Update title after setting it
    }
    return self;
}

- (void)fetchData {
    // Simulate terminal data
    NSInteger commandsToday = 142 + (arc4random() % 20);
    
    [self.data setObject:@(commandsToday) forKey:@"commands_today"];
    [self.data setObject:@"git" forKey:@"most_used_command"];
    [self.data setObject:@"selfspy3" forKey:@"current_project"];
    [self.data setObject:@[@"git status", @"python simple_widget.py", @"uv run pytest", @"git add .", @"code ."] 
                  forKey:@"recent_commands"];
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
    
    // Summary line
    NSString *summary = [NSString stringWithFormat:@"📊 %@ commands today  •  🏆 %@  •  📁 %@",
                        [self.data objectForKey:@"commands_today"],
                        [self.data objectForKey:@"most_used_command"],
                        [self.data objectForKey:@"current_project"]];
    
    NSDictionary *summaryAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11],
        NSForegroundColorAttributeName: [NSColor secondaryLabelColor]
    };
    NSAttributedString *summaryString = [[NSAttributedString alloc] initWithString:summary attributes:summaryAttrs];
    [summaryString drawAtPoint:NSMakePoint(margin, y)];
    y -= 25;
    
    // Recent commands label
    NSDictionary *labelAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:11],
        NSForegroundColorAttributeName: [NSColor tertiaryLabelColor]
    };
    NSAttributedString *label = [[NSAttributedString alloc] initWithString:@"Recent commands:" attributes:labelAttrs];
    [label drawAtPoint:NSMakePoint(margin, y)];
    y -= 20;
    
    // Recent commands
    NSDictionary *commandAttrs = @{
        NSFontAttributeName: [NSFont fontWithName:@"Monaco" size:10],  // Monospace
        NSForegroundColorAttributeName: [NSColor labelColor]
    };
    
    NSArray *recentCommands = [self.data objectForKey:@"recent_commands"];
    for (NSString *command in recentCommands) {
        NSString *cmdLine = [NSString stringWithFormat:@"$ %@", command];
        NSAttributedString *cmdString = [[NSAttributedString alloc] initWithString:cmdLine attributes:commandAttrs];
        [cmdString drawAtPoint:NSMakePoint(margin + 8, y)];
        y -= 16;
        
        if (y < 30) break;  // Don't draw below the bottom
    }
}

@end