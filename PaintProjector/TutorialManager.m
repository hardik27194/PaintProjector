//
//  TutorialManager.m
//  PaintProjector
//
//  Created by 胡 文杰 on 6/15/14.
//  Copyright (c) 2014 WenjiHu. All rights reserved.
//

#import "TutorialManager.h"

@implementation TutorialManager
+ (void)initialize{
    DebugLogSystem(@"initialize");
    [super initialize];
    if (!tutorialManager) {
        tutorialManager = [[TutorialManager alloc]init];
    }
}

+ (void)destroy{
    DebugLogSystem(@"destroy");
    tutorialManager = nil;
}

+ (TutorialManager *)current{
    return tutorialManager;
}

- (void)activeTutorial:(NSString *)name{
    
    Tutorial* tutorial = (Tutorial*)[self.tutorials valueForKey:name];
    if (!tutorial) {
        DebugLogError(@"tutorial %@ not found", name);
        return;
    }
    
    self.curTutorial = tutorial;
}

- (void)deactive{
    if (!self.curTutorial) {
        return;
    }
    
    self.curTutorial = nil;
}

- (BOOL)isActive{
    
    if (!self.curTutorial) {
        return false;
    }
    return true;
}

- (id)init{
    DebugLogSystem(@"init");
    self = [super init];
    if (self) {
        _tutorials = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)dealloc{
    DebugLogSystem(@"dealloc");
    [self.tutorials removeAllObjects];
    self.tutorials = nil;
    self.curTutorial = nil;
}

- (Tutorial *)addTutorial:(NSString *)name{
    DebugLogFuncStart(@"addTutorial %@", name);
    
    Tutorial *tutorial = [[Tutorial alloc]init];
    tutorial.delegate = self;
    tutorial.name = name;
    [self.tutorials setValue:tutorial forKey:name];
    return tutorial;
}

- (Tutorial *)addTutorial:(NSString *)name ofClass:(NSString *)className{
    if (className == nil) {
        return [self addTutorial:name];
    }
    
    Class class = NSClassFromString(className);
    if (class == nil) {
        DebugLogError(@"addTutorial of class, class not exist");
        return nil;
    }
    
    Tutorial *tutorial = [[class alloc]init];
    tutorial.delegate = self;    
    tutorial.name = name;
    [self.tutorials setValue:tutorial forKey:name];
    return tutorial;
}

- (void)removeTutorial:(NSString *)name{
    DebugLogFuncStart(@"removeTutorial %@", name);
    
    [self.tutorials removeObjectForKey:name];
}
#pragma mark- 教程代理 TutorialDelegate
- (void)willTutorialEnd:(Tutorial *)tutorial{
    DebugLogFuncStart(@"willTutorialEnd %@", tutorial.name);
    tutorial = nil;
    self.curTutorial = nil;
    
    if (self.delegate) {
        [self.delegate willTutorialEnd:tutorial];
    }
}
@end