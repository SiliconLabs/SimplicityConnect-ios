//
//  SILWeakTargetWrapper.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/6/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILWeakTargetWrapper.h"

@interface SILWeakTargetWrapper ()

@property (weak, nonatomic) id target;
@property (assign, nonatomic) SEL selector;

@end

@implementation SILWeakTargetWrapper

- (instancetype)initWithTarget:(id)target selector:(SEL)sel {
    self = [super init];
    if (self) {
        self.target = target;
        self.selector = sel;
    }
    return self;
}

- (void)triggerSelector:(id)object {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.selector withObject:object];
#pragma clang diagnostic pop
}

@end
