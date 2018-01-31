//
//  SILHomeKitServiceTableModel.m
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#if ENABLE_HOMEKIT
#import <HomeKit/HomeKit.h>
#endif
#import "SILHomeKitServiceTableModel.h"
#import "SILHomeKitCharacteristicTableModel.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SILBluetoothModelManager.h"

@implementation SILHomeKitServiceTableModel

@synthesize isExpanded;
@synthesize hideTopSeparator;

- (instancetype)initWithService:(HMService *)service {
    self = [super init];
    if (self) {
        _service = service;
        _characteristicModels = [self characteristicModelsForService:service];
    }
    return self;
}

- (NSArray *)characteristicModelsForService:(HMService *)service {
    NSMutableArray *characteristicModels = [NSMutableArray array];
    for (HMCharacteristic *characteristic in service.characteristics) {
        SILHomeKitCharacteristicTableModel *characteristicModel = [[SILHomeKitCharacteristicTableModel alloc]initWithCharacteristic:characteristic];
        [characteristicModels addObject:characteristicModel];
    }
    return characteristicModels;
}

- (NSString *)name {
    return self.service.name;
}


#pragma mark - SILGenericAttributeTableModel

- (BOOL)canExpand {
    return self.characteristicModels.count > 0;
}

- (void)toggleExpansionIfAllowed {
    self.isExpanded = !self.isExpanded;
}

- (NSString *)uuidString {
    return self.service.uniqueIdentifier.UUIDString;
}

@end
