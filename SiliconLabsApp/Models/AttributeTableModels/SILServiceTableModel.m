//
//  SILServiceTableModel.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/6/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SILServiceTableModel.h"
#import "SILBluetoothModelManager.h"
#import "SILUUIDProvider.h"
#import "BlueGecko.pch"

@implementation SILServiceTableModel

@synthesize isExpanded;
@synthesize hideTopSeparator;
@synthesize isMappable;

- (instancetype)initWithService:(CBService *)service {
    self = [super init];
    if (self) {
        self.service = service;
        self.characteristicModels = [NSArray new];
        self.bluetoothModel = [[SILBluetoothModelManager sharedManager] serviceModelForUUIDString:[self uuidString]];
        self.isMappable = NO;
    }
    return self;
}

- (NSString *)name {
    if (_bluetoothModel.name) {
        return _bluetoothModel.name;
    }
    
    NSString * const predefinedName = [[SILUUIDProvider sharedProvider] predefinedNameForServiceUUID:[self uuidString]];

    return predefinedName ?: self.mappedName;
}

- (NSString *)mappedName {
    [self setIsMappable:YES];
    NSString * const mappedName = [SILServiceMap getWith:self.uuidString].name;
    return mappedName ?: [self setMappable];
}

- (NSString *)setMappable {
    return @"Unknown Service";
}

#pragma mark - SILGenericAttributeTableModel

- (BOOL)canExpand {
    return self.characteristicModels.count > 0;
}

- (void)toggleExpansionIfAllowed {
    self.isExpanded = !self.isExpanded;
}

- (NSString *)uuidString {
    NSString *uuidString = [self.service.UUID.UUIDString uppercaseString];
    
    if ([uuidString hasPrefix:@"0000"] && [uuidString hasSuffix:@"-0000-1000-8000-00805F9B34FB"]) {
        uuidString = [uuidString substringWithRange:NSMakeRange(4, 4)];
    }
    
    return uuidString;
}

@end
