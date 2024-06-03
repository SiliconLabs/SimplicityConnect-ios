//
//  SILBluetoothSearch.m
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/17/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "CBPeripheral+Services.h"
#import "SILUUIDProvider.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SILBluetoothSearch.h"

@interface SILBluetoothSearch () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, weak) CBCentralManager *centralManager;
@property (nonatomic, strong) NSCondition *condition;

@property (nonatomic, copy) NSString *serviceName;
@property (nonatomic, strong) CBPeripheral *peripheral;

@property (nonatomic, assign) BOOL connecting;
@end

@implementation SILBluetoothSearch

#pragma mark - Object lifecycle

- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager {
    self = [super init];
    if (self) {
        _centralManager = centralManager;
        _centralManager.delegate = self;
        _condition = [[NSCondition alloc] init];
        _connecting = NO;
    }
    return self;
}

#pragma mark -

- (void)searchForService:(NSString *)serviceName completionHandler:(void (^)(CBPeripheral *peripheral))completion {
    self.serviceName = serviceName;
    self.connecting = NO;
    self.peripheral = nil;

    if (self.centralManager.state == CBManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:@[] options: @{CBCentralManagerScanOptionAllowDuplicatesKey : @YES}];
    }

    dispatch_queue_t searchQueue = dispatch_queue_create("SILBluetoothSearch_searchForService", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(searchQueue, ^{
        [self.condition lock];
        [self.condition wait];
        dispatch_async(dispatch_get_main_queue(), ^(){
            completion(self.peripheral);
        });
        [self.condition unlock];
    });
}

#pragma mark - CBCentralManagerDelegate methods

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    
    if (!self.connecting) {
        if ([peripheral.name isEqualToString:self.serviceName] || [advertisementData[CBAdvertisementDataLocalNameKey] isEqualToString:self.serviceName]){
            self.peripheral = peripheral;
            self.connecting = YES;
            [self.centralManager connectPeripheral:self.peripheral options:nil];
            [self.centralManager stopScan];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {

}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    self.peripheral.delegate = self;
    CBUUID *otaServiceUUID = SILUUIDProvider.sharedProvider.otaServiceUUID;
    [self.peripheral discoverServices:@[otaServiceUUID]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    [self.condition lock];
    [self.condition signal];
    [self.condition unlock];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
}

@end
