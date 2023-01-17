//
//  SILConnectedPeripheralDataModel.m
//  BlueGecko
//
//  Created by Kamil Czajka on 24/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILConnectedPeripheralDataModel.h"

@interface SILConnectedPeripheralDataModel ()

@end

@implementation SILConnectedPeripheralDataModel

- (instancetype)initWithPeripheral:(SILDiscoveredPeripheral*)peripheral andIsSelected:(BOOL)isSelected {
    self = [super init];
    if (self) {
        self.discoveredPeripheral = peripheral;
        self.isSelected = isSelected;
    }
    return self;
}

@end



