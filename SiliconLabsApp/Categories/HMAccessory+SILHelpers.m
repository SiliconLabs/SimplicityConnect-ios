//
//  HMAccessories+SILHelpers.m
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/12/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "HMAccessory+SILHelpers.h"

@implementation HMAccessory (SILHelpers)

- (HMService *)findServiceOfType:(NSString *)serviceType{
    HMService *service = nil;
    
    if (serviceType.length > 0) {
        for (HMService *aService in self.services) {
            if ([aService.serviceType caseInsensitiveCompare:serviceType] == NSOrderedSame) {
                service = aService;
                break;
            }
        }
    }
    
    return service;
}

@end
