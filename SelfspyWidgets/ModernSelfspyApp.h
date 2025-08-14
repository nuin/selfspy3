//
//  ModernSelfspyApp.h
//  SelfspyWidgets
//
//  Modern macOS application delegate
//

#import <Cocoa/Cocoa.h>

@interface ModernSelfspyApp : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSMutableArray *widgets;
@property (strong, nonatomic) NSTimer *updateTimer;

- (void)createDefaultWidgets;
- (void)createWidgetOfType:(NSString *)type atPosition:(NSPoint)position;

@end