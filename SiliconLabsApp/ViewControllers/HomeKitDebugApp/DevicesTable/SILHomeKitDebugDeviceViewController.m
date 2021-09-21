//
//  SILHomeKitDebugDeviceViewController.m
//  SiliconLabsApp
//
//  Created by Ayal Spitz on 5/11/17.
//  Copyright © 2017 SiliconLabs. All rights reserved.
//

#import "SILApp.h"
#import "SILCentralManager.h"
#import "SILHomeKitDebugDeviceViewController.h"
#import "SILHomeKitDebugDeviceTableViewCell.h"
#import "SILDebugHeaderView.h"
#import "SILDiscoveredPeripheral.h"
#import "SILRSSIMeasurementTable.h"
#import "UIColor+SILColors.h"
#import "SILDebugServicesViewController.h"
#import "SILDebugAdvDetailsViewController.h"
#import "SILAdvertisementDataModel.h"
#import "SILDiscoveredPeripheralDisplayDataViewModel.h"
#import "UIView+NibInitable.h"
#import <WYPopoverController/WYPopoverController.h>
#import "WYPopoverController+SILHelpers.h"
#import "SILAlertBarView.h"
#import "UITableViewCell+SILHelpers.h"
#import "SILActivityBarViewController.h"
#import "UIViewController+Containment.h"
#import <PureLayout/PureLayout.h>
#import "SILAdvertisementDataViewModel.h"
#import "SILHomeKitManager.h"
#import "SILHomeKitDebugServicesViewController.h"

const float kHKScanInterval = 15.0f;
const float kScanIntervalPrime = 15.0f;
const float kTableRefreshIntervalPrime = 2.0f;
static NSInteger const kTableViewEdgePaddingPrime = 36;

@interface SILHomeKitDebugDeviceViewController () <UITableViewDataSource, UITableViewDelegate, DebugDeviceCellDelegate, SILActivityBarViewControllerDelegate>

@property (weak, nonatomic) IBOutlet SILAlertBarView *failedConnectionAlertBarView;
@property (weak, nonatomic) IBOutlet UIView *activityBarViewControllerContainer;
@property (weak, nonatomic) IBOutlet UILabel *backgroundMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *backgroundStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *failedConnectionLabel;
@property (weak, nonatomic) IBOutlet UITableView *devicesTableView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *failedConnectionBarHideConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *failedConnectionBarRevealConstraint;

@property (strong, nonatomic) SILHomeKitDebugDeviceTableViewCell *sizingTableCell;

@property (nonatomic) BOOL isObserving;
@property (strong, nonatomic) NSArray *discoveredAccessories;
@property (strong, nonatomic) NSTimer *scanTimer;
@property (strong, nonatomic) NSTimer *tableRefreshTimer;
@property (strong, nonatomic) SILHomeKitManager *homeKitManager;
@property (strong, nonatomic) SILActivityBarViewController *activityBarViewController;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *devicesTableViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *devicesTableViewTrailingConstraint;

@property (nonnull, strong, nonatomic) CBCentralManager *centralManager;

@end

@implementation SILHomeKitDebugDeviceViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    [self setupActivityBar];
    [self setupHomeKitManager];
    [self setupDeviceTable];
    [self setupNavigationBar];
    [self setupBackgroundForScanning:YES];
    [self setUpDevicesTableView];
    [self setUpCentralManager];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForHomeKitNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unregisterForHomeKitNotifications];
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - Setup

- (void)registerNibs {
    NSString *cellClassString = NSStringFromClass([SILHomeKitDebugDeviceTableViewCell class]);
    [self.devicesTableView registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
}

- (void)setupHomeKitManager {
    self.homeKitManager = [[SILHomeKitManager alloc] init];
    [self scanForInterval:kScanIntervalPrime];
}

- (void)setupDeviceTable {
    self.devicesTableView.rowHeight = UITableViewAutomaticDimension;
    self.devicesTableView.estimatedRowHeight = 150;
    self.devicesTableView.sectionHeaderHeight = 40;
    self.devicesTableView.hidden = YES;
    
    NSString *tableCellClassName = NSStringFromClass([SILHomeKitDebugDeviceTableViewCell class]);
    self.sizingTableCell = (SILHomeKitDebugDeviceTableViewCell *)[self.view initWithNibNamed:tableCellClassName];
}

- (void)setupNavigationBar {
    self.title = self.app.title;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" "
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self.navigationController
                                                                            action:@selector(popNavigationItemAnimated:)];
}

- (void)setUpDevicesTableView {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.devicesTableViewLeadingConstraint.constant = kTableViewEdgePaddingPrime;
        self.devicesTableViewTrailingConstraint.constant = kTableViewEdgePaddingPrime;
    } else {
        self.devicesTableViewLeadingConstraint.constant = 0;
        self.devicesTableViewTrailingConstraint.constant = 0;
    }
    self.devicesTableView.backgroundColor = [UIColor sil_bgGreyColor];
}

- (void)setupActivityBar {
    self.activityBarViewController = [[SILActivityBarViewController alloc] init];
    self.activityBarViewController.delegate = self;
    [self ip_addChildViewController:self.activityBarViewController toView:self.activityBarViewControllerContainer];
    [self.activityBarViewController.view autoPinEdgesToSuperviewEdges];
    [self.failedConnectionAlertBarView configureLabel:self.failedConnectionLabel revealConstraint:self.failedConnectionBarRevealConstraint hideConstraint:self.failedConnectionBarHideConstraint];
}

- (void)setupBackgroundForScanning:(BOOL)scanning {
    NSString *backgroundMessage = scanning ? @"Looking for nearby HomeKit devices..." : @"No HomeKit devices found";
    NSString *imageName = scanning ? @"homekit_debug_scanning" : @"debug_not_found";
    self.backgroundMessageLabel.text = backgroundMessage;
    self.backgroundImageView.image = [UIImage imageNamed:imageName];
    self.backgroundStatusLabel.hidden = scanning;
}

- (void)setUpCentralManager {
    // Initializing central manager for the purpose of prompting user to turn on bluetooth
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:nil
                                                               queue:nil
                                                             options:@{CBCentralManagerOptionShowPowerAlertKey: [NSNumber numberWithBool:YES]}];
}

#pragma mark - Notifications

// TODO: Move this to a category.
- (void)registerForHomeKitNotifications {
    if (!self.isObserving) {
        self.isObserving = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didDiscoverAccessoriesNotification:)
                                                     name:SILHomeKitManagerDiscoveredAccessoriesNotification
                                                   object:self.homeKitManager];
    }
}

- (void)unregisterForHomeKitNotifications {
    if (self.isObserving) {
        self.isObserving = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:SILHomeKitManagerDiscoveredAccessoriesNotification
                                                      object:self.homeKitManager];
    }
}

#pragma mark - Notifcation Methods

- (void)didDiscoverAccessoriesNotification:(NSNotification *)notification {
    self.discoveredAccessories = self.homeKitManager.accessories;
}

#pragma mark - Scanning

- (void)scanForInterval:(float)interval {
    [self.activityBarViewController scanningAnimationWithMessage:@"Stop Scanning"];
    self.activityBarViewController.allowsStopActivity = YES;
    self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                      target:self
                                                    selector:@selector(scanIntervalTimerFired)
                                                    userInfo:nil
                                                     repeats:NO];
    self.tableRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:kTableRefreshIntervalPrime
                                                              target:self
                                                            selector:@selector(tableRefreshTimerFired)
                                                            userInfo:nil
                                                             repeats:YES];
    self.devicesTableView.hidden = YES;
    [self setupBackgroundForScanning:YES];
}

- (void)scanIntervalTimerFired {
    [self stopScanningForDevices];
}

- (void)stopScanningForDevices {
    [self removeUnfiredTimers];
    [self.activityBarViewController configureActivityBarWithState:SILActivityBarStateResting];
    self.activityBarViewController.allowsStopActivity = NO;
    if (self.discoveredAccessories.count == 0) {
        [self setupBackgroundForScanning:NO];
    }
    [self refreshTable];
}

- (void)tableRefreshTimerFired {
    if (self.discoveredAccessories.count > 0) {
        self.devicesTableView.hidden = NO;
        [self refreshTable];
    }
}

- (void)refreshTable {
    [self.devicesTableView reloadData];
    [self workaroundHeaderJumpingIssue];
}

- (void)workaroundHeaderJumpingIssue {
    // This is a workaround for the header jumping on a timer fire.
    // Reproduction case without this fix (It helps to increase the scan intervals):
    // 1. Start a scan
    // 2. After any timer fires scroll the table view down any amount.
    // 3. After the next timer fires observe the header view has shifted down.
    // There is no apparent frame change happening here and this fix seems to workaround that issue.
    [self.devicesTableView layoutSubviews];
}

- (void)removeUnfiredTimers {
    [self removeTimer:self.scanTimer];
    [self removeTimer:self.tableRefreshTimer];
}

- (void)removeTimer:(NSTimer *)timer {
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
}

#pragma mark - Connecting

- (void)updateCellsWithConnecting {
    [self.activityBarViewController configureActivityBarWithState:SILActivityBarStateResting];
    [self.devicesTableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.discoveredAccessories.count;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILHomeKitDebugDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILHomeKitDebugDeviceTableViewCell class]) forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    HMAccessory *accessory = self.discoveredAccessories[indexPath.row];
    [self configureTableViewCell:cell withAccessory:accessory atIndexPath:indexPath];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SILDebugHeaderView *headerView = (SILDebugHeaderView *)[self.view initWithNibNamed:NSStringFromClass([SILDebugHeaderView class])];
    headerView.headerLabel.text = @"DEVICES";
    return headerView;
}

//Necessary for iOS7
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    HMAccessory *accessory = self.homeKitManager.accessories[indexPath.row];
    [self configureTableViewCell:self.sizingTableCell withAccessory:accessory atIndexPath:indexPath];
    return [self.sizingTableCell autoLayoutHeight];
}

#pragma mark - DebugDeviceCellDelegate

- (void)displayAdverisementDetails:(UITableViewCell *)cell {

}

- (void)didTapToConnect:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.devicesTableView indexPathForCell:cell];
    HMAccessory *accessory = self.discoveredAccessories[indexPath.row];

    SILHomeKitDebugServicesViewController *servicesViewController = [[SILHomeKitDebugServicesViewController alloc] init];
    servicesViewController.accessory = accessory;
    servicesViewController.homekitManager = self.homeKitManager;
    [self updateCellsWithConnecting];
    [self.activityBarViewController configureActivityBarWithState:SILActivityBarStateResting];
    [self removeUnfiredTimers];
    [self.navigationController pushViewController:servicesViewController animated:YES];
}

#pragma mark - SILActivityBarViewControllerDelegate

- (void)activityBarViewControllerDidTapActivityButton:(SILActivityBarViewController *)controller {
    [self.homeKitManager removeAllDiscoveredAccessories];
    self.discoveredAccessories = nil;
    [self scanForInterval:kHKScanInterval];
    [self.homeKitManager reloadAccessories];
    [self.devicesTableView reloadData];
}

- (void)activityBarViewControllerDidTapStopActivityButton:(SILActivityBarViewController *)controller {
    [self stopScanningForDevices];
}

#pragma mark - Configure Cells

- (void)configureTableViewCell:(SILHomeKitDebugDeviceTableViewCell *)cell withAccessory:(HMAccessory *)accessory atIndexPath:(NSIndexPath *)indexPath {
    cell.displayNameLabel.text = accessory.name;
    cell.uuidLabel.text = accessory.uniqueIdentifier.UUIDString;
    cell.delegate = self;
}

#pragma mark - Dealloc

- (void)dealloc {
    [self removeUnfiredTimers];
}

@end
