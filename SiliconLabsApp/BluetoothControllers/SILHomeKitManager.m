//
//  SILHomeKitManager.m
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/11/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILHomeKitManager.h"
#import "SILUUIDProvider.h"

#import "HMAccessory+SILHelpers.h"
#import "HMService+SILHelpers.h"
#import "HMHomeManager+SILHelpers.h"
#import "HMCharacteristic+SILHelpers.h"

NSString * const SILHomeKitManagerDiscoveredAccessoriesNotification = @"SILHomeKitManagerDiscoveredAccessoriesNotification";

@interface SILHomeKitManager () <HMHomeManagerDelegate, HMAccessoryDelegate>

@property (strong, nonatomic) HMHomeManager *hmHomeManager;
@property (copy, nonatomic) NSString *otaName;

@end

@implementation SILHomeKitManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupHomeKit];
    }
    return self;
}

- (void)setupHomeKit {
    _hmHomeManager = [[HMHomeManager alloc] init];
    _hmHomeManager.delegate = self;

    _accessories = [NSArray array];
}

- (void)removeAllDiscoveredAccessories {
    self.accessories = @[];
    [[NSNotificationCenter defaultCenter] postNotificationName:SILHomeKitManagerDiscoveredAccessoriesNotification
                                                        object:self
                                                      userInfo:nil];
}

- (void)reloadAccessories {
    [self updateAccessories:self.hmHomeManager];
}

#pragma mark - HMHomeManagerDelegate

- (void)homeManagerDidUpdateHomes:(HMHomeManager *)manager {
    if ([manager.homes count] == 0) {
        return;
    }

    [self updateAccessories:manager];
}

- (void)homeManagerDidUpdatePrimaryHome:(HMHomeManager *)manager {}

- (void)homeManager:(HMHomeManager *)manager didAddHome:(HMHome *)home {
    [self updateAccessories:manager];
}

- (void)homeManager:(HMHomeManager *)manager didRemoveHome:(HMHome *)home {
    [self updateAccessories:manager];
}

- (void)updateAccessories:(HMHomeManager *)manager {
    NSMutableArray *newAccessories = [NSMutableArray array];
    dispatch_group_t accessoryGroup = dispatch_group_create();

    for (HMHome *home in manager.homes) {
        for (HMAccessory *accessory in home.accessories) {
            dispatch_group_enter(accessoryGroup);
            [self readOTACharacteristicFromAccessory:accessory completionHandler:^(BOOL success) {
                if (success) {
                    [newAccessories addObject:accessory];
                }
                dispatch_group_leave(accessoryGroup);
            }];
        }
    }

    __weak __typeof__(self) weakSelf = self;
    dispatch_group_notify(accessoryGroup, dispatch_get_main_queue(), ^{
        weakSelf.accessories = newAccessories;
        [[NSNotificationCenter defaultCenter] postNotificationName:SILHomeKitManagerDiscoveredAccessoriesNotification
                                                            object:self
                                                          userInfo:nil];
    });
}

#pragma mark - HMAccessoryDelegate

- (void)accessoryDidUpdateReachability:(HMAccessory *)accessory {
    NSLog(@"Accessory (%@) is %@ accessible", accessory.name, accessory.isReachable ? @"" : @"not");
}

#pragma mark - OTA mode services

- (NSString *)transitionAccessoryIntoDFUMode:(HMAccessory *)accessory completionHandler:(void (^)(NSString *otaDeviceName))completion {
    NSString *otaDeviceName = nil;
    
    HMService *otaService = [accessory findServiceOfType:kSILOtaServiceUUIDString];
    if (otaService) {
        __weak SILHomeKitManager *weakSelf = self;
        [self renameOTAAccessoryWithService:otaService completionHandler:^(NSError *error, NSString *otaDeviceName) {
            if (error == nil) {
                [weakSelf putOTAAccessoryWithServiceIntoDFUMode:otaService completionHandler:^(NSError *error) {
                    if (error == nil) {
                        completion(otaDeviceName);
                    } else {
                        NSLog(@"Could not put the accessory into DFU mode. Error: %@", error);
                        completion(nil);
                    }
                }];
            } else {
                NSLog(@"Could not rename the accessory. Error: %@", error);
                completion(nil);
            }
        }];
    }
    
    return otaDeviceName;
}

- (void)renameOTAAccessory:(HMAccessory *)accessory completionHandler:(void (^)(NSError *error, NSString *otaDeviceName))completion {
    
    HMService *otaService = [accessory findServiceOfType:kSILOtaServiceUUIDString];
    if (otaService) {
        [self renameOTAAccessoryWithService:otaService completionHandler:^(NSError *error, NSString *otaDeviceName) {
            if (error == nil) {
                completion(error, otaDeviceName);
            } else {
                completion(error, nil);
            }
        }];
    } else {
        completion(nil, nil);
    }
}

- (void)renameOTAAccessoryWithService:(HMService *)otaService completionHandler:(void (^)(NSError *error, NSString *otaDeviceName))completion {
    NSMutableString *text = [NSMutableString stringWithCapacity:8];
    HMCharacteristic *otaNameCharacteristic = [otaService findCharacteristicOfType:kSILOtaCharacteristicDataUUIDString];
    
    if (otaNameCharacteristic && [otaNameCharacteristic isWritable]) {
        for (int i = 0; i < 4; i++){
            int r = arc4random_uniform(256);
            [text appendFormat:@"%02x", r];
        }
        NSData *textData = [text dataUsingEncoding:NSASCIIStringEncoding];
        self.otaName = text;
        [otaNameCharacteristic writeValue:textData completionHandler:^(NSError *error) {
            completion(error, text);
        }];
    }
}

- (void)putOTAAccessoryIntoDFUMode:(HMAccessory *)accessory completionHandler:(void (^)(NSError *error))completion {
    HMService *otaService = [accessory findServiceOfType:kSILOtaServiceUUIDString];
    if (otaService) {
        [self putOTAAccessoryWithServiceIntoDFUMode:otaService completionHandler:completion];
    } else {
        completion(nil);
    }
}

- (void)putOTAAccessoryWithServiceIntoDFUMode:(HMService *)otaService completionHandler:(void (^)(NSError *error))completion {
    HMCharacteristic *otaControlCharacteristic = [otaService findCharacteristicOfType:kSILOtaCharacteristicControlUUIDString];
    
    if (otaControlCharacteristic && [otaControlCharacteristic isWritable]) {
        // Write 00 to cause the device to go into OTA mode
        unsigned char *bytes = malloc(1);
        bytes[0] = 0x00;
        NSData *data = [NSData dataWithBytes:bytes length:1];
        free(bytes);
        [otaControlCharacteristic writeValue:data completionHandler:completion];
    }
}

- (BOOL)accessoryHasOTAService:(HMAccessory *)accessory {
    BOOL hasOTAService = NO;
    
    HMService *otaService = [accessory findServiceOfType:kSILOtaServiceUUIDString];
    
    if (otaService) {
        HMCharacteristic *otaNameCharacteristic = [otaService findCharacteristicOfType:kSILOtaCharacteristicDataUUIDString];
        HMCharacteristic *otaControlCharacteristic = [otaService findCharacteristicOfType:kSILOtaCharacteristicControlUUIDString];
        
        hasOTAService = (otaControlCharacteristic != nil) && (otaNameCharacteristic != nil);
    }

    return hasOTAService;
}

- (void)readOTACharacteristicFromAccessory:(HMAccessory *)accessory completionHandler:(void (^) (BOOL success))completion {

    HMService *otaService = [accessory findServiceOfType:kSILOtaServiceUUIDString];

    if (otaService) {
        for (HMCharacteristic *characteristic in otaService.characteristics) {
            if ([characteristic.properties containsObject:HMCharacteristicPropertyReadable]) {
                [characteristic readValueWithCompletionHandler:^(NSError * _Nullable error) {
                    completion(error == nil);
                }];
                return;
            }
        }
    }

    completion(NO);
}

@end
