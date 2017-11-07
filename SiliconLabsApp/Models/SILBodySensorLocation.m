//
//  SILBodySensorLocation.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/15/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILBodySensorLocation.h"

@implementation SILBodySensorLocation

+ (NSString *)displayNameForBodySensorLocationType:(SILBodySensorLocationType)bodySensorLocationType {
    switch (bodySensorLocationType) {
        case SILBodySensorLocationTypeOther:
            return @"Other";
        case SILBodySensorLocationTypeChest:
            return @"Chest";
        case SILBodySensorLocationTypeWrist:
            return @"Wrist";
        case SILBodySensorLocationTypeFinger:
            return @"Finger";
        case SILBodySensorLocationTypeHand:
            return @"Hand";
        case SILBodySensorLocationTypeEarLobe:
            return @"Ear Lobe";
        case SILBodySensorLocationTypeFoot:
            return @"Foot";
        case SILBodySensorLocationTypeInvalid:
            return @"Invalid";
    }
}

@end
