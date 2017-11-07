//
//  SILWeakNotificationPair.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 5/18/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILWeakNotificationPair : NSObject

@property (weak, nonatomic) id object;
@property (assign, nonatomic) SEL selector;

+ (instancetype)pairWithObject:(id)object
                      selector:(SEL)selector;

@end
