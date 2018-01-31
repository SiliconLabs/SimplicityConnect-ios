//
//  SILBeaconDataModel.h
//  SiliconLabsApp
//
//  Created by Max Litteral on 6/22/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BeaconModelType) {
    BeaconModelTypeURL,
    BeaconModelTypeUUID,
    BeaconModelTypeInstance,
    BeaconModelTypeVersion,
    BeaconModelTypeVoltage,
    BeaconModelTypeTemperature,
    BeaconModelTypeAdvertisementCount,
    BeaconModelTypeOnTime
};

@interface SILBeaconDataModel : NSObject

@property (strong, nonatomic) NSString *value;
@property (nonatomic) BeaconModelType type;

- (instancetype)initWithValue:(NSString *)value type:(BeaconModelType)type;

@end
