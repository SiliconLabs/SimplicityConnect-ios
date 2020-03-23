//
//  SILDebugViewController.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 9/30/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import "SILApp.h"
#import "SILCentralManager.h"
#import "SILDebugDeviceViewController.h"
#import "SILDebugDeviceTableViewCell.h"
#import "SILDebugHeaderView.h"
#import "SILDiscoveredPeripheral.h"
#import "SILRSSIMeasurementTable.h"
#import "UIColor+SILColors.h"
#import "SILDebugServicesViewController.h"
#import "SILDebugAdvDetailsViewController.h"
#import "SILDebugAdvDetailsCollectionView.h"
#import "SILDebugAdvDetailCollectionViewCell.h"
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
#import "SILDiscoveredPeripheralDisplayData.h"
#import "SILAdvertisementDataViewModel.h"

const float kTableRefreshInterval = 2.0f;
static NSInteger const kTableViewEdgePadding = 36;
const float kFilterBarHeightCollapsed = 0.0f;
const float kFilterBarHeightExpanded = 81.0f;

@interface SILDebugDeviceViewController () <UITableViewDataSource, UITableViewDelegate, CBPeripheralDelegate, DebugDeviceCellDelegate, SILDebugPopoverViewControllerDelegate, WYPopoverControllerDelegate, SILActivityBarViewControllerDelegate, UITextFieldDelegate, SILDebugDeviceViewModelDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SILDebugDeviceFilterViewControllerDelegate>

@property (strong, nonatomic) SILDebugDeviceViewModel *viewModel;
@property (weak, nonatomic) IBOutlet SILAlertBarView *failedConnectionAlertBarView;
@property (weak, nonatomic) IBOutlet UIView *activityBarViewControllerContainer;
@property (weak, nonatomic) IBOutlet UILabel *backgroundMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *backgroundStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *failedConnectionLabel;
@property (weak, nonatomic) IBOutlet UITableView *devicesTableView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *failedConnectionBarHideConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *failedConnectionBarRevealConstraint;

@property (strong, nonatomic) SILDebugAdvDetailCollectionViewCell *sizingCollectionCell;

@property (nonatomic) BOOL isAnimatingFailedBar;
@property (strong, nonatomic) NSTimer *tableRefreshTimer;
@property (strong, nonatomic) NSIndexPath *connectingCellIndexPath;
@property (strong, nonatomic) WYPopoverController *peripheralPopoverController;
@property (strong, nonatomic) WYPopoverController *filterPopoverController;
@property (strong, nonatomic) SILActivityBarViewController *activityBarViewController;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *devicesTableViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *devicesTableViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *filterBarHeightConstraint;

@property (strong, nonatomic) UIImageView *filterArrowView;
@property (strong, nonatomic) NSLayoutConstraint *filterArrowCenterXConstraint;
@property (strong, nonatomic) UIBarButtonItem *filterBarButtonItem;
@property (weak, nonatomic) IBOutlet UIView *filterView;
@property (weak, nonatomic) IBOutlet UILabel *currentFilterLabel;

@end

@implementation SILDebugDeviceViewController

#pragma mark - UIViewController

+ (UIImage *)filterArrowImage {
    static UIImage *filterArrowImage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGSize arrowSize = CGSizeMake(11.3, 7.4);
        UIGraphicsBeginImageContextWithOptions(arrowSize, NO, [[UIScreen mainScreen] scale]);
        UIBezierPath *path = [[UIBezierPath alloc] init];
        [path moveToPoint:CGPointMake(0, arrowSize.height)]; // Move to bottom left
        [path addLineToPoint:CGPointMake(arrowSize.width, arrowSize.height)]; // Move to bottom right
        [path addLineToPoint:CGPointMake(arrowSize.width / 2, 0)]; // Move to top middle
        [path closePath];
        [[UIColor whiteColor] setFill];
        [path fill];
        filterArrowImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return filterArrowImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    [self setupActivityBar];
    [self setupViewModel];
    [self setupDeviceTable];
    [self setupNavigationBar];
    [self setupBackgroundForScanning:YES];
    [self setUpDevicesTableView];
    [self registerForApplicationDidBecomeActiveNotification];
    [self setupFilterArrowView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.viewModel.observing = YES;
    [self startScanning];
    [self filterArrowViewFadeIn:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.viewModel.connectedPeripheral) {
        [self.failedConnectionAlertBarView revealAlertBarWithMessage:self.viewModel.peripheralDisconnectedMessage revealTime:0.4f displayTime:3.0f];
    }
    self.viewModel.connectedPeripheral = nil;

    // Set z position to display arrow over navigation bar
    self.navigationController.navigationBar.layer.zPosition = -1;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.viewModel.observing = NO;
    [self filterArrowViewFadeIn:NO];
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (![parent isEqual:self.parentViewController]) {
        [self unregisterForApplicationDidBecomeActiveNotification];
        [self removeUnfiredTimers];
        // Reset z position
        self.navigationController.navigationBar.layer.zPosition = 0;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIView *filterBarButtonItemView = [self.filterBarButtonItem valueForKey:@"view"];
    CGRect filterBarButtonItemFrame = filterBarButtonItemView.frame;
    self.filterArrowCenterXConstraint.constant = filterBarButtonItemFrame.origin.x + filterBarButtonItemFrame.size.width / 2;
}

#pragma mark - Actions

- (void)filterBarButtonItemTapped {
    SILDebugDeviceFilterViewController *filterViewController = [[SILDebugDeviceFilterViewController alloc] initWithQuery:self.viewModel.searchByDeviceName rssi:self.viewModel.currentMinRSSI];
    filterViewController.delegate = self;
    self.filterPopoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:filterViewController
                                                                                 presentingViewController:self
                                                                                                 delegate:self
                                                                                                 animated:YES];
}

- (IBAction)resetFilterButtonTapped {
    self.currentFilterLabel.text = nil;
    [self.viewModel resetFilter];
    [self refreshTable];
    self.filterBarHeightConstraint.constant = kFilterBarHeightCollapsed;
    [self.filterArrowView setHidden:YES];
}

- (void)filterArrowViewFadeIn:(BOOL)fadeIn {
    CGFloat alpha;
    if (fadeIn) {
        alpha = 1.0;
    } else {
        alpha = 0.0;
    }
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self.filterArrowView setAlpha:alpha];
                     }];
}

#pragma mark - Setup

- (void)registerNibs {
    NSString *cellClassString = NSStringFromClass([SILDebugDeviceTableViewCell class]);
    [self.devicesTableView registerNib:[UINib nibWithNibName:cellClassString bundle:nil] forCellReuseIdentifier:cellClassString];
}

- (void)setupDeviceTable {
    self.devicesTableView.rowHeight = UITableViewAutomaticDimension;
    self.devicesTableView.estimatedRowHeight = 150;
    self.devicesTableView.sectionHeaderHeight = 40;
    self.devicesTableView.hidden = YES;

    NSString *collectionCellClassName = NSStringFromClass([SILDebugAdvDetailCollectionViewCell class]);
    self.sizingCollectionCell = (SILDebugAdvDetailCollectionViewCell *)[self.view initWithNibNamed:collectionCellClassName];
}

- (void)setupNavigationBar {
    self.title = self.app.title;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" "
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self.navigationController
                                                                            action:@selector(popNavigationItemAnimated:)];

    UIImage *filterBarButtonItemImage = [UIImage imageNamed:@"icFilter"];
    self.filterBarButtonItem = [[UIBarButtonItem alloc] initWithImage:filterBarButtonItemImage
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(filterBarButtonItemTapped)];
    self.navigationItem.rightBarButtonItem = self.filterBarButtonItem;
}

- (void)setUpDevicesTableView {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.devicesTableViewLeadingConstraint.constant = kTableViewEdgePadding;
        self.devicesTableViewTrailingConstraint.constant = kTableViewEdgePadding;
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

- (void)setupViewModel {
    self.viewModel = [[SILDebugDeviceViewModel alloc] init];
    self.viewModel.delegate = self;
}

- (void)setupBackgroundForScanning:(BOOL)scanning {
    NSString *backgroundMessage = scanning ? @"Looking for nearby devices..." : @"No devices found";
    NSString *imageName = scanning ? @"debug_scanning" : @"debug_not_found";
    self.backgroundMessageLabel.text = backgroundMessage;
    self.backgroundImageView.image = [UIImage imageNamed:imageName];
    self.backgroundStatusLabel.hidden = scanning;
}

- (void)textFieldTextDidChange:(UITextField *)textField {
    self.viewModel.searchByDeviceName = textField.text;
    [self refreshTable];
}

- (void)rssiSliderValueDidChange:(UISlider *)slider {
    self.viewModel.currentMinRSSI = @(-slider.value);
    [self refreshTable];
}

- (void)setupFilterArrowView {
    self.filterArrowView = [[UIImageView alloc] initWithImage: [[self class] filterArrowImage]];
    [self.filterArrowView setHidden:YES];
    self.filterArrowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.filterArrowView];

    self.filterArrowCenterXConstraint = [self.filterArrowView.centerXAnchor constraintEqualToAnchor:self.filterView.leadingAnchor];
    [self.filterArrowCenterXConstraint setActive:YES];
    [[self.filterArrowView.bottomAnchor constraintEqualToAnchor:self.filterView.topAnchor constant: 1] setActive:YES];
    [[self.filterArrowView.widthAnchor constraintEqualToConstant:11.3] setActive:YES];
    [[self.filterArrowView.heightAnchor constraintEqualToConstant:7.4] setActive:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Notifications

- (void)registerForApplicationDidBecomeActiveNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)unregisterForApplicationDidBecomeActiveNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - Notifcation Methods

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self startScanning];
}

#pragma mark - Scanning

- (void)startScanning {
    [self.viewModel startScanning];
    [self.activityBarViewController scanningAnimationWithMessage:@"Stop Scanning"];
    self.activityBarViewController.allowsStopActivity = YES;

    self.tableRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:kTableRefreshInterval
                                                              target:self
                                                            selector:@selector(tableRefreshTimerFired)
                                                            userInfo:nil
                                                              repeats:YES];
    self.devicesTableView.hidden = YES;
    [self setupBackgroundForScanning:YES];
}

- (void)stopScanningForDevices {
    [self removeUnfiredTimers];
    [self.activityBarViewController configureActivityBarWithState:SILActivityBarStateResting];
    self.activityBarViewController.allowsStopActivity = NO;
    if (self.viewModel.discoveredPeripheralsViewModels.count == 0) {
        [self setupBackgroundForScanning:NO];
    }
    [self refreshTable];
}

- (void)tableRefreshTimerFired {
    if (self.viewModel.isContentAvailable) {
        self.devicesTableView.hidden = NO;
        [self refreshTable];
    }
}

- (void)refreshTable {
    [self.viewModel refreshDiscoveredPeripheralViewModels];
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
    if (!self.viewModel.isConnecting) {
        self.connectingCellIndexPath = nil;
        [self.activityBarViewController configureActivityBarWithState:SILActivityBarStateResting];
    }

    [self.devicesTableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.discoveredPeripheralsViewModels.count;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILDebugDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugDeviceTableViewCell class]) forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    SILDiscoveredPeripheralDisplayDataViewModel *discoveredPeripheralViewModel = [self.viewModel peripheralViewModelAt:indexPath.row];
    [self configureTableViewCell:cell withDiscoveredPeripheral:discoveredPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral atIndexPath:indexPath];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SILDebugHeaderView *headerView = (SILDebugHeaderView *)[self.view initWithNibNamed:NSStringFromClass([SILDebugHeaderView class])];
    headerView.headerLabel.text = @"DEVICES";
    return headerView;
}

#pragma mark - DebugDeviceCellDelegate

- (void)displayAdvertisementDetails:(UITableViewCell *)cell {
    NSIndexPath *selectedIndexPath = [self.devicesTableView indexPathForCell:cell];
    SILDiscoveredPeripheralDisplayDataViewModel *selectedPeripheralViewModel = [self.viewModel peripheralViewModelAt:selectedIndexPath.row];
    if (selectedPeripheralViewModel != nil) {
        SILDebugAdvDetailsViewController *advDetailsViewController = [[SILDebugAdvDetailsViewController alloc] initWithPeripheralViewModel:selectedPeripheralViewModel];
        advDetailsViewController.popoverDelegate = self;
        self.peripheralPopoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:advDetailsViewController
                                                                                         presentingViewController:self
                                                                                                         delegate:self
                                                                                                         animated:YES];
    }
}

- (void)didTapToConnect:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.devicesTableView indexPathForCell:cell];
    SILDiscoveredPeripheralDisplayDataViewModel *selectedPeripheralViewModel = [self.viewModel peripheralViewModelAt:indexPath.row];

    if ([self.viewModel connectTo:selectedPeripheralViewModel]) {
        self.connectingCellIndexPath = indexPath;
        SILDebugDeviceTableViewCell *selectedPeripheralCell = [self.devicesTableView cellForRowAtIndexPath:self.connectingCellIndexPath];
        [selectedPeripheralCell startConnectionAnimation];
        [self.activityBarViewController connectingAnimationWithMessage:@"Connecting..."];
        [self updateCellsWithConnecting];
    }
}

#pragma mark - SILPopoverViewControllerDelegate

- (void)didClosePopoverViewController:(SILDebugPopoverViewController *)popoverViewController {
    [self.peripheralPopoverController dismissPopoverAnimated:YES completion:^{
        self.peripheralPopoverController = nil;
    }];
}

#pragma mark - WYPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)popoverController {
    [self.peripheralPopoverController dismissPopoverAnimated:YES completion:nil];
    self.peripheralPopoverController = nil;
}

#pragma mark - SILActivityBarViewControllerDelegate

- (void)activityBarViewControllerDidTapActivityButton:(SILActivityBarViewController *)controller {
    [self.viewModel removeAllDiscoveredPeripherals];
    [self startScanning];
    [self.devicesTableView reloadData];
}

- (void)activityBarViewControllerDidTapStopActivityButton:(SILActivityBarViewController *)controller {
    [self.viewModel stopScanning];
    [self stopScanningForDevices];
}

#pragma mark - Configure Cells

- (void)configureTableViewCell:(SILDebugDeviceTableViewCell *)cell withDiscoveredPeripheral:(SILDiscoveredPeripheral *)discoveredPeripheral atIndexPath:(NSIndexPath *)indexPath {
    NSString *deviceName = discoveredPeripheral.advertisedLocalName ?: @"Unknown";
    NSString *rssi = [discoveredPeripheral.RSSIMeasurementTable.lastRSSIMeasurement stringValue];
    NSString *deviceUUID = discoveredPeripheral.peripheral.identifier.UUIDString;
    cell.displayNameLabel.text = deviceName;
    cell.rssiLabel.text = rssi;
    cell.uuidLabel.text = deviceUUID;
    cell.delegate = self;

    if ([indexPath isEqual:self.connectingCellIndexPath]) {
        [cell startConnectionAnimation];
    } else {
        [cell stopConnectionAnimation];
    }

    BOOL enabled = !self.connectingCellIndexPath || [indexPath isEqual:self.connectingCellIndexPath];
    [cell configureAsOwner:self withIndexPath:indexPath];
    [cell configureAsEnabled:enabled connectable:discoveredPeripheral.isConnectable];
    [cell revealCollectionView];
}

- (UICollectionViewCell *)configureCollectionViewCell:(SILDebugAdvDetailCollectionViewCell *)cell
                      forCollectionView:(UICollectionView *)collectionView
                              forDetail:(SILAdvertisementDataViewModel *)detail
                            atIndexPath:(NSIndexPath *)indexPath {
    cell.infoLabel.text = detail.valueString;
    cell.infoNameLabel.text = detail.typeString;
    return cell;
}

- (void)revealFailedConnectionBar:(CBPeripheral *)failedPeripheral {
    NSString *failedMessage = [NSString stringWithFormat:(@"Failed connecting to %@"), failedPeripheral.name ?: @"Unknown"];
    [self.failedConnectionAlertBarView revealAlertBarWithMessage:failedMessage revealTime:0.4f displayTime:5.0f];
}

#pragma mark - SILDebugDeviceViewModelDelegate

- (void)didConnectToPeripheral:(CBPeripheral *)peripheral {
    SILDebugServicesViewController *servicesViewController = [[SILDebugServicesViewController alloc] init];
    servicesViewController.peripheral = peripheral;
    servicesViewController.centralManager = self.viewModel.centralManager;
    [self updateCellsWithConnecting];
    [self.activityBarViewController configureActivityBarWithState:SILActivityBarStateResting];
    [self removeUnfiredTimers];
    [self.navigationController pushViewController:servicesViewController animated:YES];
}

- (void)didDisconnectFromPeripheral:(CBPeripheral *)peripheral {
    [self updateCellsWithConnecting];
}

- (void)didFailToConnectToPeripheral:(CBPeripheral *)peripheral {
    [self updateCellsWithConnecting];
    [self revealFailedConnectionBar:peripheral];
}

- (void)scanningDidEnd {
    [self stopScanningForDevices];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self detailsForCollectionView:collectionView].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SILAdvertisementDataViewModel* deviceDetail = [self detailsForCollectionView:collectionView][indexPath.row];
    SILDebugAdvDetailCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SILDebugAdvDetailCollectionViewCell class]) forIndexPath:indexPath];
    return [self configureCollectionViewCell:cell forCollectionView:collectionView forDetail:deviceDetail atIndexPath:indexPath];
}

#pragma mark - UICollectionViewFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    SILAdvertisementDataViewModel* deviceDetail = [self detailsForCollectionView:collectionView][indexPath.row];
    UICollectionViewCell *deviceCellCollectionCell = [self configureCollectionViewCell:self.sizingCollectionCell forCollectionView:collectionView forDetail:deviceDetail atIndexPath:indexPath];
    CGSize collectionCellSize = [deviceCellCollectionCell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return collectionCellSize;
}

#pragma mark - Collection View Helpers

- (NSArray *)detailsForCollectionView:(UICollectionView *)collectionView {
    SILDebugAdvDetailsCollectionView *detailsCollectionView = (SILDebugAdvDetailsCollectionView *)collectionView;
    SILDiscoveredPeripheralDisplayDataViewModel *deviceViewModel = [self.viewModel peripheralViewModelAt:detailsCollectionView.parentIndexPath.row];
    return deviceViewModel.advertisementDataViewModelsForDevicesTable;
}

#pragma mark - SILDebugDeviceFilterViewControllerDelegate

- (void)debugDeviceFilterViewControllerDidCancel:(SILDebugDeviceFilterViewController *)viewController {
    [self.filterPopoverController dismissPopoverAnimated:YES completion:^{
        self.filterPopoverController = nil;
    }];
}

- (void)debugDeviceFilterViewControllerDidApplyFilterWithName:(NSString *)name rssi:(NSNumber *)rssi viewController:(SILDebugDeviceFilterViewController *)viewController {
    [self.viewModel setSearchQuery:name minRSSI:rssi];
    self.currentFilterLabel.text = [self.viewModel filterDescription];
    [self refreshTable];
    if ([self.viewModel isFilterApplied]) {
        self.filterBarHeightConstraint.constant = kFilterBarHeightExpanded;
        [self.filterArrowView setHidden:NO];
    } else {
        self.filterBarHeightConstraint.constant = kFilterBarHeightCollapsed;
        [self.filterArrowView setHidden:YES];
    }

    [self.filterPopoverController dismissPopoverAnimated:YES completion:^{
        self.filterPopoverController = nil;
    }];
}

@end
