//
//  SILTemperatureType.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/16/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILTemperatureType.h"


NSString * SILTemperatureTypeDisplayName(SILTemperatureType temperatureType) {
    switch (temperatureType) {
        case SILTemperatureTypeUnknown:
            return @"Unknown";
        case SILTemperatureTypeArmpit:
            return @"Armpit";
        case SILTemperatureTypeBody:
            return @"Body";
        case SILTemperatureTypeEar:
            return @"Ear";
        case SILTemperatureTypeFinger:
            return @"Finger";
        case SILTemperatureTypeGastroIntestinalTract:
            return @"Gastro-intestinal Tract";
        case SILTemperatureTypeMouth:
            return @"Mouth";
        case SILTemperatureTypeRectum:
            return @"Rectum";
        case SILTemperatureTypeToe:
            return @"Toe";
        case SILTemperatureTypeTypanum:
            return @"Tympanum";
        default:
            return @"Invalid";
    }
}