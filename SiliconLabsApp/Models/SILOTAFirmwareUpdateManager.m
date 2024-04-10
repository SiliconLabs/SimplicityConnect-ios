//
//  SILOTAFirmwareUpdateManager.m
//  SiliconLabsApp
//
//  Created by Nicholas Servidio on 3/8/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILOTAFirmwareUpdateManager.h"
#import "CBPeripheral+Services.h"
#import "CBService+Categories.h"
#import "SILUUIDProvider.h"
#import "SILCharacteristicTableModel.h"
#import "NSError+SILHelpers.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "SILOTAFirmwareFile.h"
#if ENABLE_HOMEKIT
#import "SILHomeKitManager.h"
#endif

static NSTimeInterval const kSILDurationBeforeUpdatingDFUStatusToWaiting = 10.0;
static NSInteger const kSILOTAByteAlignment = 4;
static unsigned char kSILOTAByteAlignmentPadding[] = {0xFF, 0xFF, 0xFF, 0xFF};
static char const kSILInitiateDFUData = 0x00;
static char const kSILTerminateFimwareUpdateData = 0x03;

typedef NS_ENUM(NSInteger, SILFirmwareMode) {
    SILFirmwareModeUnknown,
    SILFirmwareModeDFU,
    SILFirmwareModeUpdateFile
};

typedef NS_ENUM(NSInteger, SILOTAControlWriteMode) {
    SILOTAControlWriteModeUnset,
    SILOTAControlWriteModeInitiating,
    SILOTAControlWriteModeTerminating
};

@interface SILOTAFirmwareUpdateManager () <CBPeripheralDelegate>

@property (weak, nonatomic) HMAccessory *accessory;
@property (weak, nonatomic) CBPeripheral *peripheral;
@property (nonatomic) SILFirmwareMode firmwareUpdateMode;
@property (nonatomic) SILOTAControlWriteMode otaControlWriteMode;
@property (nonatomic) NSInteger location;
@property (nonatomic) NSInteger length;
@property (strong, nonatomic) NSData *fileData;
@property (nonatomic) BOOL expectingToDisconnectFromPeripheral;
@property (nonatomic) BOOL didDiscoverOTADevice;
@property (nonatomic, strong) CBCharacteristic *currentWriteCharacteristic;

@property (nonatomic, copy) void (^dfuCompletion)(CBPeripheral *, NSError *);
@property (nonatomic, copy) void (^fileCompletion)(CBPeripheral *, NSError *);
@property (nonatomic, copy) void (^fileProgress)(NSInteger, double);

@end

@implementation SILOTAFirmwareUpdateManager

#pragma mark - Initializers

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral centralManager:(SILCentralManager *)centralManager {
    self = [super init];
    if (self) {
        self.peripheral = peripheral;
        self.peripheral.delegate = self;
        self.centralManager = centralManager;
        self.otaControlWriteMode = SILOTAControlWriteModeUnset;
        [self registerForCentralManagerNotificaions];
    }
    return self;
}

- (instancetype)initWithAccessory:(HMAccessory *)accessory peripheral:(CBPeripheral *)peripheral centralManager:(SILCentralManager *)centralManager {
    _accessory = accessory;
    return [self initWithPeripheral:peripheral centralManager:centralManager];
}

#pragma mark - Setup

- (void)registerForCentralManagerNotificaions {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didConnectToPeripheral:)
                                                 name:SILCentralManagerDidConnectPeripheralNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDisconnectFromPeripheral:)
                                                 name:SILCentralManagerDidDisconnectPeripheralNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFailToConnectToPeripheral:)
                                                 name:SILCentralManagerDidFailToConnectPeripheralNotification object:nil];
}

#pragma mark - Notifications

- (void)didConnectToPeripheral:(NSNotification *)notification {
    self.peripheral = notification.userInfo[SILCentralManagerPeripheralKey];
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:nil];
}

- (void)didDisconnectFromPeripheral:(NSNotification *)notification {
    NSString* uuid = (NSString*)notification.userInfo[SILNotificationKeyUUID];
    
    if ([uuid isEqualToString:self.peripheral.identifier.UUIDString]) {
       if (self.expectingToDisconnectFromPeripheral) {
           self.expectingToDisconnectFromPeripheral = NO;
       } else {
           NSError *error = [NSError sil_errorWithCode:SILErrorCodeOTADisconnectedFromPeripheral underlyingError:nil];
           [self.delegate firmwareUpdateManagerDidUnexpectedlyDisconnectFromPeripheral:self withError:error];
       }
    }
}

- (void)didFailToConnectToPeripheral:(NSNotification *)notification {
    NSError *error = [NSError sil_errorWithCode:SILErrorCodeOTAFailedToConnectToPeripheral underlyingError:nil];
    [self handleCompletionWithMode:self.firmwareUpdateMode peripheral:nil error:error];
}

#pragma mark - Public

- (void)cycleDeviceWithInitiationByteSequence:(BOOL)initiatingByteSequence
                                     progress:(void(^)(SILDFUStatus status))progress
                                   completion:(void(^)(CBPeripheral *peripheral, NSError *error))completion {
    self.firmwareUpdateMode = SILFirmwareModeDFU;
    self.dfuCompletion = completion;
    self.expectingToDisconnectFromPeripheral = YES;

    self.fileCompletion = completion;

    if (initiatingByteSequence && ![self.peripheral hasOTADataCharacteristic]) {
        NSLog(@" ===== Success flow Step-3 == write initial single byte value 0x00 ====== ");
        
        const char kSILInitiateDFUDataTemp = 0x00;
        [self writeSingleByteValue:kSILInitiateDFUDataTemp toCharacteristic:[self.peripheral otaControlCharacteristic]];
    } else {
        NSLog(@" ==== fail flow Step-2 == write single byte value ====== ");
        [self disconnectConnectedPeripheral];
    }

    progress(SILDFUStatusRebooting);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSILDurationBeforeUpdatingDFUStatusToWaiting * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        progress(SILDFUStatusWaiting);
        [self reconnectToOTADevice];
    });
}

- (void)endCycleDevice {
    NSLog(@" ===== Step-4 == Remove Peripherals Observer from scan list ====== ");
    [self.centralManager removeScanForPeripheralsObserver:self];
}

- (void)reconnectToOTADevice {
    SILDiscoveredPeripheral* discoveredPeripheral = [self.centralManager discoveredPeripheralForPeripheral:self.peripheral];
    [self.centralManager connectToDiscoveredPeripheral:discoveredPeripheral];
}

- (void)uploadFile:(SILOTAFirmwareFile *)file
          progress:(void(^)(NSInteger bytes, double fraction))progress
        completion:(void(^)(CBPeripheral *peripheral, NSError *error))completion {
    self.fileCompletion = completion;
    self.fileProgress = progress;
    self.firmwareUpdateMode = SILFirmwareModeUpdateFile;
    
    [self uploadFile:file];
}

- (void)disconnectConnectedPeripheral {
    [self.centralManager disconnectConnectedPeripheral];
}

#pragma mark - CBPeriphralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    if (error == nil) {
        if ([self.peripheral hasOTAService]) {
            [self.peripheral discoverCharacteristics:nil forService:[self.peripheral otaService]];
        } else {
            NSError *theError = [NSError sil_errorWithCode:SILErrorCodeOTAFailedToFindOTAService underlyingError:error];
            [self handleCompletionWithMode:self.firmwareUpdateMode peripheral:peripheral error:theError];
        }
    } else {
        NSError *theError = [NSError sil_errorWithCode:SILErrorCodeOTADiscoveredServicesError underlyingError:error];
        [self handleCompletionWithMode:self.firmwareUpdateMode peripheral:peripheral error:theError];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error == nil) {
        if ([peripheral hasOTADataCharacteristic]) {
            switch (self.firmwareUpdateMode) {
                case SILFirmwareModeDFU:
                    [self handleCompletionWithMode:self.firmwareUpdateMode peripheral:peripheral error:nil];
                    break;
                default:
                    break;
            }
        } else {
            NSError *theError = [NSError sil_errorWithCode:SILErrorCodeOTAFailedToFindOTADataCharacteristic underlyingError:error];
            [self handleCompletionWithMode:self.firmwareUpdateMode peripheral:peripheral error:theError];
        }
    } else {
        NSError *theError = [NSError sil_errorWithCode:SILErrorCodeOTADiscoveredCharacteristicsError underlyingError:error];
        [self handleCompletionWithMode:self.firmwareUpdateMode peripheral:peripheral error:theError];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error != nil) {
        NSError *theError = [NSError sil_errorWithCode:SILErrorCodeOTAFailedToWriteToCharacteristicError underlyingError:error];
        [self handleCompletionWithMode:self.firmwareUpdateMode peripheral:peripheral error:theError];
        return;
    }
    
    if ([characteristic isEqual:[self.peripheral otaDataCharacteristic]]) {
        if (_location < _fileData.length) {
            [self writeFileDataToCharacteristic:characteristic];
            if (self.fileProgress) {
                double fraction = (double)_location / (double)_fileData.length;
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.fileProgress(_location, fraction);
                });
            }
        } else {
            [self writeSingleByteValue:kSILTerminateFimwareUpdateData toCharacteristic:[self.peripheral otaControlCharacteristic]];
            self.expectingToDisconnectFromPeripheral = YES;
            self.otaControlWriteMode = SILOTAControlWriteModeTerminating;
        }
    } else if ([characteristic isEqual:[self.peripheral otaControlCharacteristic]]) {
        if (self.otaControlWriteMode == SILOTAControlWriteModeTerminating) {
            self.fileProgress = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleCompletionWithMode:self.firmwareUpdateMode peripheral:peripheral error:error];
            });
        }
        self.otaControlWriteMode = SILOTAControlWriteModeUnset;
    }
}

#pragma mark - Helpers

- (void)uploadFile:(SILOTAFirmwareFile *)file {
    self.expectingToDisconnectFromPeripheral = NO;
    const char kSILInitiateDFUDataTemp = 0x00;
    [self writeSingleByteValue:kSILInitiateDFUDataTemp toCharacteristic:[self.peripheral otaControlCharacteristic]];
    self.otaControlWriteMode = SILOTAControlWriteModeInitiating;
    
    // TODO: Move something executing here to a background queue. There is too much happening on the main queue at this
    // moment. We have to dispatch openWithCompletionHandler: on the main queue in order to not have an exception thrown.
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([file.fileData length] > 0) {
            self.fileData = file.fileData;
            self.location = 0;
            // Even though the data characteristic is advertised as WriteWithResponse and WriteWithoutResponse, choose
            // WriteWithoutResponse.
            self.length = [SILOTAFirmwareUpdateManager maximumByteAlignedWriteValueLengthForPeripheral:self.peripheral forType:CBCharacteristicWriteWithoutResponse];
            if (self.location < self.fileData.length) {
                
                // steps to upload data
                [self writeFileDataToCharacteristic:[self.peripheral otaDataCharacteristic]];
            }
        } else {
            NSError *error = [NSError sil_errorWithCode:SILErrorCodeOTAFailedToReadFile underlyingError:nil];
            [self handleCompletionWithMode:self.firmwareUpdateMode peripheral:nil error:error];
        }
    });
}

- (void)writeFileDataToCharacteristic:(CBCharacteristic *)characteristic {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData *data;
        if (self.location + self.length > self.fileData.length) {
            NSInteger currentLength = self.fileData.length - self.location;
            NSMutableData *mutableData = [[NSMutableData alloc] initWithData:[self.fileData subdataWithRange:NSMakeRange(self.location, currentLength)]];
            NSInteger lengthPastByteAlignmentBoundary = currentLength % kSILOTAByteAlignment;
            if (lengthPastByteAlignmentBoundary > 0) {
                NSInteger requiredAdditionalLength = kSILOTAByteAlignment - lengthPastByteAlignmentBoundary;
                [mutableData appendBytes:kSILOTAByteAlignmentPadding length:requiredAdditionalLength];
            }
            
            data = [[NSData alloc] initWithData:mutableData];
            self.location = self.location + currentLength;
        } else {
            data = [self.fileData subdataWithRange:NSMakeRange(self.location, self.length)];
            self.location = self.location + self.length;
        }
        
        if (self.delegate.characteristicWriteType == CBCharacteristicWriteWithoutResponse) {
            self.currentWriteCharacteristic = characteristic;
        }
        
        NSLog(@" == Success flow Step-8 == write FW data to peripheral- %@ data == ", data);
        [self.peripheral writeValue:data forCharacteristic:characteristic type:self.delegate.characteristicWriteType];
    });
}

- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    CBCharacteristic * const characteristic = self.currentWriteCharacteristic;
    self.currentWriteCharacteristic = nil;
    
    if (characteristic) {
        [self peripheral:self.peripheral didWriteValueForCharacteristic:characteristic error:nil];
    }
}

- (void)handleCompletionWithMode:(SILFirmwareMode)firmwareMode peripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (firmwareMode == SILFirmwareModeDFU) {
        if (self.dfuCompletion) {
            self.dfuCompletion(peripheral, error);
            self.dfuCompletion = nil;
        }
    } else if (firmwareMode == SILFirmwareModeUpdateFile) {
        if (self.fileCompletion) {
            self.fileCompletion(peripheral, error);
            self.fileCompletion = nil;
        }
    }
    self.otaControlWriteMode = SILOTAControlWriteModeUnset;
}

- (void)writeSingleByteValue:(char)value toCharacteristic:(CBCharacteristic *)characteristic {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        const CBCharacteristicWriteType writeType = self.delegate.characteristicWriteType;
        NSError * error = nil;
        SILCharacteristicTableModel *characteristicTableModel = [[SILCharacteristicTableModel alloc] initWithCharacteristic:characteristic];
        NSData *data = [NSData dataWithBytes:&value length:1];
        [characteristicTableModel setIfAllowedFullWriteValue:data];
        NSLog(@" == Success flow Step-4 == write type %ld == ", (long)writeType);
        [characteristicTableModel writeIfAllowedToPeripheral:self.peripheral withWriteType:writeType error:&error];
    });
}

+ (NSUInteger)maximumByteAlignedWriteValueLengthForPeripheral:(CBPeripheral *)peripheral forType:(CBCharacteristicWriteType)type {
    NSUInteger rawLength = [peripheral maximumWriteValueLengthForType:type];
    return kSILOTAByteAlignment * (rawLength/kSILOTAByteAlignment);
}


@end
