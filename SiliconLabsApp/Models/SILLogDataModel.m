//
//  SILLogDataModel.m
//  BlueGecko
//
//  Created by Kamil Czajka on 21/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILLogDataModel.h"
#import "SILCharacteristicFieldValueResolver.h"

@interface SILLogDataModel ()

@end

@implementation SILLogDataModel

- (instancetype)initWithDesctiption:(NSString*)description {
    self = [super init];
    if (self) {
        self.timestamp = [self getCurrentTime];
        self.logDescription = description;
    }
    return self;
}

- (NSString*)getCurrentTime {
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss.SSS"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}

+ (NSString*)prepareLogDescription:(NSString*)title andPeripheral:(CBPeripheral*)peripheral andError:(NSError*)error {
    NSMutableString* description = [NSMutableString stringWithString:title];
    if (peripheral.name != nil) {
        [description appendString:peripheral.name];
    } else {
        [description appendString:@"Unknown pepipheral"];
    }
    [description appendString:@" ("];
    [description appendString:peripheral.identifier.UUIDString];
    [description appendString:@")"];
    if (error != nil) {
        [description appendString:[NSString stringWithFormat:@"\nerror code: %ld", (long)error.code]];
    }
    return description;
}

+ (NSString*)prepareLogDescription:(NSString *)title andCharacteristic:(CBCharacteristic*)characteristic andPeripheral:(CBPeripheral *)peripheral andError:(NSError *)error {
    NSMutableString* description = [NSMutableString stringWithString:title];
    if (peripheral.name != nil) {
        [description appendString:peripheral.name];
    } else {
        [description appendString:@"Unknown pepipheral"];
    }
    [description appendString:@" ("];
    [description appendString:peripheral.identifier.UUIDString];
    [description appendString:@")"];
    
    if (characteristic != nil) {
        [description appendString:[NSString stringWithFormat:@"\ncharacterictic with UUID: %@", characteristic.UUID.UUIDString]];
    }
    
    if (error != nil) {
        [description appendString:[NSString stringWithFormat:@"\nerror code: %ld", (long)error.code]];
    }
    return description;
}

+ (NSString*)prepareLogDescriptionForUpdateValueOfCharacteristic:(CBCharacteristic*)characteristic andPeripheral:(CBPeripheral *)peripheral andError:(NSError *)error {
    NSMutableString* description = [NSMutableString stringWithString:[self prepareLogDescription:@"didUpdateValueForCharacteristic: " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
    [description appendString:[self prepareStringOfValue:[characteristic value]]];
    return description;
}

+ (NSString*)prepareLogDescriptionForWriteValueOfCharacteristic:(CBCharacteristic*)characteristic andPeripheral:(CBPeripheral *)peripheral andError:(NSError *)error andData:(NSData*)data {
    NSMutableString* description = [[NSMutableString alloc] init];
    [description appendString:[self prepareLogDescription:@"writeToPeripheral: "  andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
    [description appendString:[self prepareStringOfValue: data]];
    return description;
}

+ (NSString*)prepareStringOfValue:(NSData*)data {
    if (data == nil || data.length == 0) {
        return @"\nEmpty data";
    }
    NSString* hexString = [[SILCharacteristicFieldValueResolver sharedResolver] hexStringForData:data decimalExponent:0];
    NSString* asciiString = [[[SILCharacteristicFieldValueResolver sharedResolver] asciiStringForData:data] stringByReplacingOccurrencesOfString:@"\0" withString:@""];
    NSString* decimalString = [[SILCharacteristicFieldValueResolver sharedResolver] decimalStringForData:data];
    NSString* res = [NSString stringWithFormat:@" data: 0x%@ (hex), %@ (ascii), %@ (dec).", hexString, asciiString, decimalString];
    return res;
}

+ (NSString*)prepareLogDescription:(NSString *)title andDescriptor:(CBDescriptor*)descriptor andPeripheral:(CBPeripheral *)peripheral andError:(NSError *)error {
    NSMutableString* description = [NSMutableString stringWithString:title];
    if (peripheral.name != nil) {
        [description appendString:peripheral.name];
    } else {
        [description appendString:@"Unknown pepipheral"];
    }
    [description appendString:@" ("];
    [description appendString:peripheral.identifier.UUIDString];
    [description appendString:@")"];
    
    if (descriptor != nil) {
        [description appendString:[NSString stringWithFormat:@"\ndescriptor with UUID: %@", descriptor.UUID.UUIDString]];
    }
    
    if (error != nil) {
        [description appendString:[NSString stringWithFormat:@"\nerror code: %ld", (long)error.code]];
    }
    return description;
}


@end
