//
//  EyeDropper.h
//  iReporter
//
//  Created by 文杰 胡 on 12-11-4.
//  Copyright (c) 2012年 Marin Todorov. All rights reserved.
//

//名称:
//描述:
//功能:

#import <Foundation/Foundation.h>

@interface EyeDropper : NSObject
{
}
@property (nonatomic, retain) UIView *targetView;
@property (nonatomic, assign) CGColorRef resultColor;
@property (nonatomic, assign) BOOL isDrawing;
@property (nonatomic, assign) CGPoint position;//touch position
- (void) draw;
- (id) initWithView:(UIView*)view;
- (UIColor *) colorOfPoint:(CGPoint)point;
@end