//
//  SILSavedSearchesRealmModel.m
//  BlueGecko
//
//  Created by Kamil Czajka on 19/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILSavedSearchesRealmModel.h"
#import "SILBrowserBeaconType.h"

@interface SILSavedSearchesRealmModel ()

@end

@implementation SILSavedSearchesRealmModel

- (instancetype)initWithSearchByDeviceNameText:(NSString*)searchByDeviceNameText dBmValue:(NSInteger)dBmValue beaconTypes:(RLMArray<SILBeaconTypeRealmModel*>*)beaconTypes isFavourite:(BOOL)isFavourite andIsConnectable:(BOOL)isConnectable {
    self = [super self];
    
    if (self) {
        self.searchByDeviceName = searchByDeviceNameText;
        self.dBmValue = dBmValue;
        self.beaconTypes = beaconTypes;
        self.isFavouriteSetFilter = isFavourite;
        self.isConnectableSetFilter = isConnectable;
    }
    
    return self;
}

@end
