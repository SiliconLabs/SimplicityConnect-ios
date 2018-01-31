//
//  CBPeripheral+Services.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/8/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "CBPeripheral+Services.h"
#import "SILUUIDProvider.h"
#import "CBService+Categories.h"

@implementation CBPeripheral (Services)

- (CBService *)serviceForUUID:(CBUUID *)uuid {
    CBService *theService;
    for (CBService *service in self.services) {
        if ([service.UUID isEqual:uuid]) {
            theService = service;
            break;
        }
    }
    return theService;
}

- (BOOL)hasOTAService {
    return [self otaService] != nil;
}

- (CBService *)otaService {
    return [self serviceForUUID:[SILUUIDProvider sharedProvider].otaServiceUUID];
}

- (BOOL)hasOTADataCharacteristic {
    return [[self otaService] hasOTADataCharacteristic];
}

- (CBCharacteristic *)otaDataCharacteristic {
    return [[self otaService] otaDataCharacteristic];
}

- (BOOL)hasOTAControlCharacteristic {
    return [[self otaService] hasOTAControlCharacteristic];
}

- (CBCharacteristic *)otaControlCharacteristic {
    return [[self otaService] otaControlCharacteristic];
}

@end
