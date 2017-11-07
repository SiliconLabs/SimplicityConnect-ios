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
#import "SILSegmentedControl.h"
#import "UIImage+SILImages.h"
#import "SILApp.h"
#import "SILApp+AttributedProfiles.h"
#import "SILConstants.h"
#import "SILRSSIMeasurementTable.h"
#import "UIColor+SILColors.h"

CGFloat const SILDeviceSelectionViewControllerReloadThreshold = 1.0;

typedef NS_ENUM(NSInteger, SILDeviceTypeControlType) {
    SILDeviceTypeControlTypeEFR = 0,
    SILDeviceTypeControlTypeOther = 1,
};

@interface SILDeviceSelectionViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *deviceCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *appTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *appDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *appShowcaseLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectDeviceLabel;
@property (weak, nonatomic) IBOutlet SILSegmentedControl *typeControl;

@property (strong, nonatomic) NSMutableArray *discoveredEFRDevices;
@property (strong, nonatomic) NSMutableArray *discoveredOtherDevices;
@property (strong, nonatomic) SILDiscoveredPeripheral *connectingPeripheral;

@property (strong, nonatomic) NSTimer *reloadDataTimer;
@property (assign, nonatomic) BOOL hasDataChanged;
@property (assign, nonatomic) BOOL isObserving;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;

- (IBAction)typeControlValueDidChange:(id)sender;

@end

@implementation SILDeviceSelectionViewController

#pragma mark - Device Filtering

- (void)updateDiscoveredPeripherals {
    NSArray *discoveredPeripherals = [self.centralManager discoveredPeripherals];

    self.discoveredEFRDevices = [NSMutableArray array];
    self.discoveredOtherDevices = [NSMutableArray array];

    for (SILDiscoveredPeripheral *discoveredPeripheral in discoveredPeripherals) {
        if ([discoveredPeripheral isBlueGeckoBeacon]) {
            [self.discoveredEFRDevices addObject:discoveredPeripheral];
        } else {
            [self.discoveredOtherDevices addObject:discoveredPeripheral];
        }
    }

    self.hasDataChanged = YES;
}

- (NSArray *)discoveredDevices {
    if (self.typeControl.selectedIndex == SILDeviceTypeControlTypeEFR) {
        return self.discoveredEFRDevices;
    } else {
        return self.discoveredOtherDevices;
    }
}

- (IBAction)typeControlValueDidChange:(id)sender {
    [self.deviceCollectionView reloadData];
}

#pragma mark - Button Actions

- (void)didTapCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didPressExitButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didDismissDeviceSelectionViewController)]) {
        [self.delegate didDismissDeviceSelectionViewController];
    }
}

#pragma mark - Setup Methods

- (void)setupTypeControl {
    [self.typeControl addTarget:self action:@selector(typeControlValueDidChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)setupTextLabels {
    self.appTitleLabel.text = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? self.app.title : [self.app.title uppercaseString];

    self.appDescriptionLabel.text = self.app.appDescription;

    self.appShowcaseLabel.attributedText = [self.app showcasedProfilesAttributedStringWithUserInterfaceIdiom:UI_USER_INTERFACE_IDIOM()];
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
    [self setupTypeControl];
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
    return self.discoveredDevices.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SILDeviceSelectionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SILDeviceSelectionCollectionViewCellIdentifier
                                                                           forIndexPath:indexPath];
    SILDiscoveredPeripheral *discoveredPeripheral = self.discoveredDevices[indexPath.row];

    cell.deviceNameLabel.text = discoveredPeripheral.advertisedLocalName;

    NSInteger smoothedRSSIValue = [[discoveredPeripheral.RSSIMeasurementTable averageRSSIMeasurementInPastTimeInterval:SILDeviceSelectionViewControllerReloadThreshold] integerValue];
    if (smoothedRSSIValue > SILConstantsStrongSignalThreshold) {
        cell.signalImageView.image = [UIImage imageNamed:SILImageNameBTStrong];
    } else if (smoothedRSSIValue > SILConstantsMediumSignalThreshold) {
        cell.signalImageView.image = [UIImage imageNamed:SILImageNameBTMedium];
    } else {
        cell.signalImageView.image = [UIImage imageNamed:SILImageNameBTWeak];
    }

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];

    self.connectingPeripheral = self.discoveredDevices[indexPath.row];
    [self.centralManager connectToDiscoveredPeripheral:self.connectingPeripheral];
    [SVProgressHUD showWithStatus:@"Connecting..."];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellsPerRow = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 2.0 : 1.0;
    CGFloat cellHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 105.0 : 64.0;

    if ([collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionViewLayout;
        CGFloat rowSpacing = flowLayout.minimumInteritemSpacing + flowLayout.sectionInset.left + flowLayout.sectionInset.right;
        return CGSizeMake((collectionView.frame.size.width - rowSpacing) / cellsPerRow,
                          cellHeight);
    } else {
        return CGSizeMake(collectionView.frame.size.width / cellsPerRow, cellHeight);
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
    if (self.hasDataChanged) {
        self.hasDataChanged = NO;

        [self updateDiscoveredPeripherals];
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
    }
}

- (void)handleCentralManagerDidUpdateDiscoveredPeripheralsNotification:(NSNotification *)notification {
    self.hasDataChanged = YES;
}

- (void)handleCentralManagerDidConnectPeripheralNotification:(NSNotification *)notification {
    if (self.connectingPeripheral) {
        [SVProgressHUD showSuccessWithStatus:@"Connection Successful!"];
        [self.delegate deviceSelectionViewController:self didSelectPeripheral:self.connectingPeripheral.peripheral];
        self.connectingPeripheral = nil;
    }
}

- (void)handleCentralManagerDidFailToConnectPeripheralNotification:(NSNotification *)notification {
    if (self.connectingPeripheral) {
        [SVProgressHUD showErrorWithStatus:@"Failed to connect..."];
        self.connectingPeripheral = nil;
    }
}

@end
