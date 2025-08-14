//
//  modern_main.m
//  SelfspyWidgets
//
//  Modern Selfspy Widgets - Native macOS Application
//

#import <Cocoa/Cocoa.h>
#import "ModernSelfspyApp.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        
        ModernSelfspyApp *appDelegate = [[ModernSelfspyApp alloc] init];
        [app setDelegate:appDelegate];
        
        // Run the application
        [app run];
    }
    return 0;
}