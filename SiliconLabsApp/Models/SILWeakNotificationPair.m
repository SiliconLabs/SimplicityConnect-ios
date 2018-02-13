//
//  SILWeakNotificationPair.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 5/18/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILWeakNotificationPair.h"

@implementation SILWeakNotificationPair

+ (instancetype)pairWithObject:(id)object selector:(SEL)selector {
    SILWeakNotificationPair *pair = [[self alloc] init];
    pair.object = object;
    pair.selector = selector;
    return pair;
}

@end
