//
//  CBService+Categories.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/8/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "CBService+Categories.h"
#import "SILUUIDProvider.h"

@implementation CBService (Categories)

- (CBCharacteristic *)characteristicForUUID:(CBUUID *)uuid {
    CBCharacteristic *theCharacteristic;
    for (CBCharacteristic *characteristic in self.characteristics) {
        if ([characteristic.UUID isEqual:uuid]) {
            theCharacteristic = characteristic;
            break;
        }
    }
    return theCharacteristic;
}

- (BOOL)hasOTADataCharacteristic {
    return [self otaDataCharacteristic] != nil;
}

- (CBCharacteristic *)otaDataCharacteristic {
    return [self characteristicForUUID:[SILUUIDProvider sharedProvider].otaCharacteristicOTADataAttributeUUID];
}

- (BOOL)hasOTAControlCharacteristic {
    return [self otaControlCharacteristic]!= nil;
}

- (CBCharacteristic *)otaControlCharacteristic {
    return [self characteristicForUUID:[SILUUIDProvider sharedProvider].otaCharacteristicOTAControlAttributeUUID];
}

@end
