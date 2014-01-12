//
//  PaintFrameGroup.m
//  iReporter
//
//  Created by 文杰 胡 on 13-2-18.
//  Copyright (c) 2013年 Marin Todorov. All rights reserved.
//

#import "PaintFrameViewGroup.h"

@implementation PaintFrameViewGroup

-(id) initWithCapacity:(int)capacity{
    self = [super init];
    if(self!=NULL){
        _paintFrameHeap = [[Heap alloc] initWithCapacity:capacity];
        _paintDocs = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)movePaintIndexByStep:(int)step{
    self.curPaintIndex = self.lastPaintIndex + step;
    if (self.curPaintIndex<0) {
        self.curPaintIndex = self.paintDocs.count + self.curPaintIndex;
    }
    else if(self.curPaintIndex > self.paintDocs.count-1){
        self.curPaintIndex = self.curPaintIndex - self.paintDocs.count;
    }
    
    self.lastPaintIndex = self.curPaintIndex;
    DebugLog(@"_curPaintFrameIndex:%d", self.curPaintIndex);    
    

}

-(void)push:(PaintFrameView*)pf{
    [self.paintFrameHeap push:pf];
}

-(void)push_reverse:(PaintFrameView*)pf{
    [self.paintFrameHeap push_reverse:pf];
}
@end