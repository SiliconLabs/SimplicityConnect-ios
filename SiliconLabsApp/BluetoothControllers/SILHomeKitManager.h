//
//  SILHomeKitManager.h
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/11/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

@import Foundation;
#if ENABLE_HOMEKIT
#import <HomeKit/HomeKit.h>
#endif

extern NSString * const SILHomeKitManagerDiscoveredAccessoriesNotification;

@interface SILHomeKitManager : NSObject

@property (nonatomic, strong) NSArray *accessories;

- (void)removeAllDiscoveredAccessories;
- (void)reloadAccessories;
- (BOOL)accessoryHasOTAService:(HMAccessory *)accessory;
- (NSString *)transitionAccessoryIntoDFUMode:(HMAccessory *)accessory completionHandler:(void (^)(NSString *otaDeviceName))completion;

- (void)renameOTAAccessory:(HMAccessory *)accessory completionHandler:(void (^)(NSError *error, NSString *otaDeviceName))completion;
- (void)putOTAAccessoryIntoDFUMode:(HMAccessory *)accessory completionHandler:(void (^)(NSError *error))completion;

@end
