//
//  SILTemperatureType.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/16/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SILTemperatureType) {
    SILTemperatureTypeInvalid = -1,
    SILTemperatureTypeUnknown = 0,
    SILTemperatureTypeArmpit,
    SILTemperatureTypeBody,
    SILTemperatureTypeEar,
    SILTemperatureTypeFinger,
    SILTemperatureTypeGastroIntestinalTract,
    SILTemperatureTypeMouth,
    SILTemperatureTypeRectum,
    SILTemperatureTypeToe,
    SILTemperatureTypeTypanum,
};

extern NSString * SILTemperatureTypeDisplayName(SILTemperatureType temperatureType);