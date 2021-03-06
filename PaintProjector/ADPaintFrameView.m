//
//  PaintFrameButton.m
//  ProjectPaint
//
//  Created by 胡 文杰 on 13-6-2.
//  Copyright (c) 2013年 WenjiHu. All rights reserved.
//

#import "ADPaintFrameView.h"
#import "ADUltility.h"
#import "RETextureManager.h"
@implementation ADPaintFrameView

- (id)initWithCoder:(NSCoder *)aDecoder{
//    DebugLog(@"[initWithCoder]");
    self = [super initWithCoder:aDecoder];
    if (self) {
//        [self initApperance];
     
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
//    DebugLog(@"[initWithFrame]");
    self = [super initWithFrame:frame];
    if (self) {
//        [self initApperance];
    }
    return self;
}

-(void)initApperance{
    self.clipsToBounds = NO;
    self.backgroundColor = [UIColor clearColor];

    //设置边框阴影
    //clipsToBounds will clip layer.shadow, should set shadow via drawLayer method
    CGPathRef path = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
    [self.layer setShadowPath:path];
    self.layer.shadowOpacity = 0.5;
    self.layer.shadowRadius = 5;
    self.layer.shadowOffset = CGSizeMake(0, 5);
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.cornerRadius = 5;
}

- (id)initWithFrame:(CGRect)frame paintDoc:(ADPaintDoc*)paintDoc{
    self = [super initWithFrame:frame];
    if (self !=nil) {
        _paintDoc = paintDoc;
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect
//{
//    // Drawing code
//    //// General Declarations
//    CGContextRef context = UIGraphicsGetCurrentContext();
//
//    //// Shadow Declarations
//    UIColor* shadow = [UIColor blackColor];
//    CGSize shadowOffset = CGSizeMake(2.1, -2.1);
//    CGFloat shadowBlurRadius = 5;
//    
//    //// Group
//    {
//        CGContextSaveGState(context);
//        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
//        
//        CGContextBeginTransparencyLayer(context, NULL);
//        
//        
//        //// Rectangle Drawing
//        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, 240, 320) cornerRadius: 10];
//        [[UIColor whiteColor] setFill];
//        [rectanglePath fill];
//        [[UIColor blackColor] setStroke];
//        rectanglePath.lineWidth = 1;
//        [rectanglePath stroke];
//        
//        
//        CGContextEndTransparencyLayer(context);
//        CGContextRestoreGState(context);
//    }
//    
//    
//    
//}

-(void)setPaintDoc:(ADPaintDoc *)paintDoc{
    _paintDoc = paintDoc;

    if (paintDoc) {
        NSUInteger length = [paintDoc.docPath length];
        NSString *accLabel = [paintDoc.docPath substringToIndex:(length - 4)];
        self.isAccessibilityElement = true;
        self.accessibilityLabel = accLabel;
    }

}

-(void)loadForDisplay{
    if (self.paintDoc != NULL)
    {
        NSString *thumbImagePath = [[ADUltility applicationDocumentDirectory] stringByAppendingPathComponent:self.paintDoc.thumbImagePath];
        
        //不cache
        [self setImage:[[UIImage alloc]initWithContentsOfFile:thumbImagePath] forState:UIControlStateNormal];
        DebugLog(@"DocThumbImage: %@", self.paintDoc.thumbImagePath);
    }
}

-(void)unloadForDisplay{
    [self setImage:nil forState:UIControlStateNormal];
    self.imageView.image = nil;
}
@end
