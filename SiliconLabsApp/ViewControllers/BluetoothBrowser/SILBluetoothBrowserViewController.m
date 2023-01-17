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

@interface SILBluetoothBrowserViewController () <UITableViewDataSource, UITableViewDelegate, SILBrowserDeviceViewCellDelegate, SILDebugDeviceViewModelDelegate, SILBrowserFilterViewControllerDelegate, WYPopoverControllerDelegate, SILExitPopupViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *presentationView;
@property (weak, nonatomic) IBOutlet UIView *discoveredDevicesView;
@property (weak, nonatomic) IBOutlet UITableView *browserTableView;
@property (weak, nonatomic) IBOutlet UIImageView *noDevicesFoundImageView;
@property (weak, nonatomic) IBOutlet UIStackView *noDevicesFoundStackView;
@property (weak, nonatomic) IBOutlet UILabel *noDevicesFoundLabel;
@property (weak, nonatomic) IBOutlet SILRefreshImageView *refreshImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topRefreshImageConstraint;

@property (strong, nonatomic) NSTimer *tableRefreshTimer;
@property (strong, nonatomic) SILDebugDeviceViewModel *browserViewModel;
@property (strong, nonatomic) SILBrowserConnectionsViewModel* connectionsViewModel;
@property (strong, nonatomic) SILBrowserFilterViewModel* filterViewModel;
@property (strong, nonatomic) SILSortViewModel* sortViewModel;
@property (strong, nonatomic) NSIndexPath *connectingCellIndexPath;
@property (nonatomic) BOOL isScanning;
@property (nonatomic) NSMutableArray<NSString*>* expandSections;
@property (strong, nonatomic) WYPopoverController *popoverController;
@property (nonatomic, weak) FloatingButtonSettings *floatingButtonSettings;

@end

@implementation SILBluetoothBrowserViewController

NSString* const TitleForScanningButtonDuringScanning = @"Stop Scanning";
NSString* const TitleForScanningButtonWhenIsNotScanning = @"Start Scanning";
long long const ms = 1000;
const float TABLE_FRESH_INTERVAL = 1.0f;

- (void)viewDidLoad {
    self.filterIsSelected = NO;
    [super viewDidLoad];
    [self setupProperties];
    [self setupBrowserViewModel];
    [self installViewModelsForExpandableViews];
    [self clearViewModelsForExpandableViews];
    [self setupRefreshImageView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupBackgroundForScanning:YES];
    self.browserViewModel.observing = YES;
    [self manageScannerState];
    [self addObservers];
    [self updateConnectionsButtonTitle];
    [self setScanningButtonAppearanceWithScanning:_isScanning];
    [self applyFiltersButtonWasTapped:SILBrowserFilterViewModel.sharedInstance];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.connectionsViewModel connectionsViewOnDetailsScreen:NO];
    self.browserViewModel.connectedPeripheral = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.browserViewModel.observing = NO;
    [self setScannerStateWhenControllerIsDisappeared];
    [self.browserViewModel clearIsConnectingDirectory];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setupProperties {
    self.isScanning = YES;
    self.cornerRadius = CornerRadiusStandardValue;
    self.expandSections = [[NSMutableArray alloc] init];
    self.noDevicesFoundStackView.layer.cornerRadius = CornerRadiusStandardValue;
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
    //TODO: Update Active connections amount in Scanner Tab
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
                                                                     withEmptyView:self.view
                                                                     withTableView:self.browserTableView
                                                                 andWithReloadAction: ^{
                                                                                    [self refreshTableView];
                                                                                    }];
    [self.refreshImageView setup];
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

- (void)didFailToConnectToPeripheral:(CBPeripheral * _Nullable)peripheral peerRemovedPairingInformation:(BOOL)peerRemovedPairingInformation {
    [self updateCellsWithConnecting:peripheral];
    if (peerRemovedPairingInformation) {
        [self alertWithOKButtonWithTitle:@"Error"
                                 message:@"The peripheral can't be connected because of peripheral has removed pairing information. Please go to the Settings of your device and remove the pair with peripheral, then try to connect again."
                              completion:nil];
    }
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
     NSString* identifier = discoveredPeripheralViewModel.discoveredPeripheral.identityKey;
     
     if ([self.expandSections containsObject:identifier]) {
         return discoveredPeripheralViewModel.advertisementDataViewModels.count + 1;
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
    NSString* cellIdentifier = discoveredPeripheralViewModel.discoveredPeripheral.identityKey;
    cell.cellIdentifier = cellIdentifier;
    SILDiscoveredPeripheral *discoveredPeripheral = discoveredPeripheralViewModel.discoveredPeripheral;
    NSString *deviceName = discoveredPeripheral.advertisedLocalName;
    cell.rssiLabel.text = discoveredPeripheral.rssiDescription;
    cell.title.text = deviceName;
    if ([deviceName isEqualToString:EmptyText] || deviceName == nil) {
        cell.title.text = DefaultDeviceName;
    }
    
    BOOL isExpanded = [self.expandSections containsObject:cellIdentifier];
    [cell setExpanded:isExpanded];
    
    cell.uuidLabel.text = discoveredPeripheral.uuid.UUIDString;
    long long advertisingIntervalsInMS = discoveredPeripheral.advertisingInterval * ms;
    
    NSMutableString* advertisingIntervalText = [NSMutableString stringWithFormat:@"%lld", advertisingIntervalsInMS];
    [advertisingIntervalText appendString:AppendingMS];
    
    cell.advertisingIntervalLabel.text = advertisingIntervalText;
    
    if (discoveredPeripheral.isConnectable) {
        cell.connectableLabel.text = SILDiscoveredPeripheralConnectableDevice;
        if ([self isConnectedPeripheral:discoveredPeripheral]) {
            [cell setDisconnectButtonAppearance];
        } else {
            [cell setConnectButtonAppearance];
        }
    } else {
        cell.connectableLabel.text = SILDiscoveredPeripheralNonConnectableDevice;
        [cell setHiddenButtonAppearance];
    }
    cell.beaconLabel.text = discoveredPeripheral.beacon.name;

    if (discoveredPeripheralViewModel.discoveredPeripheral.isFavourite) {
        [cell.favouritesButton setSelected:YES];
    }else {
        [cell.favouritesButton setSelected:NO];
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
    
    NSArray<SILAdvertisementDataViewModel *> *viewModels = discoveredPeripheralViewModel.advertisementDataViewModels;
    SILAdvertisementDataViewModel *adViewDataModel = indexPath.row <= viewModels.count ? viewModels[indexPath.row-1] : nil;

    cell.adTypeNameLabel.text = adViewDataModel.typeString;
    cell.adTypeValueLabel.text = adViewDataModel.valueString;
}

- (BOOL)isConnectedPeripheral:(SILDiscoveredPeripheral*)peripheral {
    for (SILConnectedPeripheralDataModel* connectedPeripheral in self.connectionsViewModel.peripherals) {
        if ([peripheral.peripheral.identifier.UUIDString isEqualToString:connectedPeripheral.discoveredPeripheral.peripheral.identifier.UUIDString]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSInteger)isConnectedPeripheralWithIndex:(SILDiscoveredPeripheral*)peripheral {
    NSInteger index = 0;
    for (SILConnectedPeripheralDataModel* connectedPeripheral in self.connectionsViewModel.peripherals) {
        if ([peripheral.peripheral.identifier.UUIDString isEqualToString:connectedPeripheral.discoveredPeripheral.peripheral.identifier.UUIDString]) {
            return index;
        }
        index++;
    }
    
    return NoDeviceFoundedIndex;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 160.0;
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 12.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SILDiscoveredPeripheralDisplayDataViewModel *selectedPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:indexPath.section];
    NSString* identifier = selectedPeripheralViewModel.discoveredPeripheral.identityKey;
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [self numberOfSectionsInTableView:tableView] - 1 == section ? [SILTableViewWithShadowCells tableView:tableView viewForFooterInSection:section withHeight:LastFooterHeight] : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self numberOfSectionsInTableView:tableView] - 1 == section ? LastFooterHeight : 0;
}

#pragma mark - Expandable Controllers

- (void)filterButtonTapped {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserHome bundle:nil];
    SILBrowserFilterViewController *filterVC = [storyboard instantiateViewControllerWithIdentifier:SILSceneFilter];
    
    if (filterVC.delegate == nil) {
        filterVC.delegate = self;
    }
    
    [self presentViewController:filterVC animated:YES completion:nil];
}

- (void)sortButtonTapped {
    [self sortRSSI];
}

- (void)sortRSSI {
    [self.browserViewModel sortRSSIWithAscending:NO];
    [self.browserViewModel postReloadBrowserTable];
}

- (void)mapButtonTapped {
    [self performSegueWithIdentifier:@"SILKeychainSegue" sender:self];
}

#pragma mark - Scanning

- (void)setScanningButtonAppearanceWithScanning:(BOOL)isScanning {
    if (isScanning) {
        [self setStopScanningButton];
    } else {
        [self setStartScanningButton];
    }
    [self.floatingButtonSettings setPresented:true];
}

- (void)setStopScanningButton {
    [self.floatingButtonSettings setButtonText:@"Stop Scanning"];
    [self.floatingButtonSettings setColor:UIColor.sil_siliconLabsRedColor];
}

- (void)setStartScanningButton {
    [self.floatingButtonSettings setButtonText:@"Start Scanning"];
    [self.floatingButtonSettings setColor:UIColor.sil_regularBlueColor];
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
}

#pragma mark - SILBrowserDeviceViewCellDelegate

- (void)favouriteButtonTappedInCell:(SILBrowserDeviceViewCell*)cell {
    NSIndexPath *indexPath = [self.browserTableView indexPathForCell:cell];
    SILDiscoveredPeripheralDisplayDataViewModel *discoveredPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:indexPath.section];
    if (discoveredPeripheralViewModel.discoveredPeripheral.isFavourite) {
        [SILFavoritePeripheral remove:discoveredPeripheralViewModel];
    } else {
        [SILFavoritePeripheral add:discoveredPeripheralViewModel];
    }
    [self refreshTable];
}

- (void)connectButtonTappedInCell:(SILBrowserDeviceViewCell*)cell {
    NSIndexPath *indexPath = [self.browserTableView indexPathForCell:cell];
    SILDiscoveredPeripheralDisplayDataViewModel *selectedPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:indexPath.section];
    
    NSInteger index = [self isConnectedPeripheralWithIndex:selectedPeripheralViewModel.discoveredPeripheral];
    
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
        [self.noDevicesFoundStackView setHidden:YES];
    } else {
        [self.noDevicesFoundStackView setHidden:NO];
    }
}

#pragma mark - SILBrowserFilterViewControllerDelegate

- (void)backButtonWasTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyFiltersButtonWasTapped:(SILBrowserFilterViewModel *)filterViewModel {
    [self filterBrowser:filterViewModel];
    [self displayNoDeviceViewIfNeeded];
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (void)stopScanningAndDisconnectAll {
    [self stopScanningAction];
    [self.sortViewModel deselectSelectedOption];
    [self.navigationController popViewControllerAnimated:NO];
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
    self.isScanning = YES;
    [self startScanning];
    [self setScanningButtonAppearanceWithScanning:_isScanning];
    [self displayNoDeviceViewIfNeeded];
}

- (void)setupFloatingButtonSettings:(FloatingButtonSettings *)settings {
    self.floatingButtonSettings = settings;
    [self setScanningButtonAppearanceWithScanning:self.isScanning];
}

@end
