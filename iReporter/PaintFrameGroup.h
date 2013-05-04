//
//  PaintFrameGroup.h
//  iReporter
//
//  Created by 文杰 胡 on 13-2-18.
//  Copyright (c) 2013年 Marin Todorov. All rights reserved.
//

//名称: 画框组
//描述: 用于显示一组画集
//功能:

#import <Foundation/Foundation.h>
#import "Heap.h"
#import "PaintFrame.h"

@interface PaintFrameGroup : NSObject
{
    NSString* _name;            //画框组名
    Heap* _paintFrameHeap;      //画框组列队
    int _lastPaintIndex;        //上一个画框号
    int _curPaintIndex;         //当前画框号
    PaintFrame* _curPaintFrame; //当前画框
    
    NSString* _dirPath;         //记录磁盘上对应的目录名
    NSMutableArray* _paintDocs; //记录该目录下所有的文件数据
}
@property(nonatomic, copy) NSString* dirPath;
@property(nonatomic, copy) NSString* name;
@property(nonatomic, retain) NSMutableArray* paintDocs;
@property(nonatomic, retain) Heap* paintFrameHeap;
@property(nonatomic, retain) PaintFrame* curPaintFrame;
@property(nonatomic, assign) int lastPaintIndex;
@property(nonatomic, assign) int curPaintIndex;
- (id) initWithCapacity:(int)capacity;
- (void)moveToPaintIndex:(float)movedCount;
-(void)push:(PaintFrame*)pf;
-(void)push_reverse:(PaintFrame*)pf;
@end