//
//  PaintSaveDoc.h
//  PaintProjector
//
//  Created by 胡 文杰 on 13-3-27.
//  Copyright (c) 2013年 Hu Wenjie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADPaintData.h"

@interface ADPaintDoc : NSObject{
}

@property (retain, nonatomic) ADPaintData *data;

//!copy属性保证只从initWithDocPath付值
@property (copy, nonatomic) NSString *docPath;
@property (copy, nonatomic) NSString *thumbImagePath;

@property (retain, nonatomic) UIImage *thumbImage;
@property (assign, nonatomic) CGSize defaultSize;

- (id)init;
- (id)initWithDocPath:(NSString *)docPath;
- (id)cloneWithDocPath:(NSString *)docPath;
- (ADPaintData *)newData;
- (ADPaintData *)open;
- (void)close;
- (void)save;
- (void)newAndSaveThumbImage;
- (void)saveThumbImage:(UIImage*)image;
- (void)delete;
- (NSString *)getExportFileName;
- (NSData *)exportToNSData;
- (BOOL)exportToDiskWithForce:(BOOL)force;
- (BOOL)importFromPath:(NSString *)importPath;

@end