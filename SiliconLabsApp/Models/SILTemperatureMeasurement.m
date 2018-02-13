//
//  SILTemperatureMeasurement.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/16/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILTemperatureMeasurement.h"

@implementation SILTemperatureMeasurement

+ (int32_t)convertInt24ToInt32:(int32_t)value {
    value = value & 0x00FFFFFF;

    // value is negative in int24
    if (value & 0x00800000) {
        value ^= 0x00FFFFFF;
        value += 1;
        value *= -1;
    }

    return value;
}

+ (SILTemperatureMeasurement *)decodeTemperatureMeasurementWithData:(NSData *)data {
    SILTemperatureMeasurement *temperatureMeasurement = [[SILTemperatureMeasurement alloc] init];
    uint8_t *dataPointer = (uint8_t *)data.bytes;

    uint8_t flags = dataPointer[0];
    dataPointer++;

    temperatureMeasurement.isFahrenheit = flags & 0x01;

    int32_t tempData = (int32_t)CFSwapInt32LittleToHost(*(uint32_t*)dataPointer);
    dataPointer += 4;
    int8_t exponent = (int8_t)(tempData >> 24);
    int32_t mantissa = [self convertInt24ToInt32:(tempData & 0x00FFFFFF)];
    temperatureMeasurement.value = (float)(mantissa*pow(10, exponent));

    if (flags & 0x02) {
        uint16_t year = CFSwapInt16LittleToHost(*(uint16_t*)dataPointer); dataPointer += 2;
        uint8_t month = *(uint8_t*)dataPointer; dataPointer++;
        uint8_t day = *(uint8_t*)dataPointer; dataPointer++;
        uint8_t hour = *(uint8_t*)dataPointer; dataPointer++;
        uint8_t min = *(uint8_t*)dataPointer; dataPointer++;
        uint8_t sec = *(uint8_t*)dataPointer; dataPointer++;

        NSString *dateString = [NSString stringWithFormat:@"%d %d %d %d %d %d", year, month, day, hour, min, sec];

        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat: @"yyyy MM dd HH mm ss"];
        temperatureMeasurement.measurementDate = [dateFormat dateFromString:dateString];
    } else {
        temperatureMeasurement.measurementDate = [NSDate date];
    }

    if (flags & 0x04) {
        uint8_t type = *(uint8_t*)dataPointer; dataPointer++;

        switch (type) {
            case 0x01:
                temperatureMeasurement.temperatureType = SILTemperatureTypeArmpit;
                break;
            case 0x02:
                temperatureMeasurement.temperatureType = SILTemperatureTypeBody;
                break;
            case 0x03:
                temperatureMeasurement.temperatureType = SILTemperatureTypeEar;
                break;
            case 0x04:
                temperatureMeasurement.temperatureType = SILTemperatureTypeFinger;
                break;
            case 0x05:
                temperatureMeasurement.temperatureType = SILTemperatureTypeGastroIntestinalTract;
                break;
            case 0x06:
                temperatureMeasurement.temperatureType = SILTemperatureTypeMouth;
                break;
            case 0x07:
                temperatureMeasurement.temperatureType = SILTemperatureTypeRectum;
                break;
            case 0x08:
                temperatureMeasurement.temperatureType = SILTemperatureTypeToe;
                break;
            case 0x09:
                temperatureMeasurement.temperatureType = SILTemperatureTypeTypanum;
                break;
            default:
                temperatureMeasurement.temperatureType = SILTemperatureTypeUnknown;
                break;
        }
    } else {
        temperatureMeasurement.temperatureType = SILTemperatureTypeUnknown;
    }
    
    return temperatureMeasurement;
}

- (float)valueInCelsius {
    if (self.isFahrenheit) {
        return (self.value - 32.0f) * 5.0f / 9.0f;
    } else {
        return self.value;
    }
}

- (float)valueInFahrenheit {
    if (self.isFahrenheit) {
        return self.value;
    } else {
        return self.value * 9.0f / 5.0f + 32.0f;
    }
}

@end
