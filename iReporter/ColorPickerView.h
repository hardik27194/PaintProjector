//
//  ColorPickerView.h
//  iReporter
//
//  Created by 文杰 胡 on 13-1-12.
//  Copyright (c) 2013年 Marin Todorov. All rights reserved.
//

//名称:
//描述:
//功能:

#import <UIKit/UIKit.h>

@interface ColorPickerView : UIView
@property(nonatomic, assign)bool locked;
@property(nonatomic, retain)UIView* sourceView;
@end