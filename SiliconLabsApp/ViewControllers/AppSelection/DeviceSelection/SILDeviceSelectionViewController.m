//
//  SILDeviceSelectionViewController.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/13/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "SILDeviceSelectionViewController.h"
#import "SILDeviceSelectionCollectionViewCell.h"
#import "SILDiscoveredPeripheral.h"
#import "SILCentralManager.h"
#import "UIImage+SILImages.h"
#import "SILConstants.h"
#import "SILRSSIMeasurementTable.h"
#import "UIColor+SILColors.h"

CGFloat const SILDeviceSelectionViewControllerReloadThreshold = 1.0;

@interface SILDeviceSelectionViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *deviceCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *selectDeviceLabel;

@property (strong, nonatomic) NSTimer *reloadDataTimer;
@property (assign, nonatomic) BOOL isObserving;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation SILDeviceSelectionViewController

- (instancetype)initWithDeviceSelectionViewModel:(SILDeviceSelectionViewModel *)viewModel {
    self = [super init];
    self.viewModel = viewModel;
    return self;
}

#pragma mark - Actions

- (IBAction)didPressCancelButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didDismissDeviceSelectionViewController)]) {
        [self.delegate didDismissDeviceSelectionViewController];
    }
}

#pragma mark - Setup Methods

- (void)setupTextLabels {
    self.selectDeviceLabel.text = [self.viewModel selectDeviceString];
}

#pragma mark - UIViewController Methods

- (CGSize)preferredContentSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake(540, 606);
    } else {
        return CGSizeMake(296, 447);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.deviceCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([SILDeviceSelectionCollectionViewCell class]) bundle:nil]
                forCellWithReuseIdentifier:SILDeviceSelectionCollectionViewCellIdentifier];
    [self setupTextLabels];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self startTimers];
    [self registerForBluetoothControllerNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self stopTimers];
    [self unregisterForBluetoothControllerNotifications];
}

- (void)dealloc {
    [self stopTimers];
    [self unregisterForBluetoothControllerNotifications];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.viewModel.discoveredDevices.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SILDeviceSelectionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SILDeviceSelectionCollectionViewCellIdentifier
                                                                           forIndexPath:indexPath];

    NSArray<SILDiscoveredPeripheral*>* discovered = self.viewModel.discoveredDevices;
    SILDiscoveredPeripheral *discoveredPeripheral = discovered[indexPath.row];
    
    [cell configureCellForPeripheral:discoveredPeripheral andApplication:self.viewModel.app];

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    NSArray<SILDiscoveredPeripheral*>* discovered = self.viewModel.discoveredDevices;
    self.viewModel.connectingPeripheral = discovered[indexPath.row];
    [self.centralManager connectToDiscoveredPeripheral:self.viewModel.connectingPeripheral];
    [SVProgressHUD showWithStatus:@"Connecting..."];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 104.0 : 64.0;

    if ([collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionViewLayout;
        CGFloat rowSpacing = flowLayout.minimumInteritemSpacing + flowLayout.sectionInset.left + flowLayout.sectionInset.right;
        return CGSizeMake(collectionView.frame.size.width - rowSpacing,
                          cellHeight);
    } else {
        return CGSizeMake(collectionView.frame.size.width, cellHeight);
    }
}

#pragma mark - ReloadDataTimer

- (void)startTimers {
    [self.reloadDataTimer invalidate];
    self.reloadDataTimer = [NSTimer scheduledTimerWithTimeInterval:SILDeviceSelectionViewControllerReloadThreshold
                                                            target:self
                                                          selector:@selector(reloadDataIfNecessary)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)stopTimers {
    [self.reloadDataTimer invalidate];
    self.reloadDataTimer = nil;
}

- (void)reloadDataIfNecessary {
    if (self.viewModel.hasDataChanged) {
        self.viewModel.hasDataChanged = NO;

        [self.viewModel updateDiscoveredPeripheralsWithDiscoveredPeripherals:[self.centralManager discoveredPeripherals]];
        [self.deviceCollectionView reloadData];
    }
}

#pragma mark - Bluetooth Controller Notifications

- (void)registerForBluetoothControllerNotifications {
    if (!self.isObserving) {
        self.isObserving = YES;

        [self.centralManager addScanForPeripheralsObserver:self
                                                              selector:@selector(handleCentralManagerDidUpdateDiscoveredPeripheralsNotification:)];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleCentralManagerDidConnectPeripheralNotification:)
                                                     name:SILCentralManagerDidConnectPeripheralNotification
                                                   object:self.centralManager];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleCentralManagerDidFailToConnectPeripheralNotification:)
                                                     name:SILCentralManagerDidFailToConnectPeripheralNotification
                                                   object:self.centralManager];
        if (self.viewModel.app.appType != SILAppTypeRangeTest) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleBluetoothDisabledNotification:) name:SILCentralManagerBluetoothDisabledNotification object:self.centralManager];
            
        }
    }
}

- (void)unregisterForBluetoothControllerNotifications {
    if (self.isObserving) {
        self.isObserving = NO;

        [self.centralManager removeScanForPeripheralsObserver:self];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SILCentralManagerDidConnectPeripheralNotification
                                                      object:self.centralManager];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SILCentralManagerDidFailToConnectPeripheralNotification
                                                      object:self.centralManager];
        if (self.viewModel.app.appType != SILAppTypeRangeTest) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SILCentralManagerBluetoothDisabledNotification
                                                      object:self.centralManager];
        }
    }
}

- (void)handleCentralManagerDidUpdateDiscoveredPeripheralsNotification:(NSNotification *)notification {
    self.viewModel.hasDataChanged = YES;
}

- (void)handleCentralManagerDidConnectPeripheralNotification:(NSNotification *)notification {
    if (self.viewModel.connectingPeripheral) {
        [SVProgressHUD dismiss];
        [self.delegate deviceSelectionViewController:self didSelectPeripheral:self.viewModel.connectingPeripheral.peripheral];
        self.viewModel.connectingPeripheral = nil;
    }
}

- (void)handleCentralManagerDidFailToConnectPeripheralNotification:(NSNotification *)notification {
    if (self.viewModel.connectingPeripheral) {
        [SVProgressHUD showErrorWithStatus:@"Failed to connect..."];
        self.viewModel.connectingPeripheral = nil;
    }
}

- (void)handleBluetoothDisabledNotification:(NSNotification *)notification {
    SILBluetoothDisabledAlertObjc* bluetoothDisabledAlert = nil;
    
    if (self.viewModel.app.appType == SILAppTypeHealthThermometer) {
        bluetoothDisabledAlert = [[SILBluetoothDisabledAlertObjc alloc] initWithBluetoothDisabledAlert:SILBluetoothDisabledAlertHealthThermometer];
    } else if (self.viewModel.app.appType == SILAppTypeConnectedLighting) {
        bluetoothDisabledAlert = [[SILBluetoothDisabledAlertObjc alloc] initWithBluetoothDisabledAlert:SILBluetoothDisabledAlertConnectedLighting];
    } else if (self.viewModel.app.appType == SILAppTypeThroughput) {
        bluetoothDisabledAlert = [[SILBluetoothDisabledAlertObjc alloc] initWithBluetoothDisabledAlert:SILBluetoothDisabledAlertThroughput];
    } else if (self.viewModel.app.appType == SILAppTypeBlinky) {
        bluetoothDisabledAlert = [[SILBluetoothDisabledAlertObjc alloc] initWithBluetoothDisabledAlert:SILBluetoothDisabledAlertBlinky];
    }
    
    if (bluetoothDisabledAlert == nil) {
        return;
    }
    
    [self alertWithOKButtonWithTitle:[bluetoothDisabledAlert getTitle]
    message:[bluetoothDisabledAlert getMessage] completion:^(UIAlertAction * action) {
        if ([self.delegate respondsToSelector:@selector(didDismissDeviceSelectionViewController)]) {
                [self.delegate didDismissDeviceSelectionViewController];
        }
    }];
}

@end
