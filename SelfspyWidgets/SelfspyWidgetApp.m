//
//  SelfspyWidgetApp.m
//  SelfspyWidgets
//
//  Main application delegate implementation
//

#import "SelfspyWidgetApp.h"
#import "SelfspyWidget.h"
#import "ActivitySummaryWidget.h"
#import "TerminalWidget.h"
#import "TopAppsWidget.h"

@implementation SelfspyWidgetApp

- (instancetype)init {
    self = [super init];
    if (self) {
        _widgets = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSLog(@"🚀 Selfspy Widgets launching...");
    
    // Create default widgets
    [self createDefaultWidgets];
    
    // Start update timer (every 10 seconds)
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                        target:self
                                                      selector:@selector(updateAllWidgets)
                                                      userInfo:nil
                                                       repeats:YES];
    
    NSLog(@"✅ Selfspy Widgets ready!");
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSLog(@"👋 Selfspy Widgets closing...");
    [self.updateTimer invalidate];
}

- (void)createDefaultWidgets {
    NSScreen *screen = [NSScreen mainScreen];
    NSRect screenFrame = [screen frame];
    
    // Position windows in a cascade pattern from top-left area
    // Note: macOS coordinate system has (0,0) at bottom-left
    CGFloat startX = 100;
    CGFloat startY = 300;  // Much lower Y value (closer to bottom of screen coordinate system)
    CGFloat offsetX = 50;  // Cascade offset
    CGFloat offsetY = 50;   // Positive offset moves up in screen coordinates
    
    NSLog(@"Screen frame: (%.0f, %.0f) %.0fx%.0f", 
          screenFrame.origin.x, screenFrame.origin.y, screenFrame.size.width, screenFrame.size.height);
    
    // Activity summary widget
    NSPoint activityPos = NSMakePoint(startX, startY);
    [self createWidgetOfType:@"activity" atPosition:activityPos];
    
    // Terminal widget (cascade down and right)
    NSPoint terminalPos = NSMakePoint(startX + offsetX, startY + offsetY);
    [self createWidgetOfType:@"terminal" atPosition:terminalPos];
    
    // Top apps widget (cascade further)
    NSPoint appsPos = NSMakePoint(startX + (offsetX * 2), startY + (offsetY * 2));
    [self createWidgetOfType:@"apps" atPosition:appsPos];
}

- (void)createWidgetOfType:(NSString *)type atPosition:(NSPoint)position {
    SelfspyWidget *widget = nil;
    
    if ([type isEqualToString:@"activity"]) {
        widget = [[ActivitySummaryWidget alloc] initWithPosition:position];
    } else if ([type isEqualToString:@"terminal"]) {
        widget = [[TerminalWidget alloc] initWithPosition:position];
    } else if ([type isEqualToString:@"apps"]) {
        widget = [[TopAppsWidget alloc] initWithPosition:position];
    }
    
    if (widget) {
        [self.widgets addObject:widget];
        [widget show];
        NSLog(@"📊 Created %@ widget", type);
    }
}

- (void)updateAllWidgets {
    NSLog(@"🔄 Updating %lu widgets...", (unsigned long)[self.widgets count]);
    
    for (SelfspyWidget *widget in self.widgets) {
        [widget updateData];
    }
}

@end