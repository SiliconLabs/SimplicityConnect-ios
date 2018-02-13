//
//  SILTemperatureMeasurement.h
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/16/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILTemperatureType.h"

@interface SILTemperatureMeasurement : NSObject

@property (nonatomic) SILTemperatureType temperatureType;
@property (nonatomic) BOOL isFahrenheit;
@property (nonatomic) float value;
@property (strong, nonatomic) NSDate *measurementDate;

+ (SILTemperatureMeasurement *)decodeTemperatureMeasurementWithData:(NSData *)data;

- (float)valueInCelsius;
- (float)valueInFahrenheit;

@end
