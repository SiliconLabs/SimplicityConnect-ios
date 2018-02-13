//
//  SILKeyFobViewController.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 2/2/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "SILKeyFobViewController.h"
#import "SILApp.h"
#import "SILKeyFobTableSectionHeaderView.h"
#import "SILKeyFobTableViewCell.h"
#import "SILFindKeyFobViewController.h"
#import "SILDiscoveredPeripheral.h"
#import "SILConstants.h"
#import "UIImage+SILImages.h"
#import "SILRSSIMeasurementTable.h"
#import "UIColor+SILColors.h"

#import "SILCentralManager.h"

CGFloat const SILKeyFobViewControllerReloadThreshold = 1.0;

@interface SILKeyFobViewController () <UITableViewDataSource, UITableViewDelegate, SILKeyFobTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *fobsTableView;

@property (strong, nonatomic) SILCentralManager *centralManager;

@property (strong, nonatomic) NSMutableArray *discoveredEFRFobs;
@property (strong, nonatomic) NSMutableArray *discoveredOtherFobs;

@property (strong, nonatomic) NSTimer *reloadDataTimer;
@property (assign, nonatomic) BOOL hasDataChanged;

@property (strong, nonatomic) SILDiscoveredPeripheral *connectingDiscoveredPeripheral;

@end

@implementation SILKeyFobViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.app.title;

    [self.fobsTableView registerNib:[UINib nibWithNibName:NSStringFromClass([SILKeyFobTableSectionHeaderView class]) bundle:nil]
             forCellReuseIdentifier:NSStringFromClass([SILKeyFobTableSectionHeaderView class])];
    [self.fobsTableView registerNib:[UINib nibWithNibName:NSStringFromClass([SILKeyFobTableViewCell class]) bundle:nil]
             forCellReuseIdentifier:NSStringFromClass([SILKeyFobTableViewCell class])];
    self.discoveredEFRFobs = [NSMutableArray array];
    self.discoveredOtherFobs = [NSMutableArray array];
    self.centralManager = [[SILCentralManager alloc] initWithServiceUUIDs:[self proximityServiceUUIDs]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self startTimers];
    [self registerForSingleCentralManagerNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self stopTimers];
    [self unregisterForSingleCentralManagerNotifications];
}

- (void)dealloc {
    [self.reloadDataTimer invalidate];
}

- (void)presentFindKeyFobViewControllerWithPeripheral:(SILDiscoveredPeripheral *)discoveredPeripheral animated:(BOOL)animated {
    SILFindKeyFobViewController *findViewController = [[SILFindKeyFobViewController alloc] init];
    findViewController.centralManager = self.centralManager;
    findViewController.keyFobPeripheral = discoveredPeripheral.peripheral;
    findViewController.txPower = discoveredPeripheral.txPowerLevel ?: @(SILConstantsTxPowerDefault);
    findViewController.lastRSSIMeasurement = [discoveredPeripheral.RSSIMeasurementTable lastRSSIMeasurement];
    [self.navigationController pushViewController:findViewController animated:YES];
}

#pragma mark - ReloadDataTimer

- (void)startTimers {
    [self.reloadDataTimer invalidate];
    self.reloadDataTimer = [NSTimer scheduledTimerWithTimeInterval:SILKeyFobViewControllerReloadThreshold
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
        [self.fobsTableView reloadData];
    }
}

#pragma mark - SILCentralManager Notifications

- (void)registerForSingleCentralManagerNotifications {
    [self unregisterForSingleCentralManagerNotifications];

    [self.centralManager addScanForPeripheralsObserver:self
                                              selector:@selector(didReceiveSingleCentralManagerDidUpdateDiscoveredPeripheralsNotification:)];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveSingleCentralManagerDidConnectPeripheralNotification:)
                                                 name:SILCentralManagerDidConnectPeripheralNotification
                                               object:self.centralManager];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveSingleCentralManagerDidFailToConnectPeripheralNotification:)
                                                 name:SILCentralManagerDidFailToConnectPeripheralNotification
                                               object:self.centralManager];
}

- (void)unregisterForSingleCentralManagerNotifications {
    [self.centralManager removeScanForPeripheralsObserver:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SILCentralManagerDidConnectPeripheralNotification
                                                  object:self.centralManager];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SILCentralManagerDidFailToConnectPeripheralNotification
                                                  object:self.centralManager];
}

- (void)registerForDiscoveredPeripheralsNotification {
    [self unregisterForDiscoveredPeripheralsNotification];

    [self.centralManager addScanForPeripheralsObserver:self
                                                          selector:@selector(didReceiveSingleCentralManagerDidUpdateDiscoveredPeripheralsNotification:)];
}

- (void)unregisterForDiscoveredPeripheralsNotification {
    [self.centralManager removeScanForPeripheralsObserver:self];
}

- (void)didReceiveSingleCentralManagerDidUpdateDiscoveredPeripheralsNotification:(NSNotification *)notification {
    self.hasDataChanged = YES;
}

- (void)didReceiveSingleCentralManagerDidConnectPeripheralNotification:(NSNotification *)notification {
    [SVProgressHUD showSuccessWithStatus:@"Connection Successful!"];
    [self registerForDiscoveredPeripheralsNotification];

    [self presentFindKeyFobViewControllerWithPeripheral:self.connectingDiscoveredPeripheral animated:YES];
    self.connectingDiscoveredPeripheral = nil;
    
    [self updateDiscoveredPeripherals];
    [self.fobsTableView reloadData];
}

- (void)didReceiveSingleCentralManagerDidFailToConnectPeripheralNotification:(NSNotification *)notification {
    [SVProgressHUD showErrorWithStatus:@"Failed to connect..."];
    [self registerForDiscoveredPeripheralsNotification];

    self.connectingDiscoveredPeripheral = nil;
}

#pragma mark - Bluetooth

- (NSArray *)proximityServiceUUIDs {
    return @[
             [CBUUID UUIDWithString:SILServiceNumberImmediateAlert]
             ];
}

- (void)updateDiscoveredPeripherals {
    NSArray *discoveredPeripherals = [self.centralManager discoveredPeripherals];
    
    [self.discoveredEFRFobs removeAllObjects];
    [self.discoveredOtherFobs removeAllObjects];

    for (SILDiscoveredPeripheral *discoveredPeripheral in discoveredPeripherals) {
        if ([discoveredPeripheral isBlueGeckoBeacon]) {
            [self.discoveredEFRFobs addObject:discoveredPeripheral];
        } else {
            [self.discoveredOtherFobs addObject:discoveredPeripheral];
        }
    }

    self.hasDataChanged = YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.discoveredEFRFobs.count + 1;
    } else {
        return self.discoveredOtherFobs.count + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIColor *backgroundColor;
    UIEdgeInsets edgeInsets;
    if (indexPath.section == 0) {
        backgroundColor = [UIColor colorWithWhite:240.0/255.0 alpha:1.0];

        if (indexPath.row == 0) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                edgeInsets = UIEdgeInsetsMake(0, 36, 0, 36);
            } else {
                edgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
            }
        } else {
            if (indexPath.row == ([tableView numberOfRowsInSection:indexPath.section] - 1)) {
                edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
            } else {
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    edgeInsets = UIEdgeInsetsMake(0, 147, 0, 36);
                } else {
                    edgeInsets = UIEdgeInsetsMake(0, 72, 0, 16);
                }
            }
        }
    } else {
        backgroundColor = [UIColor colorWithWhite:230.0/255.0 alpha:1.0];

        if (indexPath.row == 0) {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                edgeInsets = UIEdgeInsetsMake(0, 36, 0, 36);
            } else {
                edgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
            }
        } else {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                edgeInsets = UIEdgeInsetsMake(0, 147, 0, 36);
            } else {
                edgeInsets = UIEdgeInsetsMake(0, 72, 0, 16);
            }
        }
    }

    if (indexPath.row == 0) {
        SILKeyFobTableSectionHeaderView *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILKeyFobTableSectionHeaderView class])
                                                                       forIndexPath:indexPath];
        cell.backgroundColor = backgroundColor;
        cell.separatorInset = edgeInsets;

        switch (indexPath.section) {
            case 0:
                cell.sectionTitleLabel.text = @"FOB LIST";
                break;
            case 1:
                cell.sectionTitleLabel.text = @"OTHER FOBS";
                break;
            default:
                cell.sectionTitleLabel.text = @"";
                break;
        }
        
        return cell;
    } else {
        SILKeyFobTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILKeyFobTableViewCell class])
                                                                       forIndexPath:indexPath];
        cell.backgroundColor = backgroundColor;
        cell.separatorInset = edgeInsets;

        NSArray *peripheralList = indexPath.section == 0 ? self.discoveredEFRFobs : self.discoveredOtherFobs;
        SILDiscoveredPeripheral *discoveredPeripheral = peripheralList[indexPath.row - 1];

        cell.nameLabel.text = discoveredPeripheral.advertisedLocalName;

        NSInteger smoothedRSSIValue = [[discoveredPeripheral.RSSIMeasurementTable averageRSSIMeasurementInPastTimeInterval:SILKeyFobViewControllerReloadThreshold] integerValue];
        NSString *strengthName;
        if (smoothedRSSIValue > SILConstantsStrongSignalThreshold) {
            cell.strengthImageView.image = [UIImage imageNamed:SILImageNameKeyFOBGood];
            strengthName = @"Good";
        } else if (smoothedRSSIValue > SILConstantsMediumSignalThreshold) {
            cell.strengthImageView.image = [UIImage imageNamed:SILImageNameKeyFOBAverage];
            strengthName = @"Average";
        } else {
            cell.strengthImageView.image = [UIImage imageNamed:SILImageNameKeyFOBWeak];
            strengthName = @"Weak";
        }
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            cell.strengthLabel.textColor = [UIColor sil_masalaColor];
        } else {
            cell.strengthLabel.textColor = [UIColor sil_boulderColor];
            strengthName = [NSString stringWithFormat:@"%@ signal", strengthName];
        }
        cell.strengthLabel.text = strengthName;

        cell.delegate = self;
        cell.context = discoveredPeripheral;
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return 72;
        } else {
            return 39;
        }
    } else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            return 125;
        } else {
            return 64;
        }
    }
}

#pragma mark - SILKeyFobTableViewCellDelegate

- (void)didSelectFindMeWithKeyFobTableViewCell:(SILKeyFobTableViewCell *)cell {
    [SVProgressHUD showWithStatus:@"Connecting..."];

    self.connectingDiscoveredPeripheral = cell.context;
    [self unregisterForDiscoveredPeripheralsNotification];
    [self.centralManager connectToDiscoveredPeripheral:self.connectingDiscoveredPeripheral];
}

@end
