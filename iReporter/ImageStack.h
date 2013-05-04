//
//  UndoStack.h
//  iReporter
//
//  Created by 文杰 胡 on 12-11-7.
//  Copyright (c) 2012年 Marin Todorov. All rights reserved.
//

#import "Heap.h"
#import "Ultility.h"
@interface ImageStack : Heap
{
    
}
- (void)push:(CGImageRef)image;
- (CGImageRef)pop;
- (CGImageRef)lastUndoImage;
@end