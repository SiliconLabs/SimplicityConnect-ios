//
//  SILFindKeyFobViewController.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/4/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "SILFindKeyFobViewController.h"
#import "SILCentralManager.h"
#import "SILConstants.h"
#import "SILSettings.h"

CGFloat const SILFindKeyFobViewControllerAlertTransitionSmoothing = 4;

typedef NS_ENUM(uint8_t, SILCharacteristicAlertLevelType) {
    SILCharacteristicAlertLevelTypeNone = 0,
    SILCharacteristicAlertLevelTypeMild = 1,
    SILCharacteristicAlertLevelTypeHigh = 2,
};

// NOTE: This class has been modified by request of the SiliconLabs team to
// disable HTM Indications incase they get "Stuck". - 201604180847 GRM/IP

@interface SILFindKeyFobViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *lightImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UILabel *debugLabel;

@property (weak, nonatomic) CBService *immediateAlertService;
@property (weak, nonatomic) CBCharacteristic *immediateAlertLevelCharacteristic;

@property (strong, nonatomic) NSTimer *alertLevelUpdateTimer;
@property (strong, nonatomic) NSTimer *rssiUpdateTimer;

@property (assign, nonatomic) SILCharacteristicAlertLevelType currentAlertLevelType;

@end

@implementation SILFindKeyFobViewController

#pragma mark - Instance Methods

- (void)updateDebugLabel {
    if ([SILSettings displayDebugValues]) {
        self.debugLabel.text = [NSString stringWithFormat:
                                @"TX:%@, RSSI:%@, Delta:%ld",
                                self.txPower,
                                self.lastRSSIMeasurement,
                                lround([self transmitReceiveDifference])
                                ];
    } else {
        self.debugLabel.text = @"";
    }
}

- (CGFloat)transmitReceiveDifference {
    NSInteger txPower = (self.txPower != nil || [self.txPower integerValue] == 0) ? [self.txPower integerValue] : -1;
    NSInteger rssi = (self.lastRSSIMeasurement != nil) ? [self.lastRSSIMeasurement integerValue] : -1;

    CGFloat difference = txPower - rssi;
    difference = MAX([SILSettings minExpectedFobDelta], difference);
    difference = MIN([SILSettings maxExpectedFobDelta], difference);

    return  difference;
}

- (CGFloat)blinkingAnimationDuration {
    CGFloat rangeLength = [SILSettings maxExpectedFobDelta] - [SILSettings minExpectedFobDelta];
    CGFloat difference = [self transmitReceiveDifference] - [SILSettings minExpectedFobDelta];
    CGFloat duration = 0.15 + (difference / rangeLength);
    return duration;
}

- (BOOL)shouldUpdateImeadiateAlertLevelCharacteristicWithType:(SILCharacteristicAlertLevelType)updatedType {
    if (updatedType == self.currentAlertLevelType) {
        return NO;
    } else {
        CGFloat thresholdDelta = [self transmitReceiveDifference] - [SILSettings fobProximityDeltaThreshold];
        if (self.currentAlertLevelType == SILCharacteristicAlertLevelTypeNone) {
            return YES;
        } else if (self.currentAlertLevelType == SILCharacteristicAlertLevelTypeMild && thresholdDelta <= -SILFindKeyFobViewControllerAlertTransitionSmoothing) {
            return YES;
        } else if (self.currentAlertLevelType == SILCharacteristicAlertLevelTypeHigh && thresholdDelta >= SILFindKeyFobViewControllerAlertTransitionSmoothing) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self updateDebugLabel];
    self.currentAlertLevelType = SILCharacteristicAlertLevelTypeNone;
    self.nameLabel.text = self.keyFobPeripheral.name;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self animateLightImageViewAlpha:0.0];
    [self preparePeripheral];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.keyFobPeripheral.delegate = nil;
    [self stopTimers];
    [self unregisterForSingleCentralManagerNotifications];

    [self updateImeadiateAlertLevelCharacteristicWithType:SILCharacteristicAlertLevelTypeNone writeType:CBCharacteristicWriteWithoutResponse];
    [self.centralManager disconnectConnectedPeripheral];
    [SVProgressHUD showErrorWithStatus:@"Disconnecting Fob..."];
}

- (void)dealloc {
    [self stopTimers];
    [self unregisterForSingleCentralManagerNotifications];
}

- (void)preparePeripheral {
    [self registerForSingleCentralManagerNotifications];

    if ([self.keyFobPeripheral state] == CBPeripheralStateConnected) {
        self.keyFobPeripheral.delegate = self;
        [self.keyFobPeripheral discoverServices:[self proximityServiceUUIDs]];
    } else if ([self.keyFobPeripheral state] == CBPeripheralStateDisconnected) {
        [SVProgressHUD showErrorWithStatus:@"Unable to find disconnected FOB"];
        [self.navigationController popViewControllerAnimated:YES];
    }

    [self startTimers];
}

- (void)discoverPeripheralCharacteristicsForServices {
    for (CBService *service in self.keyFobPeripheral.services) {
        NSArray *characteristicUUIDs = @[];
        
        // This is a hack requested by the SiliconLabs team to force HTM Indications to be diasbled in here, just in case.
        if ([service.UUID isEqual:[CBUUID UUIDWithString:SILServiceNumberHealthThermometer]]) {
            characteristicUUIDs = @[[CBUUID UUIDWithString:SILCharacteristicNumberTemperatureMeasurement]];
        } else
        if ([service.UUID isEqual:[CBUUID UUIDWithString:SILServiceNumberImmediateAlert]]) {
            self.immediateAlertService = service;
            characteristicUUIDs = @[[CBUUID UUIDWithString:SILCharacteristicNumberAlertLevel]];
        }
        [self.keyFobPeripheral discoverCharacteristics:characteristicUUIDs
                                            forService:service];
    }
}

- (NSArray *)proximityServiceUUIDs {
    return @[
             [CBUUID UUIDWithString:SILServiceNumberImmediateAlert],
             // This is a hack requested by the SiliconLabs team to force HTM Indications to be diasbled in here, just in case.
             [CBUUID UUIDWithString:SILServiceNumberHealthThermometer]
    ];
}

- (void)updateImeadiateAlertLevelCharacteristicWithType:(SILCharacteristicAlertLevelType)alertLevelType
                             writeType:(CBCharacteristicWriteType)type {
    if (self.keyFobPeripheral == nil) {
        return;
    }
    if (self.keyFobPeripheral.state != CBPeripheralStateConnected) {
        return;
    }
    if (self.immediateAlertLevelCharacteristic == nil) {
        return;
    }

    NSLog(@"updateImeadiateAlertLevelCharacteristicWithType: %d", alertLevelType);

    uint8_t val = alertLevelType;
    NSData *data = [NSData dataWithBytes:&val length:1];
    [self.keyFobPeripheral writeValue:data
                    forCharacteristic:self.immediateAlertLevelCharacteristic
                                 type:type];
    self.currentAlertLevelType = alertLevelType;
}

- (void)animateLightImageViewAlpha:(CGFloat)alpha {
    __weak id weakSelf = self;
    [UIView animateWithDuration:[weakSelf blinkingAnimationDuration]
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [[weakSelf lightImageView] setAlpha:alpha];
                     } completion:^(BOOL finished) {
                         [weakSelf animateLightImageViewAlpha:1.0 - alpha];
                     }];
}

- (void)readRSSI {
    [self.keyFobPeripheral readRSSI];
}

#pragma mark - SILCentralManager Notifications

- (void)registerForSingleCentralManagerNotifications {
    [self unregisterForSingleCentralManagerNotifications];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveSingleCentralManagerDidDisconnectPeripheralNotification:)
                                                 name:SILCentralManagerDidDisconnectPeripheralNotification
                                               object:self.centralManager];
}

- (void)unregisterForSingleCentralManagerNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SILCentralManagerDidDisconnectPeripheralNotification
                                                  object:self.centralManager];
}

- (void)didReceiveSingleCentralManagerDidDisconnectPeripheralNotification:(NSNotification *)notification {
    [SVProgressHUD showErrorWithStatus:@"Device Disconnected..."];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Update Timer

- (void)startTimers {
    [self.rssiUpdateTimer invalidate];
    self.rssiUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                            target:self
                                                          selector:@selector(readRSSI)
                                                          userInfo:nil
                                                           repeats:YES];

    [self.alertLevelUpdateTimer invalidate];
    self.alertLevelUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.25
                                                                  target:self
                                                                selector:@selector(alertLevelUpdateTimerDidExpire:)
                                                                userInfo:nil
                                                                 repeats:YES];
}

- (void)stopTimers {
    [self.rssiUpdateTimer invalidate];
    self.rssiUpdateTimer = nil;

    [self.alertLevelUpdateTimer invalidate];
    self.alertLevelUpdateTimer = nil;
}

- (void)alertLevelUpdateTimerDidExpire:(NSTimer *)timer {
    [self updateDebugLabel];

    SILCharacteristicAlertLevelType type;
    if ([self transmitReceiveDifference] > [SILSettings fobProximityDeltaThreshold]) {
        type = SILCharacteristicAlertLevelTypeMild;
    } else {
        type = SILCharacteristicAlertLevelTypeHigh;
    }

    if ([self shouldUpdateImeadiateAlertLevelCharacteristicWithType:type]) {
        [self updateImeadiateAlertLevelCharacteristicWithType:type
                                                    writeType:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"centralManagerDidUpdateState: %d", (int)[central state]);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"didDisconnectPeripheral: %@", peripheral);
    NSLog(@"error: %@", error);

    [SVProgressHUD showErrorWithStatus:@"Connection Lost"];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"didDiscoverServices error: %@", error);
    } else {
        NSLog(@"didDiscoverService: %@", [peripheral services]);
        [self discoverPeripheralCharacteristicsForServices];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"didDiscoverCharacteristicsForService: %@ error: %@", service, error);
    } else {
        NSLog(@"didDiscoverCharacteristicsForService: %@ characteristics: %@", service, service.characteristics);
        for (CBCharacteristic *characteristic in service.characteristics) {
            if (service == self.immediateAlertService) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SILCharacteristicNumberAlertLevel]]) {
                    self.immediateAlertLevelCharacteristic = characteristic;
                }
            } else
            // This is a hack requested by the SiliconLabs team to force HTM Indications to be diasbled in here, just in case.
            if ([service.UUID isEqual:[CBUUID UUIDWithString:SILServiceNumberHealthThermometer]]) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SILCharacteristicNumberTemperatureMeasurement]]) {
                    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic: %@ error: %@", characteristic, error);
    } else {
        NSLog(@"didUpdateValueForCharacteristic: %@ data: %@", characteristic, [characteristic value]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"didWriteValueForCharacteristic: %@ error: %@", characteristic, error);
    } else {
        NSLog(@"didWriteValueForCharacteristic: %@ data: %@", characteristic, [characteristic value]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    NSLog(@"didReadRSSI: %@", peripheral);
    if (error) {
        NSLog(@"error: %@", error);
    } else {
        NSLog(@"RSSI: %@", RSSI);
        self.lastRSSIMeasurement = RSSI;
    }
}

@end
