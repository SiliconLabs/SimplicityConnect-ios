//
//  SILWeakTargetWrapper.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/6/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SILWeakTargetWrapper : NSObject

- (instancetype)initWithTarget:(id)target selector:(SEL)sel;

- (void)triggerSelector:(id)object;

@end
