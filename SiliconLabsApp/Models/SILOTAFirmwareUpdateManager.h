//
//  SILOTAFirmwareUpdateManager.h
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/8/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SILCentralManager.h"

#import <CoreBluetooth/CoreBluetooth.h>

@class HMAccessory;
@class SILOTAFirmwareFile;

typedef NS_ENUM(NSInteger, SILDFUStatus) {
    SILDFUStatusRebooting,
    SILDFUStatusWaiting,
    SILDFUStatusConnecting
};

@protocol SILOTAFirmwareUpdateManagerDelegate;

@interface SILOTAFirmwareUpdateManager : NSObject

@property (weak, nonatomic) SILCentralManager *centralManager;
@property (weak, nonatomic) id<SILOTAFirmwareUpdateManagerDelegate> delegate;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral centralManager:(SILCentralManager *)centralManager;
- (instancetype)initWithAccessory:(HMAccessory *)accessory peripheral:(CBPeripheral *)peripheral centralManager:(SILCentralManager *)centralManager;

- (void)cycleDeviceWithInitiationByteSequence:(BOOL)initiatingByteSequence
                                     progress:(void(^)(SILDFUStatus status))progress
                                   completion:(void(^)(CBPeripheral *peripheral, NSError *error))completion;
- (void)endCycleDevice;
- (void)uploadFile:(SILOTAFirmwareFile *)file
          progress:(void(^)(NSInteger bytes, double fraction))progress
        completion:(void(^)(CBPeripheral *peripheral, NSError *error))completion;
- (void)disconnectConnectedPeripheral;
+ (NSUInteger)maximumByteAlignedWriteValueLengthForPeripheral:(CBPeripheral *)peripheral forType:(CBCharacteristicWriteType)type;
- (void)reconnectToOTADevice;

@end

@protocol SILOTAFirmwareUpdateManagerDelegate <NSObject>

- (CBCharacteristicWriteType)characteristicWriteType;
- (void)firmwareUpdateManagerDidUnexpectedlyDisconnectFromPeripheral:(SILOTAFirmwareUpdateManager *)firmwareUpdateManager
                                                           withError:(NSError *)error;

@end
