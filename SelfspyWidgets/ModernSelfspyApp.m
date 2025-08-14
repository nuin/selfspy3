//
//  ModernSelfspyApp.m
//  SelfspyWidgets
//
//  Modern macOS application implementation
//

#import "ModernSelfspyApp.h"
#import "SimpleModernActivityWidget.h"

@implementation ModernSelfspyApp

- (instancetype)init {
    self = [super init];
    if (self) {
        _widgets = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSLog(@"🚀 Modern Selfspy Widgets launching...");
    
    // Set up the app to behave like a regular app (not just background)
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    
    // Create default widgets
    NSLog(@"📱 Creating default widgets...");
    [self createDefaultWidgets];
    
    NSLog(@"✅ Modern Selfspy Widgets ready! Created %lu widgets", (unsigned long)[self.widgets count]);
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"👋 Modern Selfspy Widgets closing...");
    
    // Clean up timers
    for (id widget in self.widgets) {
        if ([widget respondsToSelector:@selector(updateTimer)]) {
            NSTimer *timer = [widget updateTimer];
            [timer invalidate];
        }
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;  // Quit when all windows are closed
}

- (void)createDefaultWidgets {
    NSScreen *screen = [NSScreen mainScreen];
    NSRect screenFrame = [screen frame];
    
    // Position windows in a nice layout
    CGFloat centerX = screenFrame.size.width / 2;
    CGFloat centerY = screenFrame.size.height / 2;
    
    NSLog(@"Screen frame: (%.0f, %.0f) %.0fx%.0f", 
          screenFrame.origin.x, screenFrame.origin.y, screenFrame.size.width, screenFrame.size.height);
    
    // Position widget in top-left corner to be more visible
    NSPoint activityPos = NSMakePoint(100, screenFrame.size.height - 250);
    [self createWidgetOfType:@"activity" atPosition:activityPos];
    
    // Terminal widget disabled for debugging
    // NSPoint terminalPos = NSMakePoint(centerX + 50, centerY + 50);
    // [self createWidgetOfType:@"terminal" atPosition:terminalPos];
}

- (void)createWidgetOfType:(NSString *)type atPosition:(NSPoint)position {
    NSLog(@"🔧 Creating widget of type '%@' at position (%.0f, %.0f)", type, position.x, position.y);
    
    id widget = nil;
    
    if ([type isEqualToString:@"activity"]) {
        NSLog(@"📊 Creating SimpleModernActivityWidget...");
        widget = [[SimpleModernActivityWidget alloc] initWithPosition:position];
    }
    
    if (widget) {
        [self.widgets addObject:widget];
        NSLog(@"🎯 Widget created, showing...");
        [widget show];
        NSLog(@"📊 Created modern %@ widget successfully", type);
    } else {
        NSLog(@"❌ Failed to create widget of type '%@'", type);
    }
}

@end