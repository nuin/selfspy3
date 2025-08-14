//
//  main.m
//  SelfspyWidgets
//
//  Native macOS desktop widgets for Selfspy activity monitoring
//

#import <Cocoa/Cocoa.h>
#import "SelfspyWidgetApp.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory]; // Hide from dock
        
        SelfspyWidgetApp *appDelegate = [[SelfspyWidgetApp alloc] init];
        [app setDelegate:appDelegate];
        
        [app run];
    }
    return 0;
}