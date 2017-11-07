//
//  HMService+SILHelpers.m
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/12/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "HMService+SILHelpers.h"

@implementation HMService (SILHelpers)

- (HMCharacteristic *)findCharacteristicOfType:(NSString *)characteristicType{
    HMCharacteristic *characteristic = nil;
    
    if (characteristicType.length > 0) {
        for (HMCharacteristic *aCharacteristic in self.characteristics) {
            if ([aCharacteristic.characteristicType caseInsensitiveCompare:characteristicType] == NSOrderedSame) {
                characteristic = aCharacteristic;
                break;
            }
        }
    }
    
    return characteristic;
}

@end
