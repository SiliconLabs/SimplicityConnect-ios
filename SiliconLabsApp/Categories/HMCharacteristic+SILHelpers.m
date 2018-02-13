//
//  HMCharacteristic+SILHelpers.m
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/12/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "HMCharacteristic+SILHelpers.h"

@implementation HMCharacteristic (SILHelpers)

- (BOOL)isWritable {
    return [self hasProperty:HMCharacteristicPropertyWritable];
}

- (BOOL)isReadable {
    return [self hasProperty:HMCharacteristicPropertyReadable];
}

- (BOOL)hasProperty:(NSString *)propertyName {
    BOOL flag = NO;
    
    for (NSString* property in self.properties) {
        if ([property isEqualToString:propertyName]) {
            flag = YES;
            break;
        }
    }
    
    return flag;
}

@end
