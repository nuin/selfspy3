//
//  ModernActivityWidget.h
//  SelfspyWidgets
//
//  Modern activity summary widget
//

#import "ModernSelfspyWidget.h"

@interface ModernActivityWidget : ModernSelfspyWidget

@property (strong, nonatomic) NSStackView *statsStack;
@property (strong, nonatomic) NSMutableArray *statViews;

@end