//
//  PaintCommandStack.h
//  iReporter
//
//  Created by 文杰 胡 on 12-12-25.
//  Copyright (c) 2012年 Marin Todorov. All rights reserved.
//

#import "Heap.h"
#import "Command.h"
@interface CommandStack : Heap
- (void)push:(Command*)image;
- (Command*)pop;
- (Command*)firstCommand;
- (Command*)lastCommand;
- (NSMutableArray *)allCommands;
@end