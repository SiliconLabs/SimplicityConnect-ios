//
//  SILBluetoothBrowserViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 30/12/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

#import "SILBluetoothBrowserViewController.h"
#import "SILBrowserFilterViewController.h"
#import "SILBrowserFilterViewControllerDelegate.h"
#import "SILBrowserConnectionsViewController.h"
#import "SILBrowserConnectionsViewControllerDelegate.h"
#import "SILBrowserLogViewController.h"
#import "SILBrowserLogViewControllerDelegate.h"
#import "SILDebugServicesViewController.h"
#import "SILDiscoveredPeripheralDisplayDataViewModel.h"
#import "SILDiscoveredPeripheralDisplayData.h"
#import "SILDiscoveredPeripheral.h"
#import "SILAdvertisementDataViewModel.h"
#import "SILBrowserFilterViewModel.h"
#import "SILBrowserConnectionsViewModel.h"
#import "UIImage+SILImages.h"
#import "UIColor+SILColors.h"
#import "SILBrowserLogViewModel.h"
#import "NSString+SILBrowserNotifications.h"
#import "SILBluetoothBrowser+Constants.h"
#import "SILStoryboard+Constants.h"
#import "SILBluetoothBrowserExpandableViewManager.h"
#import "BlueGecko.pch"
#import "SILBluetoothBrowser+Constants.h"

@interface SILBluetoothBrowserViewController () <UITableViewDataSource, UITableViewDelegate, SILBrowserDeviceViewCellDelegate, SILDebugDeviceViewModelDelegate, SILBrowserFilterViewControllerDelegate, SILBrowserConnectionsViewControllerDelegate, SILBrowserLogViewControllerDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UIView *aboveSpaceAreaView;
@property (weak, nonatomic) IBOutlet UILabel *navigationBarTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *presentationView;
@property (weak, nonatomic) IBOutlet UIView *discoveredDevicesView;
@property (weak, nonatomic) IBOutlet UITableView *browserTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * tableLeftInset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * tableRightInset;
@property (weak, nonatomic) IBOutlet UIButton *logButton;
@property (weak, nonatomic) IBOutlet UIButton *connectionsButton;
@property (weak, nonatomic) IBOutlet UIButton *filterButton;
@property (weak, nonatomic) IBOutlet UIImageView *activeFilterImage;
@property (weak, nonatomic) IBOutlet UIButton *scanningButton;
@property (weak, nonatomic) IBOutlet UIImageView *noDevicesFoundImageView;
@property (weak, nonatomic) IBOutlet UIStackView *noDevicesFoundView;
@property (weak, nonatomic) IBOutlet UILabel *noDevicesFoundLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *expandableControllerHeight;
@property (weak, nonatomic) IBOutlet UIView *expandableControllerView;

@property (strong, nonatomic) NSTimer *tableRefreshTimer;
@property (strong, nonatomic) SILDebugDeviceViewModel *browserViewModel;
@property (strong, nonatomic) SILBrowserConnectionsViewModel* connectionsViewModel;
@property (strong, nonatomic) NSIndexPath *connectingCellIndexPath;
@property (nonatomic) BOOL isScanning;
@property (nonatomic) NSMutableArray<NSString*>* expandSections;
@property (nonatomic) SILBluetoothBrowserExpandableViewManager* browserExpandableViewManager;

@end

@implementation SILBluetoothBrowserViewController

NSString* const TitleForScanningButtonDuringScanning = @"Stop Scanning";
NSString* const TitleForScanningButtonWhenIsNotScanning = @"Start Scanning";
long long const ms = 1000;
NSString* const AppendingMS = @" ms";
const float TABLE_FRESH_INTERVAL = 2.0f;
CGFloat const tableInset = 16;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupProperties];
    [self setupNavigationBar];
    [self setupBrowserExpandableViewManager];
    [self setupButtonsTabBar];
    [self setupScanningButton];
    [self registerForApplicationWillResignActiveNotification];
    [self setupBrowserViewModel];
    [self installViewModelsForExpandableViews];
    [self setupBackgroundForScanning:YES];
    [self setScanningButtonAppearanceWithScanning:_isScanning];
    [self addObservers];
    [self updateConnectionsButtonTitle];
    [self setupBrowserTableViewAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.browserViewModel.observing = YES;
    [self manageScannerState];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.connectionsViewModel connectionsViewOnDetailsScreen:NO];
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
    self.browserViewModel.connectedPeripheral = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.browserViewModel.observing = NO;
    [self setScannerStateWhenControllerIsDisappeared];
    [self.browserViewModel clearIsConnectingDirectory];
}

#pragma mark - Setup

- (void)setupProperties {
    self.isScanning = YES;
    self.cornerRadius = CornerRadiusStandardValue;
    self.expandSections = [[NSMutableArray alloc] init];
}

- (void)setupNavigationBar {
    [self setupNavigationBarBackgroundColor];
    [self setupNavigationBarTitle];
}

- (void)setupBrowserTableViewAppearance {
    if (@available(iOS 13, *)) {
        self.tableLeftInset.constant = 0;
        self.tableRightInset.constant = 0;
        self.browserTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        self.tableLeftInset.constant = tableInset;
        self.tableRightInset.constant = tableInset;
    }
}

- (void)setupNavigationBarBackgroundColor {
    self.navigationBarView.backgroundColor = [UIColor sil_siliconLabsRedColor];
    self.aboveSpaceAreaView.backgroundColor = [UIColor sil_siliconLabsRedColor];
}

- (void)setupNavigationBarTitle {
    self.navigationBarTitleLabel.font = [UIFont robotoMediumWithSize:SILNavigationBarTitleFontSize];
    self.navigationBarTitleLabel.textColor = [UIColor sil_backgroundColor];
}

- (void)setupBrowserExpandableViewManager {
    self.browserExpandableViewManager = [[SILBluetoothBrowserExpandableViewManager alloc] initWithOwnerViewController:self];
    [self.browserExpandableViewManager setReferenceForPresentationView:self.presentationView andDiscoveredDevicesView:self.discoveredDevicesView];
    [self.browserExpandableViewManager setReferenceForExpandableControllerView:self.expandableControllerView andExpandableControllerHeight:self.expandableControllerHeight];
    [self.browserExpandableViewManager setValueForCornerRadius:self.cornerRadius];
}
 
- (void)setupButtonsTabBar {
    [self.browserExpandableViewManager setupButtonsTabBarWithLog:self.logButton connections:self.connectionsButton filter:self.filterButton andActiveFilterImage:self.activeFilterImage];
}

- (void)setupScanningButton {
    self.scanningButton.titleLabel.font = [UIFont robotoMediumWithSize:SILScanningButtonTitleFontSize];
    self.scanningButton.titleLabel.textColor = [UIColor sil_backgroundColor];
    self.scanningButton.layer.cornerRadius = CornerRadiusForButtons;
}

- (void)registerForApplicationWillResignActiveNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)setupBrowserViewModel {
    self.browserViewModel = [[SILDebugDeviceViewModel alloc] init];
    self.browserViewModel.delegate = self;
}

- (void)installViewModelsForExpandableViews {
    SILBrowserLogViewModel* browserLog = [SILBrowserLogViewModel sharedInstance];
    self.connectionsViewModel = [SILBrowserConnectionsViewModel sharedInstance];
    self.connectionsViewModel.centralManager = self.browserViewModel.centralManager;
    [self.connectionsViewModel disconnectAllPeripheral];
    [browserLog clearLogs];
}

- (void)setupBackgroundForScanning:(BOOL)scanning {
    NSString * const ImageName = SILImageLoading;
    NSString * const ActiveScanningText = @"Looking for nearby devices...";
    NSString * const DisableScanningTect = @"No devices found";
    NSString* text = scanning ? ActiveScanningText : DisableScanningTect;
    self.noDevicesFoundLabel.text = text;
    self.noDevicesFoundImageView.image = [UIImage imageNamed:ImageName];
}

- (void)addObservers {
    [self addObserversForReloadBrowserTableView];
    [self addObserverForReloadConnectionsButtonTitle];
}

- (void)addObserversForReloadBrowserTableView {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:SILNotificationReloadBrowserTable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:SILNotificationReloadConnectionsTableView object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cellsForVisibleRows) name: SILNotificationCellsForVisibleRows object:nil];
}

- (void)reloadTable {
    [self.browserTableView reloadData];
}

- (void)addObserverForReloadConnectionsButtonTitle {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionsButtonTitle) name:SILNotificationReloadConnectionsTableView object:nil];
}

- (void)updateConnectionsButtonTitle {
    NSUInteger connections = [self.connectionsViewModel.peripherals count];
    [self.browserExpandableViewManager updateConnectionsButtonTitle:connections];
}

#pragma mark - SILDebugDeviceViewModelDelegate

- (void)didConnectToPeripheral:(CBPeripheral *)peripheral {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserDetails bundle:nil];
    SILDebugServicesViewController* detailsVC = [storyboard instantiateViewControllerWithIdentifier:SILSceneConnectedDevice];
    detailsVC.peripheral = peripheral;
    detailsVC.centralManager = self.browserViewModel.centralManager;
    [self updateCellsWithConnecting:peripheral];
    [self removeUnfiredTimers];
    [self.connectionsViewModel addNewConnectedPeripheral:peripheral];
    [self.navigationController pushViewController:detailsVC animated:YES];
}

- (void)didDisconnectFromPeripheral:(CBPeripheral *)peripheral {
    [self updateCellsWithConnecting:peripheral];
}

- (void)didFailToConnectToPeripheral:(CBPeripheral *)peripheral {
    [self updateCellsWithConnecting:peripheral];
}

- (void)scanningDidEnd {
    [self stopScanningForDevices];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.browserViewModel.discoveredPeripheralsViewModels.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SILDiscoveredPeripheralDisplayDataViewModel *discoveredPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:section];
    NSString* identifier = discoveredPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.identityKey;
    
    if ([self.expandSections containsObject:identifier]) {
        return self.browserViewModel.discoveredPeripheralsViewModels[section].advertisementDataViewModelsForInfoView.count + 1;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        SILBrowserDeviceViewCell * cell = [tableView
                                           dequeueReusableCellWithIdentifier:SILClassBrowserDeviceViewCell
                                           forIndexPath:indexPath];
        [self configureDeviceCell:cell atIndexPath:indexPath];
        if (@available(iOS 13, *)) {} else {
            if ([tableView numberOfRowsInSection:indexPath.section] > 1) {
                cell.isRounded = YES;
                cell.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
            }
        }
        return cell;
    } else {
        SILBrowserServiceViewCell *cell = [tableView
                                           dequeueReusableCellWithIdentifier:SILClassBrowserServiceViewCell
                                           forIndexPath:indexPath];
        [self configureServiceCell:cell atIndexPath:indexPath];
        if (@available(iOS 13, *)) {} else {
            if ([tableView numberOfRowsInSection:indexPath.section]-1 == indexPath.row) {
                cell.isRounded = YES;
                cell.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            } else {
                cell.isRounded = NO;
            }
        }
        return cell;
    }
}

- (void)configureDeviceCell:(SILBrowserDeviceViewCell*)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.delegate = self;
    SILDiscoveredPeripheralDisplayDataViewModel *discoveredPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:indexPath.section];
    NSString* cellIdentifier = discoveredPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.identityKey;
    cell.cellIdentifier = cellIdentifier;
    SILDiscoveredPeripheral *discoveredPeripheral = discoveredPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral;
    NSString *deviceName = discoveredPeripheral.advertisedLocalName;
    cell.rssiLabel.text = discoveredPeripheral.rssiDescription;
    cell.title.text = deviceName;
    if ([deviceName isEqualToString:EmptyText] || deviceName == nil) {
        cell.title.text = DefaultDeviceName;
    }
    
    cell.uuidLabel.text = discoveredPeripheral.uuid.UUIDString;
    long long advertisingIntervalsInMS = discoveredPeripheral.advertisingInterval * ms;
    
    NSMutableString* advertisingIntervalText = [NSMutableString stringWithFormat:@"%lld", advertisingIntervalsInMS];
    [advertisingIntervalText appendString:AppendingMS];
    
    cell.advertisingIntervalLabel.text = advertisingIntervalText;
    
    if (discoveredPeripheral.isConnectable) {
        cell.connectableLabel.text = SILDiscoveredPeripheral.connectableDevice;
        if ([self isConnectedPeripheral:discoveredPeripheral]) {
            [cell setDisconnectButtonAppearance];
        } else {
            [cell setConnectButtonAppearance];
        }
    } else {
        cell.connectableLabel.text = SILDiscoveredPeripheral.nonConnectableDevice;
        [cell setHiddenButtonAppearance];
    }
    cell.beaconLabel.text = discoveredPeripheral.beacon.name;

    if (discoveredPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite) {
        [cell.favouritesButton setSelected:YES];
    }
    
    if (discoveredPeripheral.peripheral != nil) {
        if ([self.browserViewModel containPeripheral:discoveredPeripheral.peripheral]) {
            [cell.connectingIndicator setHidden:NO];
            [cell.connectingIndicator startAnimating];
        }
    }
}

- (void)configureServiceCell:(SILBrowserServiceViewCell*)cell atIndexPath:(NSIndexPath *)indexPath {
    SILDiscoveredPeripheralDisplayDataViewModel *discoveredPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:indexPath.section];
    SILAdvertisementDataViewModel *detailModel = discoveredPeripheralViewModel.advertisementDataViewModelsForInfoView[indexPath.row-1];
    cell.serviceNameLabel.text = detailModel.typeString;
    cell.serviceUUIDLabel.text = detailModel.valueString;
}

- (BOOL)isConnectedPeripheral:(SILDiscoveredPeripheral*)peripheral {
    for (SILConnectedPeripheralDataModel* connectedPeripheral in self.connectionsViewModel.peripherals) {
        if ([peripheral.peripheral.identifier.UUIDString isEqualToString:connectedPeripheral.peripheral.identifier.UUIDString]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSInteger)isConnectedPeripheralWithIndex:(SILDiscoveredPeripheral*)peripheral {
    NSInteger index = 0;
    for (SILConnectedPeripheralDataModel* connectedPeripheral in self.connectionsViewModel.peripherals) {
        if ([peripheral.peripheral.identifier.UUIDString isEqualToString:connectedPeripheral.peripheral.identifier.UUIDString]) {
            return index;
        }
        index++;
    }
    
    return NoDeviceFoundedIndex;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 121.0;
    }
    return 76.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 16.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SILDiscoveredPeripheralDisplayDataViewModel *selectedPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:indexPath.section];
    NSString* identifier = selectedPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.identityKey;
    if ([self.expandSections containsObject:identifier]) {
        [self.expandSections removeObject:identifier];
    } else {
        [self.expandSections addObject:identifier];
    }
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:indexPath.section];
    [self.browserTableView beginUpdates];
    [self.browserTableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.browserTableView endUpdates];
}

#pragma mark - Expandable Controllers

- (IBAction)filterButtonTapped:(id)sender {
    SILBrowserFilterViewController* filterVC = [self.browserExpandableViewManager filterButtonWasTappedAction];
    if (filterVC.delegate == nil) {
        filterVC.delegate = self;
    }
}

- (IBAction)connectionsButtonTapped:(id)sender {
    SILBrowserConnectionsViewController* connectionsVC = [self.browserExpandableViewManager connectionsButtonWasTappedAction];
    if (connectionsVC.delegate == nil) {
        connectionsVC.delegate = self;
    }
}

- (IBAction)logButtonWasTapped:(id)sender {
    SILBrowserLogViewController* logVC = [self.browserExpandableViewManager logButtonWasTappedAction];
    if (logVC.delegate == nil) {
        logVC.delegate = self;
    }
}

#pragma mark - Scanning

- (void)setScanningButtonAppearanceWithScanning:(BOOL)isScanning {
    if (isScanning) {
        [self setStopScanningButton];
    } else {
        [self setStartScanningButton];
    }
}

- (void)setStopScanningButton {
    self.scanningButton.backgroundColor = [UIColor sil_siliconLabsRedColor];
    [self.scanningButton setTitle:TitleForScanningButtonDuringScanning forState:UIControlStateNormal];
}

- (void)setStartScanningButton {
    self.scanningButton.backgroundColor = [UIColor sil_regularBlueColor];
    [self.scanningButton setTitle:TitleForScanningButtonWhenIsNotScanning forState:UIControlStateNormal];
}

- (IBAction)scanningButtonWasTapped:(id)sender {
    if (self.isScanning) {
        [self stopScanningAction];
    } else {
        [self startScanningAction];
    }
    self.isScanning = !self.isScanning;
    [self setScanningButtonAppearanceWithScanning:self.isScanning];
}

- (void)stopScanningAction {
    [self.browserViewModel stopScanningWithVisibleCellsCount:[self.browserTableView visibleCells].count];
    [self stopScanningForDevices];
}

- (void)startScanningAction {
    [self startScanning];
}

- (void)manageScannerState {
    if (self.isScanning) {
        [self startScanningAction];
    } else {
        [self stopScanningAction];
    }
}

- (void)setScannerStateWhenControllerIsDisappeared {
    [self stopScanningAction];
    self.isScanning = NO;
    [self setScanningButtonAppearanceWithScanning:self.isScanning];
}

#pragma mark - SILBrowserDeviceViewCellDelegate

- (void)favouriteButtonTappedInCell:(SILBrowserDeviceViewCell*)cell {
    NSIndexPath *indexPath = [self.browserTableView indexPathForCell:cell];
    SILDiscoveredPeripheralDisplayDataViewModel *discoveredPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:indexPath.section];
    if (discoveredPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.isFavourite) {
        [SILFavoritePeripheral remove:discoveredPeripheralViewModel];
    } else {
        [SILFavoritePeripheral add:discoveredPeripheralViewModel];
    }
    [self refreshTable];
}

- (void)connectViewButtonTappedInCell:(SILBrowserDeviceViewCell*)cell {
    NSIndexPath *indexPath = [self.browserTableView indexPathForCell:cell];
    SILDiscoveredPeripheralDisplayDataViewModel *selectedPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:indexPath.section];
    
    NSInteger index = [self isConnectedPeripheralWithIndex:selectedPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral];
    
    if (index != NoDeviceFoundedIndex) {
        [self postNotificationToViewModel:index];
    } else {
        if ([self.browserViewModel connectTo:selectedPeripheralViewModel]) {
            self.connectingCellIndexPath = indexPath;
            [cell.connectingIndicator setHidden:NO];
            [cell.connectingIndicator startAnimating];
        }
    }
}

- (void)postNotificationToViewModel:(NSInteger)index {
    NSString* indexString = [NSString stringWithFormat:@"%luld", (unsigned long)index];
    NSDictionary* userInfo = @{SILNotificationKeyIndex: indexString};
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationDisconnectPeripheral object:self userInfo:userInfo];
}

#pragma mark - Notifcation Methods

- (void)applicationWillResignActive:(NSNotification*)notification {
    [self setScannerStateWhenControllerIsDisappeared];
}

- (void)updateCellsWithConnecting:(CBPeripheral*)peripheral {
    if (![self.browserViewModel containPeripheral:peripheral]) {
        SILBrowserDeviceViewCell *cell = [self.browserTableView cellForRowAtIndexPath:self.connectingCellIndexPath];
        [cell.connectingIndicator stopAnimating];
        [cell.connectingIndicator setHidden:YES];
        self.connectingCellIndexPath = nil;
    } else {
        SILBrowserDeviceViewCell *cell = [self.browserTableView cellForRowAtIndexPath:self.connectingCellIndexPath];
        [cell.connectingIndicator setHidden:NO];
        [cell.connectingIndicator startAnimating];
    }

    [self.browserTableView reloadData];
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

- (void)stopScanningForDevices {
    [self removeUnfiredTimers];
    if (self.browserViewModel.discoveredPeripheralsViewModels.count == 0) {
        [self setupBackgroundForScanning:NO];
    }
    [self refreshTable];
}

- (void)refreshTable {
    [self.browserViewModel refreshDiscoveredPeripheralViewModels];
    [self.browserTableView reloadData];
}

- (void)cellsForVisibleRows {
    [self.browserTableView beginUpdates];
    for (NSIndexPath* indexPath in [self.browserTableView indexPathsForVisibleRows]) {
            [self.browserTableView cellForRowAtIndexPath:indexPath];
    }
    [self.browserTableView endUpdates];
}

- (void)startScanning {
    [self.browserViewModel startScanning];

    self.tableRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:TABLE_FRESH_INTERVAL
                                                              target:self
                                                            selector:@selector(tableRefreshTimerFired)
                                                            userInfo:nil
                                                              repeats:YES];
    if (self.browserViewModel.isContentAvailable == NO) {
        self.browserTableView.hidden = YES;
    }
    [self setupBackgroundForScanning:YES];
}

- (void)tableRefreshTimerFired {
    if (self.browserViewModel.isContentAvailable) {
        self.browserTableView.hidden = NO;
        [self.noDevicesFoundView setHidden:YES];
        [self refreshTable];
    }
}

#pragma mark - SILBrowserFilterViewControllerDelegate

- (void)backButtonWasTapped {
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
}

- (void)searchButtonWasTapped:(SILBrowserFilterViewModel *)filterViewModel {
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
    [self manageAppearanceOfActiveFilterImage:filterViewModel];
    [self filterBrowser:filterViewModel];
}

- (void)manageAppearanceOfActiveFilterImage:(SILBrowserFilterViewModel*)filterViewModel {
    if ([filterViewModel isFilterActive]) {
        [self.activeFilterImage setHidden:NO];
    } else {
        [self.activeFilterImage setHidden:YES];
    }
}

- (void)filterBrowser:(SILBrowserFilterViewModel*)filterViewModel {
    if ([filterViewModel isFilterActive]) {
        [self setFilters:filterViewModel];
    } else {
        [self resetFilters];
    }
}

- (void)setFilters:(SILBrowserFilterViewModel*)filterViewModel {
    if (![filterViewModel.searchByDeviceName isEqualToString:EmptyText]) {
         self.browserViewModel.searchByDeviceName = filterViewModel.searchByDeviceName;
     } else {
         self.browserViewModel.searchByDeviceName = nil;
     }
     if (![filterViewModel.searchByRawAdvertisingData isEqualToString:EmptyText]) {
         self.browserViewModel.searchByAdvertisingData = filterViewModel.searchByRawAdvertisingData;
     } else {
         self.browserViewModel.searchByAdvertisingData = nil;
     }
     self.browserViewModel.currentMinRSSI = [NSNumber numberWithInteger:filterViewModel.dBmValue];
     self.browserViewModel.beaconTypes = filterViewModel.beaconTypes;
     self.browserViewModel.isFavourite = filterViewModel.isFavouriteFilterSet;
     self.browserViewModel.isConnectable = filterViewModel.isConnectableFilterSet;
}

- (void)resetFilters {
    self.browserViewModel.searchByDeviceName = nil;
    self.browserViewModel.searchByAdvertisingData = nil;
    self.browserViewModel.currentMinRSSI = nil;
    self.browserViewModel.beaconTypes = nil;
    self.browserViewModel.isFavourite = nil;
    self.browserViewModel.isConnectable = nil;
}

#pragma mark - SILBrowserConnectionsViewControllerDelegate

- (void)connectionsViewBackButtonPressed {
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
}

- (void)presentDetailsViewControllerForIndex:(NSInteger)index {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserDetails bundle:nil];
    SILDebugServicesViewController* detailsVC = [storyboard instantiateViewControllerWithIdentifier:SILSceneConnectedDevice];
    SILConnectedPeripheralDataModel* connectedPeripheral = self.connectionsViewModel.peripherals[index];
    detailsVC.peripheral = connectedPeripheral.peripheral;
    detailsVC.centralManager = self.browserViewModel.centralManager;
    [self updateCellsWithConnecting:connectedPeripheral.peripheral];
    [self removeUnfiredTimers];
    [self.navigationController pushViewController:detailsVC animated:YES];
}

#pragma mark - SILBrowserLogViewControllerDelegate

- (void)logViewBackButtonPressed {
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
}

- (IBAction)backToDevelopWasTapped:(id)sender {
    [self stopScanningAction];
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self isSignificatantScrollToTop:scrollView]) {
        [self.browserViewModel stopScanningWithVisibleCellsCount:0];
        [self removeUnfiredTimers];
        [self.browserViewModel removeAllDiscoveredPeripherals];
        [self reloadTable];
        [self.noDevicesFoundView setHidden:NO];
        self.isScanning = YES;
        [self setScanningButtonAppearanceWithScanning:self.isScanning];
        [self setupBackgroundForScanning:YES];
        [self startScanning];
    }
}

- (BOOL)isSignificatantScrollToTop:(UIScrollView*)scrollView {
    NSInteger SignificantVerticalChangeValue = -50;
    NSInteger StateChanged = 0;
    return scrollView.contentOffset.y <= SignificantVerticalChangeValue && scrollView.panGestureRecognizer.state != StateChanged;
}

@end
