//
//  SILServiceAttributeTableModel.h
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILGenericAttributeTableModel.h"

@class CBService, SILBluetoothServiceModel;

@interface SILServiceTableModel : NSObject <SILGenericAttributeTableModel>

@property (strong, nonatomic) CBService *service;
@property (strong, nonatomic) SILBluetoothServiceModel *bluetoothModel;
@property (strong, nonatomic) NSArray *characteristicModels; //of SILCharacteristicTableModels

- (instancetype)initWithService:(CBService *)service;
- (NSString *)name;

@end
