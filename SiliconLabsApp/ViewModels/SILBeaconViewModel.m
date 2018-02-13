//
//  SILBeaconViewModelBase.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 11/18/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILBeaconViewModel.h"
@class SILDoubleKeyDictionaryPair;

@interface SILBeaconViewModel()
@property (strong, nonatomic, readwrite) SILBeacon *beacon;
@end

@implementation SILBeaconViewModel

- (instancetype)initWithBeacon:(SILBeacon *)beacon {
    self = [super init];
    if (self) {
        self.beacon = beacon;
    }
    return self;
}

- (NSString *)name {
    return self.beacon.name;
}

- (NSString *)imageName {
    NSAssert(NO, @"Implement imageName in child class");
    return nil;
}

- (UIImage *)image {
    return [UIImage imageNamed:[self imageName]];
}

- (NSString *)type {
    NSAssert(NO, @"Implement type in child class");
    return nil;
}

- (NSNumber *)rssi {
    NSAssert(NO, @"Implement rssi in child class");
    return nil;
}

- (NSNumber *)tx {
    NSAssert(NO, @"Implement tx in child class");
    return nil;
}

- (SILDoubleKeyDictionaryPair *)beaconDetails {
    NSAssert(NO, @"Implement beaconDetails in child class");
    return nil;
}

@end
