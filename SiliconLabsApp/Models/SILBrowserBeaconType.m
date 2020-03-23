//
//  SILBrowserBeaconType.m
//  BlueGecko
//
//  Created by Kamil Czajka on 18/02/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILBrowserBeaconType.h"

@interface SILBrowserBeaconType ()

@property (strong, nonatomic, readwrite) NSString *beaconName;

@end

@implementation SILBrowserBeaconType : NSObject

- (instancetype)initWithName:(NSString*)beaconName andSelection:(BOOL)isSelected {
    self = [super init];
    if (self) {
        self.beaconName = beaconName;
        self.isSelected = isSelected;
    }
    return self;
}

- (void)modifySelection {
    self.isSelected = !self.isSelected;
}

@end
