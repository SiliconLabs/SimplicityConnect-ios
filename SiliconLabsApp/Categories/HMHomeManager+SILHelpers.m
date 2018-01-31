//
//  HMHomeManager+SILHelpers.m
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/12/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "HMHomeManager+SILHelpers.h"
#import "HMAccessory+SILHelpers.h"

@implementation HMHomeManager (SILHelpers)

- (HMAccessory *)findAccessoryWithServiceOfType:(NSString *)serviceType {
    HMAccessory *accessory = nil;
    
    if (serviceType.length > 0) {
        for (HMHome *home in self.homes) {
            for (HMAccessory *anAccessory in home.accessories) {
                if ([anAccessory findServiceOfType:serviceType]) {
                    accessory = anAccessory;
                    break;
                }
            }
        }
    }
    
    return accessory;
}

@end
