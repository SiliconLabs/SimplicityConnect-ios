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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *firstSegmentIndicatorTrailingContstraint;

@property (strong, nonatomic) NSTimer *reloadDataTimer;
@property (assign, nonatomic) BOOL isObserving;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;

- (IBAction)typeControlValueDidChange:(id)sender;

@end

@implementation SILDeviceSelectionViewController

- (instancetype)initWithDeviceSelectionViewModel:(SILDeviceSelectionViewModel *)viewModel {
    self = [super init];
    self.viewModel = viewModel;
    return self;
}

#pragma mark - Actions

- (IBAction)typeControlValueDidChange:(id)sender {
    [self.deviceCollectionView reloadData];
}

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
    
    NSArray *tabs = [self.viewModel availableTabs];
    self.typeControl.firstSegmentLabel.text = tabs.firstObject;
    if (tabs.count > 1) {
        self.typeControl.secondSegmentLabel.text = [tabs objectAtIndex:1];
    } else {
        [self hideOtherTab];
    }
}

- (void)hideOtherTab {
    [self.typeControl.secondSegmentView setHidden:true];
    CGFloat trailingContstraint;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        trailingContstraint = 88.5;
    } else {
        trailingContstraint = 79;
    }
    self.firstSegmentIndicatorTrailingContstraint.constant = trailingContstraint;
}

- (void)setupTextLabels {
    self.appTitleLabel.text = [self.viewModel appTitleLabelString];
    self.appDescriptionLabel.text = [self.viewModel appDescriptionString];
    self.appShowcaseLabel.attributedText = [self.viewModel appShowcaseLabelString];
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
    return [self.viewModel discoveredDevicesForIndex:self.typeControl.selectedIndex].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SILDeviceSelectionCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SILDeviceSelectionCollectionViewCellIdentifier
                                                                           forIndexPath:indexPath];

    NSArray *discovered = [self.viewModel discoveredDevicesForIndex:self.typeControl.selectedIndex];
    SILDiscoveredPeripheral *discoveredPeripheral = discovered[indexPath.row];

    cell.deviceNameLabel.text = discoveredPeripheral.advertisedLocalName;
    
    if (self.viewModel.app.appType == SILAppTypeConnectedLighting) {
        cell.dmpTypeImageView.hidden = NO;
        NSString *dmpImage = discoveredPeripheral.isDMPConnectedLightZigbee ? @"iconZigbee" : @"iconProprietary";
        cell.dmpTypeImageView.image = [UIImage imageNamed:dmpImage];
    } else {
        cell.dmpTypeImageView.hidden = YES;
        cell.dmpTypeImageView.image = nil;
    }
    
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

    NSArray *discovered = [self.viewModel discoveredDevicesForIndex:self.typeControl.selectedIndex];
    self.viewModel.connectingPeripheral = discovered[indexPath.row];
    [self.centralManager connectToDiscoveredPeripheral:self.viewModel.connectingPeripheral];
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
    self.viewModel.hasDataChanged = YES;
}

- (void)handleCentralManagerDidConnectPeripheralNotification:(NSNotification *)notification {
    if (self.viewModel.connectingPeripheral) {
        [SVProgressHUD showSuccessWithStatus:@"Connection Successful!"];
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

@end
