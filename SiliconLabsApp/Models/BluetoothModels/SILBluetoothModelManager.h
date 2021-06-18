//
//  SILServiceModelManager.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/19/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBluetoothServiceModel.h"
#import "SILBluetoothCharacteristicModel.h"
#import "SILBluetoothDescriptorModel.h"

@interface SILBluetoothModelManager : NSObject

+ (instancetype)sharedManager;
- (void)populateModels;
- (SILBluetoothServiceModel *)serviceModelForUUIDString:(NSString *)string;
- (SILBluetoothCharacteristicModel *)characteristicModelForUUIDString:(NSString *)string;
- (SILBluetoothCharacteristicModel *)characteristicModelForName:(NSString *)string;
- (SILBluetoothDescriptorModel *)descriptorModelForUUIDString:(NSString *)string;
- (SILBluetoothDescriptorModel *)descriptorModelForName:(NSString *)string;

@end
