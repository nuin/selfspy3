//
//  SelfspyWidgetApp.h
//  SelfspyWidgets
//
//  Main application delegate for Selfspy desktop widgets
//

#import <Cocoa/Cocoa.h>

@class SelfspyWidget;

@interface SelfspyWidgetApp : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSMutableArray<SelfspyWidget *> *widgets;
@property (strong, nonatomic) NSTimer *updateTimer;

- (void)createDefaultWidgets;
- (void)createWidgetOfType:(NSString *)type atPosition:(NSPoint)position;
- (void)updateAllWidgets;

@end