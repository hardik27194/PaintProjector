//
//  LayerBlendModePopoverController.m
//  ProjectPaint
//
//  Created by 胡 文杰 on 13-5-22.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

#import "ADLayerBlendModePopoverController.h"
#import "ADLayerBlendModePopoverBackgroundView.h"

@implementation ADLayerBlendModePopoverController
-(id)initWithContentViewController:(UIViewController *)viewController{
    self = [super initWithContentViewController:viewController];
    if (self) {
        // Initialization code
        self.popoverBackgroundViewClass = [ADLayerBlendModePopoverBackgroundView class];
    }
    return self;
}
@end