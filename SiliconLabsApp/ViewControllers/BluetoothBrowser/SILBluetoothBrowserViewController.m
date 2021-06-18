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
#import "BlueGecko.pch"
#import "SILBluetoothBrowser+Constants.h"
#import "SILRefreshImageView.h"
#import "SILRefreshImageModel.h"
#import "UIView+SILShadow.h"

#import "SILExitPopupViewController.h"
#import "SILBrowserSettings.h"

@interface SILBluetoothBrowserViewController () <UITableViewDataSource, UITableViewDelegate, SILBrowserDeviceViewCellDelegate, SILDebugDeviceViewModelDelegate, SILBrowserFilterViewControllerDelegate, SILBrowserConnectionsViewControllerDelegate, SILBrowserLogViewControllerDelegate, WYPopoverControllerDelegate, SILExitPopupViewControllerDelegate, SILSortViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UIView *aboveSpaceAreaView;
@property (weak, nonatomic) IBOutlet UILabel *navigationBarTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *presentationView;
@property (weak, nonatomic) IBOutlet UIView *discoveredDevicesView;
@property (weak, nonatomic) IBOutlet UITableView *browserTableView;
@property (weak, nonatomic) IBOutlet UIButton *logButton;
@property (weak, nonatomic) IBOutlet UIButton *connectionsButton;
@property (weak, nonatomic) IBOutlet UIButton *filterButton;
@property (weak, nonatomic) IBOutlet UIButton *sortButton;
@property (weak, nonatomic) IBOutlet UIButton *scanningButton;
@property (weak, nonatomic) IBOutlet UIImageView *noDevicesFoundImageView;
@property (weak, nonatomic) IBOutlet UIStackView *noDevicesFoundView;
@property (weak, nonatomic) IBOutlet UILabel *noDevicesFoundLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *expandableControllerHeight;
@property (weak, nonatomic) IBOutlet UIView *expandableControllerView;
@property (weak, nonatomic) IBOutlet SILRefreshImageView *refreshImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topRefreshImageConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *filterBarHeight;
@property (weak, nonatomic) IBOutlet SILFilterBarViewController* filterBarViewController;

@property (strong, nonatomic) NSTimer *tableRefreshTimer;
@property (strong, nonatomic) SILDebugDeviceViewModel *browserViewModel;
@property (strong, nonatomic) SILBrowserConnectionsViewModel* connectionsViewModel;
@property (strong, nonatomic) SILBrowserFilterViewModel* filterViewModel;
@property (strong, nonatomic) SILSortViewModel* sortViewModel;
@property (strong, nonatomic) NSIndexPath *connectingCellIndexPath;
@property (nonatomic) BOOL isScanning;
@property (nonatomic) NSMutableArray<NSString*>* expandSections;
@property (nonatomic) SILBluetoothBrowserExpandableViewManager* browserExpandableViewManager;
@property (strong, nonatomic) WYPopoverController *popoverController;
@property (weak, nonatomic) IBOutlet UIView *scanningButtonView;
@property (weak, nonatomic) IBOutlet UIView *topButtonsView;

@end

@implementation SILBluetoothBrowserViewController

NSString* const TitleForScanningButtonDuringScanning = @"Stop Scanning";
NSString* const TitleForScanningButtonWhenIsNotScanning = @"Start Scanning";
long long const ms = 1000;
NSString* const AppendingMS = @" ms";
const float TABLE_FRESH_INTERVAL = 1.0f;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupProperties];
    [self setupNavigationBar];
    [self setupBrowserExpandableViewManager];
    [self setupButtonsTabBar];
    [self setupScanningButton];
    [self setupBrowserViewModel];
    [self installViewModelsForExpandableViews];
    [self setupBackgroundForScanning:YES];
    [self setScanningButtonAppearanceWithScanning:_isScanning];
    [self clearViewModelsForExpandableViews];
    [self setupRefreshImageView];
    [self setupShadows];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.browserViewModel.observing = YES;
    [self manageScannerState];
    [self addObservers];
    [self updateConnectionsButtonTitle];
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
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    [self.browserExpandableViewManager setupFilterBarWithFilterBarHeight:self.filterBarHeight filterBarViewController:self.filterBarViewController];
}
 
- (void)setupButtonsTabBar {
    [self.browserExpandableViewManager setupButtonsTabBarWithLog:self.logButton connections:self.connectionsButton filter:self.filterButton andFilterIsActive:[self.filterViewModel isFilterActive] andSortButton:self.sortButton];
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
    self.connectionsViewModel = [SILBrowserConnectionsViewModel sharedInstance];
    self.filterViewModel = [SILBrowserFilterViewModel sharedInstance];
    self.sortViewModel = [SILSortViewModel sharedInstance];
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
    [self addObserverForDisplayToastResponse];
    [self registerForApplicationWillResignActiveNotification];
}

- (void)addObserversForReloadBrowserTableView {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:SILNotificationReloadBrowserTable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:SILNotificationReloadConnectionsTableView object:nil];
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

- (void)addObserverForDisplayToastResponse {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayToast:) name:SILNotificationDisplayToastResponse object:nil];
}

- (void)displayToast:(NSNotification*)notification {
    NSString* ErrorMessage = notification.userInfo[SILNotificationKeyDescription];
    [self showToastWithMessage:ErrorMessage toastType:ToastTypeDisconnectionError completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationDisplayToastRequest object:nil];
    }];
}

- (void)setupRefreshImageView {
    self.refreshImageView.model = [[SILRefreshImageModel alloc] initWithConstraint:self.topRefreshImageConstraint
                                                                     withEmptyView:self.discoveredDevicesView
                                                                     withTableView:self.browserTableView
                                                                 andWithReloadAction: ^{
                                                                                    [self refreshTableView];
                                                                                    }];
    [self.refreshImageView setup];
}

- (void)setupShadows {
    [self.scanningButtonView addShadow];
    [self.topButtonsView addShadow];
}

- (void)presentDetailsViewControllerWithPeripheral:(CBPeripheral *)peripheral {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserDetails bundle:nil];
    SILBrowserDetailsTabBarController * detailsTabBarController = [storyboard instantiateViewControllerWithIdentifier: @"SILDetailsTabBarController"];
    SILDebugServicesViewController* detailsVC = detailsTabBarController.viewControllers[0];
    detailsVC.peripheral = peripheral;
    detailsVC.centralManager = self.browserViewModel.centralManager;
    SILLocalGattServerViewController* localGattServerVC = detailsTabBarController.viewControllers[1];
    localGattServerVC.peripheral = peripheral;
    localGattServerVC.centralManager = self.browserViewModel.centralManager;
    [self updateCellsWithConnecting:peripheral];
    [self removeUnfiredTimers];
    [self.navigationController pushViewController:detailsTabBarController animated:YES];
}

#pragma mark - SILDebugDeviceViewModelDelegate

- (void)didConnectToPeripheral:(CBPeripheral *)peripheral {
    [self.connectionsViewModel addNewConnectedPeripheral:peripheral];
    [self presentDetailsViewControllerWithPeripheral:peripheral];
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

- (void)bluetoothIsDisabled {
    SILBluetoothDisabledAlertObjc* bluetoothDisabledAlert = [[SILBluetoothDisabledAlertObjc alloc] initWithBluetoothDisabledAlert:SILBluetoothDisabledAlertBrowser];
    [self alertWithOKButtonWithTitle:[bluetoothDisabledAlert getTitle]
                             message:[bluetoothDisabledAlert getMessage]
                          completion:^(UIAlertAction * action) {
                                                            [self stopScanningAndDisconnectAll];
                                                            [self.navigationController popToRootViewControllerAnimated:YES];
    }];
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
        return cell;
    } else {
        SILBrowserDeviceAdTypeViewCell *cell = [tableView
                                           dequeueReusableCellWithIdentifier:SILClassBrowserServiceViewCell
                                           forIndexPath:indexPath];
        [self configureAdTypeCell:cell atIndexPath:indexPath];
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

- (void)configureAdTypeCell:(SILBrowserDeviceAdTypeViewCell*)cell atIndexPath:(NSIndexPath *)indexPath {
    SILDiscoveredPeripheralDisplayDataViewModel *discoveredPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:indexPath.section];
    SILAdvertisementDataViewModel *detailModel = discoveredPeripheralViewModel.advertisementDataViewModelsForInfoView[indexPath.row-1];
    cell.adTypeNameLabel.text = detailModel.typeString;
    cell.adTypeValueLabel.text = detailModel.valueString;
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
    return UITableViewAutomaticDimension;
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
    [UIView setAnimationsEnabled:NO];
    [self.browserTableView beginUpdates];
    [self.browserTableView reloadSections:sections withRowAnimation:UITableViewRowAnimationNone];
    [self.browserTableView fixCellBounds];
    [self.browserTableView endUpdates];
    [UIView setAnimationsEnabled:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [SILTableViewWithShadowCells tableView:tableView willDisplay:cell forRowAt:indexPath];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [SILTableViewWithShadowCells tableView:tableView viewForHeaderInSection:section withHeight: 20.0];
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

- (IBAction)sortButtonWasTapped:(id)sender {
    SILSortViewController* sortVC = [self.browserExpandableViewManager sortButtonWasTappedAction];
    if (sortVC.delegate == nil) {
        sortVC.delegate = self;
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
    BOOL previousState = self.isScanning;
    self.isScanning = !self.isScanning;
    if (previousState) {
        [self stopScanningAction];
    } else {
        [self startScanningAction];
    }
    [self setScanningButtonAppearanceWithScanning:self.isScanning];
}

- (void)stopScanningAction {
    [self.browserViewModel stopScanning];
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
    NSDictionary* userInfo = @{SILNotificationKeyIndex: @(index)};
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

- (void)startScanning {
    [self.browserViewModel startScanning];
    

    self.tableRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:TABLE_FRESH_INTERVAL
                                                              target:self
                                                            selector:@selector(tableRefreshTimerFired)
                                                            userInfo:nil
                                                              repeats:YES];
    [self displayNoDeviceViewIfNeeded];
}

- (void)tableRefreshTimerFired {
    [self refreshTable];
    [self displayNoDeviceViewIfNeeded];
}

- (void)displayNoDeviceViewIfNeeded {
    [self setupBackgroundForScanning:self.isScanning];
    if (self.browserViewModel.isContentAvailable) {
        self.browserTableView.hidden = NO;
        [self.noDevicesFoundView setHidden:YES];
    } else {
        [self.browserTableView setHidden:YES];
        [self.noDevicesFoundView setHidden:NO];
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
    [self.browserExpandableViewManager updateFilterBarWith:filterViewModel];
    [self displayNoDeviceViewIfNeeded];
}

- (void)manageAppearanceOfActiveFilterImage:(SILBrowserFilterViewModel*)filterViewModel {
    [self.browserExpandableViewManager updateFilterIsActiveFilter:[filterViewModel isFilterActive]];
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
     self.browserViewModel.currentMinRSSI = [NSNumber numberWithInteger:filterViewModel.dBmValue];
     self.browserViewModel.beaconTypes = filterViewModel.beaconTypes;
     self.browserViewModel.isFavourite = filterViewModel.isFavouriteFilterSet;
     self.browserViewModel.isConnectable = filterViewModel.isConnectableFilterSet;
}

- (void)resetFilters {
    self.browserViewModel.searchByDeviceName = nil;
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
    SILConnectedPeripheralDataModel* connectedPeripheral = self.connectionsViewModel.peripherals[index];
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
    [self presentDetailsViewControllerWithPeripheral:connectedPeripheral.peripheral];
}

#pragma mark - SILBrowserLogViewControllerDelegate

- (void)logViewBackButtonPressed {
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
}

- (IBAction)backToDevelopWasTapped:(id)sender {
    [self stopScanningAndDisconnectAll];
}

- (void)stopScanningAndDisconnectAll {
    [self stopScanningAction];
    [self.sortViewModel deselectSelectedOption];
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark = SILSortViewControllerDelegate

- (void)sortOptionWasSelectedWithOption:(SILSortOption)option {
    self.browserViewModel.sortOption = option;
    [self.browserExpandableViewManager changeImagesOfSortButtonForOption:option];
}

#pragma mark - WYPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)popoverController {
    [self dismissPopoverViewController];
}

#pragma mark = SILExitPopupViewControllerDelegate

- (void)cancelWasTappedInExitPopup {
    [self dismissPopoverViewController];
}

- (void)okWasTappedInExitPopupWithSwitchState:(BOOL)state {
    [SILBrowserSettings setDisplayExitWarningPopup:state];
    [self.popoverController dismissPopoverAnimated:YES completion: ^{
        self.popoverController = nil;
        [self stopScanningAndDisconnectAll];
    }];
}

- (void)dismissPopoverViewController {
    [self.popoverController dismissPopoverAnimated:YES completion:nil];
    self.popoverController = nil;
}

- (void)clearViewModelsForExpandableViews {
    [self.filterViewModel clearViewModelData];
    SILBrowserLogViewModel* browserLog = [SILBrowserLogViewModel sharedInstance];
    [browserLog clearLogs];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.y < 0) {
        scrollView.contentOffset = CGPointZero;
    } else {
        [self.browserTableView setScrollEnabled:YES];
    }
}

- (void)refreshTableView {
    [self.browserViewModel stopScanning];
    [self removeUnfiredTimers];
    [self.browserViewModel removeAllDiscoveredPeripherals];
    [self reloadTable];
    [self.noDevicesFoundView setHidden:NO];
    self.isScanning = YES;
    [self setScanningButtonAppearanceWithScanning:self.isScanning];
    [self startScanning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self getInstanceOfFilterBarViewController:segue];
}

- (void)getInstanceOfFilterBarViewController:(UIStoryboardSegue*)segue {
    if ([segue.identifier isEqual:@"filterBarViewController"]) {
        self.filterBarViewController = (SILFilterBarViewController*)segue.destinationViewController;
        self.filterBarViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    }
}

@end
