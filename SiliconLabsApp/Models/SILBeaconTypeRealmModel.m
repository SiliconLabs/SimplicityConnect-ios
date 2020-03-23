//
//  SILBeaconTypeRealmModel.m
//  BlueGecko
//
//  Created by Kamil Czajka on 19/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBeaconTypeRealmModel.h"

@interface SILBeaconTypeRealmModel ()

@end

@implementation SILBeaconTypeRealmModel

- (instancetype)initWithName:(NSString*)beaconName andIsSelected:(BOOL)isSelected {
    self = [super init];
    
    if (self) {
        self.beaconName = beaconName;
        self.isSelected = isSelected;
    }

    return self;
}

@end
