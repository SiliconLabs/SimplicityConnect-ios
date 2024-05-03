//
//  SILConnectedLightingViewController.m
//  SiliconLabsApp
//
//  Created by jamaal.sedayao on 10/31/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILConnectedLightingViewController.h"
#import "SILCentralManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SILConstants.h"
#import "SILApp.h"
#import <SVProgressHUD/SVProgressHUD.h>

typedef NS_ENUM(int, SILLightState) {
    SILConnectedLightStateOff = 0,
    SILConnectedLightStateOn = 1
};

typedef NS_ENUM(int, SILSwitchSource) {
    SILConnectedLightSwitchSourceBluetooth = 0,
    SILConnectedLightSwitchSourceZigbeeOrConnectOrProprietary = 1,
    SILConnectedLightSwitchSourceLightBoard = 2,
};

#define IS_IOS10_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0)

NSString * const SILLightEventOn = @"Light On";
NSString * const SILLightEventOff = @"Light Off";

@interface SILConnectedLightingViewController () <CBPeripheralDelegate, UIGestureRecognizerDelegate> {
    NSTimer *scheduleReadTimer;
    BOOL isConnected;
    BOOL isDMPConnect;
    BOOL isDMPThread;
    BOOL isDMPZigbee;
    CBCharacteristic *lightStateCharacteristic;
    CBCharacteristic *switchSourceCharacteristic;
    CBCharacteristic *sourceAddressCharacteristic;
    SILLightState lightState;
}

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *lightStateImageView;
@property (weak, nonatomic) IBOutlet UIImageView *lastEventSourceImageView;
@property (weak, nonatomic) IBOutlet UILabel *lastEventSourceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastEventStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastEventSourceLabel;
@property (weak, nonatomic) IBOutlet UIView *lastEventImageContentView;
@property (strong, nonatomic) UISelectionFeedbackGenerator *feedbackGenerator;
@property (nonatomic, strong) CBCentralManager *bluetoothManager;

@end

@implementation SILConnectedLightingViewController

- (uint8_t)byteFromData:(NSData *)data {
    uint8_t byte = -1;
    int size = sizeof(uint8_t);
    if (sizeof(data) >= size) {
        [data getBytes:&byte length:size];
    }
    return byte;
}

- (NSString *)hexStringForData:(NSData *)value {
    NSMutableString * const hexString = [[NSMutableString alloc] initWithString:@""];
    const unsigned char *valueBuffer = value.bytes;
    
    for (long index = value.length - 1; index >= 0; --index) {
        [hexString appendFormat:@"%02lX", (unsigned long)valueBuffer[index]];
        
        if (index - 1 >= 0) {
            [hexString appendString:@":"];
        }
    }
    
    return [hexString copy];
}

- (void)updateLightStateImageViewWithData:(NSData *)data {
    uint8_t byte = [self byteFromData:data];
    switch (byte) {
        case SILConnectedLightStateOn:
            NSLog(@"Light State On");
            self.lightStateImageView.image = [UIImage imageNamed:@"lightOn"];
            self.lastEventStateLabel.text = SILLightEventOn;
            lightState = SILConnectedLightStateOn;
            break;
        case SILConnectedLightStateOff:
            NSLog(@"Light State Off");
            self.lightStateImageView.image = [UIImage imageNamed:@"lightOff"];
            self.lastEventStateLabel.text = SILLightEventOff;
            lightState = SILConnectedLightStateOff;
            break;
        default:
            break;
    }
}

- (void)updateSourceImageViewWithData:(NSData *)data {
    uint8_t byte = [self byteFromData:data];
    switch (byte) {
        case SILConnectedLightSwitchSourceBluetooth:
            NSLog(@"Source Bluetooth");
            self.lastEventSourceImageView.image = [UIImage imageNamed:@"iconBluetooth"];
            self.lastEventSourceNameLabel.text = @"Bluetooth";
            [self.lastEventImageContentView setHidden:NO];
            break;
        case SILConnectedLightSwitchSourceZigbeeOrConnectOrProprietary: {
            NSString *imageName = nil;
            NSString *typeName = @"";
            
            if (isDMPConnect) {
                NSLog(@"Source Connect");
                imageName = @"iconBleConnect";
                typeName = @"Connect";
            } else if (isDMPThread) {
                NSLog(@"Source Thread");
                imageName = @"iconThread";
                typeName = @"Thread";
            } else if (isDMPZigbee) {
                NSLog(@"Source Zigbee");
                imageName = @"iconZigbee";
                typeName = @"Zigbee";
            } else {
                NSLog(@"Source Proprietary");
                imageName = @"iconProprietary";
                typeName = @"Proprietary";
            }
            self.lastEventSourceImageView.image = [UIImage imageNamed:imageName];
            self.lastEventSourceNameLabel.text = typeName;
            [self.lastEventImageContentView setHidden:NO];
            [self scheduleRecoveryRead];
            break;
        }
        case SILConnectedLightSwitchSourceLightBoard:
            NSLog(@"Source LightBoard");
            self.lastEventSourceImageView.image = nil;
            self.lastEventSourceNameLabel.text = @"Local control";
            [self.lastEventImageContentView setHidden:YES];
            [self scheduleRecoveryRead];
            break;
        default:
            break;
    }
}

- (void)updateSourceAddressLabelWithData:(NSData *)data {
    char allZeroes[] = {0,0,0,0,0,0,0,0};
    NSData *badData = [NSData dataWithBytes:allZeroes length:sizeof(allZeroes)];
    if ([data isEqual: badData]) {
        self.lastEventSourceLabel.text = @"Unknown";
    } else {
        self.lastEventSourceLabel.text = [self hexStringForData:data];
    }
}

// DMP is unable to handle rapid toggling of the light state from a zigbee/button
// For the app to display the correct light state, schedule an explicit read of the light state characteristic
// 0.8s after the last status change from zigbee/button
- (void)scheduleRecoveryRead {
    [scheduleReadTimer invalidate];
    scheduleReadTimer = nil;
    scheduleReadTimer = [NSTimer scheduledTimerWithTimeInterval:0.8f
                                                         target:self
                                                       selector:@selector(readLightStateCharacteristic)
                                                       userInfo:nil
                                                        repeats:NO];
    
}

- (void)readLightStateCharacteristic {
    NSLog(@"recovery read");
    if (lightStateCharacteristic != nil) {
        [self.connectedPeripheral readValueForCharacteristic:lightStateCharacteristic];
    }
    scheduleReadTimer = nil;
}

#pragma mark - Action

- (void)didTapLightStateImageView {
    NSLog(@"did tap light state imageView");
    uint8_t bytesOff[1] = {0x00};
    uint8_t bytesOn[1] = {0x01};
    NSData *data;
    if (lightState == SILConnectedLightStateOff) {
        data = [NSData dataWithBytes:bytesOn length:sizeof(bytesOn)];
    } else {
        data = [NSData dataWithBytes:bytesOff length:sizeof(bytesOff)];
    }
    if (lightStateCharacteristic != nil) {
        [self.connectedPeripheral writeValue:data forCharacteristic:lightStateCharacteristic
                                        type:CBCharacteristicWriteWithResponse];
    }
    [self generateHapticFeedback];
}

- (void)generateHapticFeedback {
    if (!IS_IOS10_OR_LATER) { return; }
    [self.feedbackGenerator prepare];
    [self.feedbackGenerator selectionChanged];
}

- (IBAction)didTapBackButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Light";
    self.feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
    
    SILDiscoveredPeripheral *discoveredPeripheral = [self.centralManager discoveredPeripheralForPeripheral:self.connectedPeripheral];
    isDMPConnect = discoveredPeripheral.isDMPConnectedLightConnect;
    isDMPThread = discoveredPeripheral.isDMPConnectedLightThread;
    isDMPZigbee = discoveredPeripheral.isDMPConnectedLightZigbee;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapLightStateImageView)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.delegate = self;
    [self.lightStateImageView addGestureRecognizer:tapGesture];
    self.lightStateImageView.userInteractionEnabled = YES;
    
    self.contentView.layer.cornerRadius = 16;
    [self.contentView addShadow];
    
    [self setLeftAlignedTitle:@"Connected Lighting"];
    
    [self.lastEventImageContentView setHidden:YES];
    
    if(!self.bluetoothManager) {
        NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey: @NO};
        self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate: self queue:nil options:options];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.contentView.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds cornerRadius:16] CGPath];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self preparePeripheral];
    [self observeCentralManagerNotifications];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (isConnected) {
        [self disconnectPeripheral];
    }
    [self stopObservingCentralManagerNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.tabBarController hideTabBarAndUpdateFrames];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.tabBarController showTabBarAndUpdateFrames];
}

#pragma mark - Central Manager Notifications

- (void)observeCentralManagerNotifications {
    [self stopObservingCentralManagerNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCentralManagerNotification:)
                                                 name:SILCentralManagerDidDisconnectPeripheralNotification
                                               object:self.centralManager];
}

- (void)stopObservingCentralManagerNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SILCentralManagerDidDisconnectPeripheralNotification
                                                  object:self.centralManager];
}

- (void)handleCentralManagerNotification:(NSNotification *)notification {
    [self disconnectPeripheral];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Bluetooth

- (void)preparePeripheral {
    if ([self.connectedPeripheral state] == CBPeripheralStateConnected) {
        isConnected = YES;
        self.connectedPeripheral.delegate = self;
        if ([self.connectedPeripheral services].count > 0) {
            [self discoverPeripheralCharacteristicsForServices];
        } else {
            [self.connectedPeripheral discoverServices:self.centralManager.serviceUUIDs];
        }
    } else if ([self.connectedPeripheral state] == CBPeripheralStateDisconnected) {
        [self disconnectPeripheral];
    } else {
        NSLog(@"The app has entered an unhandled state, returning to menu.");
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)disconnectPeripheral {
    isConnected = NO;
    self.connectedPeripheral = nil;
    self.connectedPeripheral.delegate = nil;
    
    [self stopObservingCentralManagerNotifications];
    [self.connectedPeripheral setNotifyValue:NO forCharacteristic:switchSourceCharacteristic];
    [self.connectedPeripheral setNotifyValue:NO forCharacteristic:lightStateCharacteristic];
    [self.connectedPeripheral setNotifyValue:NO forCharacteristic:sourceAddressCharacteristic];
    [self.centralManager disconnectConnectedPeripheral];
}

- (void)discoverPeripheralCharacteristicsForServices {
    for (CBService *service in self.connectedPeripheral.services) {
        [self.connectedPeripheral discoverCharacteristics:@[
                                                            [CBUUID UUIDWithString:SILCharacteristicNumberDMPLightState],
                                                            [CBUUID UUIDWithString:SILCharacteristicNumberDMPSwitchSource],
                                                            [CBUUID UUIDWithString:SILCharacteristicNumberDMPSourceAddress]
                                                            ]
                                               forService:service];
    }
}

#pragma mark - Central Manager status

- (void) showAlert: (NSString *) stateString {
    UIAlertAction* okButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    [self.navigationController popViewControllerAnimated:YES];
                                }];

    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Bluetooth Disabled" message:stateString preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:okButton];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOff) {
        [self showAlert:@"You will be redirected to the home screen. Turn on Bluetoooth to use Connected Lighting"];
    }
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (!error) {
        NSLog(@"didDiscoverService: %@", [peripheral services]);
        [self discoverPeripheralCharacteristicsForServices];
    } else {
        NSLog(@"didDiscoverServices error: %@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (!error) {
        NSLog(@"didDiscoverCharacteristicsForService: %@ characteristics: %@", [peripheral services], service.characteristics);
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SILCharacteristicNumberDMPLightState]]) {
                lightStateCharacteristic = characteristic;
            } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SILCharacteristicNumberDMPSwitchSource]]) {
                switchSourceCharacteristic = characteristic;
            } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SILCharacteristicNumberDMPSourceAddress]]) {
                sourceAddressCharacteristic = characteristic;
            }
            [peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    } else {
        NSLog(@"didDiscoverCharacteristicsForService: %@ error: %@", service, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (!error) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SILCharacteristicNumberDMPLightState]]) {
            NSLog(@"peripheral; didUpdateValueForLightStateCharacteristic: %@", [characteristic value]);
            [self updateLightStateImageViewWithData:[characteristic value]];
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SILCharacteristicNumberDMPSwitchSource]]) {
            NSLog(@"peripheral; didUpdateValueForSwitchSourceCharacteristic: %@", [characteristic value]);
            [self updateSourceImageViewWithData:[characteristic value]];
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SILCharacteristicNumberDMPSourceAddress]]) {
            NSLog(@"peripheral; didUpdateValueForSourceAddressCharacteristic: %@", [characteristic value]);
            [self updateSourceAddressLabelWithData:[characteristic value]];
        }
    } else {
        NSLog(@"didUpdateValueForCharacteristic: %@ error: %@", characteristic, error);
    }
}

@end
