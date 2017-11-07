//
//  CBPeripheral+Services.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/8/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheral (Services)

- (CBService *)serviceForUUID:(CBUUID *)uuid;
- (BOOL)hasOTAService;
- (CBService *)otaService;
- (BOOL)hasOTADataCharacteristic;
- (CBCharacteristic *)otaDataCharacteristic;
- (BOOL)hasOTAControlCharacteristic;
- (CBCharacteristic *)otaControlCharacteristic;

@end
