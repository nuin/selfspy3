//
//  ModernTerminalWidget.h
//  SelfspyWidgets
//
//  Modern terminal activity widget
//

#import "ModernSelfspyWidget.h"

@interface ModernTerminalWidget : ModernSelfspyWidget

@property (strong, nonatomic) NSScrollView *commandScrollView;
@property (strong, nonatomic) NSStackView *commandStack;

@end