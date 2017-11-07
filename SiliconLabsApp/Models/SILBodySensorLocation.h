//
//  SILBodySensorLocation.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/15/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SILBodySensorLocationType) {
    SILBodySensorLocationTypeInvalid = -1,
    SILBodySensorLocationTypeOther = 0,
    SILBodySensorLocationTypeChest,
    SILBodySensorLocationTypeWrist,
    SILBodySensorLocationTypeFinger,
    SILBodySensorLocationTypeHand,
    SILBodySensorLocationTypeEarLobe,
    SILBodySensorLocationTypeFoot,
};

@interface SILBodySensorLocation : NSObject

+ (NSString *)displayNameForBodySensorLocationType:(SILBodySensorLocationType)bodySensorLocationType;

@end
