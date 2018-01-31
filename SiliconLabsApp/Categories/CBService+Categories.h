//
//  CBService+Categories.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/8/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBService (Categories)

- (CBCharacteristic *)characteristicForUUID:(CBUUID *)uuid;
- (BOOL)hasOTADataCharacteristic;
- (CBCharacteristic *)otaDataCharacteristic;
- (BOOL)hasOTAControlCharacteristic;
- (CBCharacteristic *)otaControlCharacteristic;

@end
