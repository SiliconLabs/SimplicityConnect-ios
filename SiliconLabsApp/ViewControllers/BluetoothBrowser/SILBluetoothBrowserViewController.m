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
@property (weak, nonatomic) IBOutlet UIImageView *emptyImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *expandableControllerHeight;
@property (weak, nonatomic) IBOutlet UIView *expandableControllerView;
@property UIViewController* expandingViewController;
@property UIVisualEffectView* effectView;
@property (strong, nonatomic) NSTimer *tableRefreshTimer;
@property (strong, nonatomic) SILDebugDeviceViewModel *browserViewModel;
@property (strong, nonatomic) SILBrowserConnectionsViewModel* connectionsViewModel;
@property (strong, nonatomic) NSIndexPath *connectingCellIndexPath;
@property BOOL isScanning;
@property NSMutableArray<NSString*>* expandSections;

@end

@implementation SILBluetoothBrowserViewController

UIEdgeInsets const ImageInsetsForLogButton = {0, 16, 0 ,8};
UIEdgeInsets const TitleEdgeInsetsForLogButton = {0, 20., 0, 0};
UIEdgeInsets const ImageInsetsForConnectionsButton = {0, 8, 0 ,8};
UIEdgeInsets const TitleEdgeInsetsForConnectionsButton = {0, 8, 0, 0};
UIEdgeInsets const ImageInsetsForFilterButton = {0, 8, 0 ,12};
UIEdgeInsets const TitleEdgeInsetsForFilterButton = {0, 8, 0, 8};
NSString* const TitleForScanningButtonDuringScanning = @"Stop Scanning";
NSString* const TitleForScanningButtonWhenIsNotScanning = @"Start Scanning";
NSString* const AppendingConnections = @" Connections";
NSString* const MissingPeripheralName = @"Unknown";
long long const ms = 1000000;
NSString* const AppendingMS = @" ms";
const float TABLE_FRESH_INTERVAL = 2.0f;
CGFloat const tableInset = 16;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupProperties];
    [self setupNavigationBar];
    [self setupLogButton];
    [self setupConnectionsButton];
    [self setupFilterButton];
    [self setupScanningButton];
    [self registerForApplicationDidBecomeActiveNotification];
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
    [self startScanning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_connectionsViewModel connectionsViewOnDetailsScreen:NO];
    [self prepareSceneForRemoveExpandingController];
    self.browserViewModel.connectedPeripheral = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.browserViewModel.observing = NO;
    [self.browserViewModel clearIsConnectingDirectory];
}

#pragma mark - Setup

- (void)setupProperties {
    _isScanning = YES;
    _cornerRadius = 0.0;
    _expandSections = [[NSMutableArray alloc] init];
}

- (void)setupNavigationBar {
    [self setupNavigationBarBackgroundColor];
    [self setupNavigationBarTitle];
}

- (void)setupBrowserTableViewAppearance {
    if (@available(iOS 13, *)) {
        _tableLeftInset.constant = 0;
        _tableRightInset.constant = 0;
        _browserTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        _tableLeftInset.constant = tableInset;
        _tableRightInset.constant = tableInset;
    }
}

- (void)setupNavigationBarBackgroundColor {
    _navigationBarView.backgroundColor = [UIColor sil_siliconLabsRedColor];
    _aboveSpaceAreaView.backgroundColor = [UIColor sil_siliconLabsRedColor];
}

- (void)setupNavigationBarTitle {
    _navigationBarTitleLabel.font = [UIFont robotoMediumWithSize:SILNavigationBarTitleFontSize];
    _navigationBarTitleLabel.textColor = [UIColor sil_backgroundColor];
}

- (void)setupLogButton {
    [_logButton setTintColor:[UIColor clearColor]];
    [_logButton setImage:[[UIImage imageNamed:SILImageLogOff] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState: UIControlStateNormal];
    [_logButton setImage:[[UIImage imageNamed:SILImageLogOn] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateSelected];
    _logButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _logButton.imageEdgeInsets = ImageInsetsForLogButton;
    [_logButton setTitleEdgeInsets:TitleEdgeInsetsForLogButton];
    _logButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    _logButton.titleLabel.font = [UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]];
    [_logButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
    [_logButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateSelected];
}

- (void)setupConnectionsButton {
    [_connectionsButton setTintColor:[UIColor clearColor]];
    [_connectionsButton setImage:[[UIImage imageNamed:SILImageConnectOff] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [_connectionsButton setImage:[[UIImage imageNamed:SILImageConnectOn] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateSelected];
    _connectionsButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _connectionsButton.imageEdgeInsets = ImageInsetsForConnectionsButton;
    [_connectionsButton setTitleEdgeInsets:TitleEdgeInsetsForConnectionsButton];
    _connectionsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    _connectionsButton.titleLabel.font = [UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]];
    [_connectionsButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
    [_connectionsButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateSelected];
}

- (void)setupFilterButton {
    [_filterButton setTintColor:[UIColor clearColor]];
    [_filterButton setImage:[[UIImage imageNamed:SILImageSearchOff] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [_filterButton setImage:[[UIImage imageNamed:SILImageSearchOn] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateSelected];
    _filterButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _filterButton.imageEdgeInsets = ImageInsetsForFilterButton;
    [_filterButton setTitleEdgeInsets:TitleEdgeInsetsForFilterButton];
    _filterButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    _filterButton.titleLabel.font = [UIFont robotoMediumWithSize:[UIFont getMiddleFontSize]];
    [_filterButton setTitleColor:[UIColor sil_primaryTextColor] forState:UIControlStateNormal];
    [_filterButton setTitleColor:[UIColor sil_regularBlueColor] forState:UIControlStateSelected];
    [_activeFilterImage setHidden:YES];
}

- (void)setupScanningButton {
    _scanningButton.titleLabel.font = [UIFont robotoMediumWithSize:SILScanningButtonTitleFontSize];
    _scanningButton.titleLabel.textColor = [UIColor sil_backgroundColor];
    _scanningButton.layer.cornerRadius = 10.0;
}

- (void)registerForApplicationDidBecomeActiveNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)setupBrowserViewModel {
    self.browserViewModel = [[SILDebugDeviceViewModel alloc] init];
    self.browserViewModel.delegate = self;
}

- (void)installViewModelsForExpandableViews {
    SILBrowserLogViewModel* browserLog = [SILBrowserLogViewModel sharedInstance];
    _connectionsViewModel = [SILBrowserConnectionsViewModel sharedInstance];
    _connectionsViewModel.centralManager = _browserViewModel.centralManager;
    [_connectionsViewModel disconnectAllPeripheral];
    [browserLog clearLogs];
}

- (void)setupBackgroundForScanning:(BOOL)scanning {
    NSString *imageName = scanning ? SILImageLoading : SILImageEmptyView;
    self.emptyImageView.image = [UIImage imageNamed:imageName];
}

- (void)addObservers {
    [self addObserversForReloadBrowserTableView];
    [self addObserverForReloadConnectionsButtonTitle];
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
    NSMutableString* connectionsText = [[NSMutableString alloc] initWithFormat: @"%lu", (unsigned long)connections];
    [connectionsText appendString:AppendingConnections];
    [_connectionsButton setTitle:connectionsText forState:UIControlStateNormal];
    [_connectionsButton setTitle:connectionsText forState:UIControlStateSelected];
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
    NSString* identifier = discoveredPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.peripheral.identifier.UUIDString;
    
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
    NSString* cellIdentifier = discoveredPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.peripheral.identifier.UUIDString;
    cell.cellIdentifier = cellIdentifier;
    SILDiscoveredPeripheral *discoveredPeripheral = discoveredPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral;
    NSString *deviceName = discoveredPeripheral.advertisedLocalName;
    cell.rssiLabel.text = discoveredPeripheral.rssiDescription;
    cell.title.text = deviceName;
    if ([deviceName isEqualToString:EmptyText] || deviceName == nil) {
        cell.title.text = MissingPeripheralName;
    }
    
    cell.uuidLabel.text = discoveredPeripheral.peripheral.identifier.UUIDString;
    long long advertisingIntervalsInMS = discoveredPeripheral.advertisingInterval / ms;
    
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
    
    if ([_browserViewModel containPeripheral:discoveredPeripheral.peripheral]) {
        [cell.connectingIndicator setHidden:NO];
        [cell.connectingIndicator startAnimating];
    }
}

- (void)configureServiceCell:(SILBrowserServiceViewCell*)cell atIndexPath:(NSIndexPath *)indexPath {
    SILDiscoveredPeripheralDisplayDataViewModel *discoveredPeripheralViewModel = [self.browserViewModel peripheralViewModelAt:indexPath.section];
    SILAdvertisementDataViewModel *detailModel = discoveredPeripheralViewModel.advertisementDataViewModelsForInfoView[indexPath.row-1];
    cell.serviceNameLabel.text = detailModel.typeString;
    cell.serviceUUIDLabel.text = detailModel.valueString;
}

- (BOOL)isConnectedPeripheral:(SILDiscoveredPeripheral*)peripheral {
    for (SILConnectedPeripheralDataModel* connectedPeripheral in _connectionsViewModel.peripherals) {
        if ([peripheral.peripheral.identifier.UUIDString isEqualToString:connectedPeripheral.peripheral.identifier.UUIDString]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSInteger)isConnectedPeripheralWithIndex:(SILDiscoveredPeripheral*)peripheral {
    NSInteger index = 0;
    for (SILConnectedPeripheralDataModel* connectedPeripheral in _connectionsViewModel.peripherals) {
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
    NSString* identifier = selectedPeripheralViewModel.discoveredPeripheralDisplayData.discoveredPeripheral.peripheral.identifier.UUIDString;
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
    if (_filterButton.isSelected == NO) {
        BOOL anyButtonSelected = [self isAnyButtonSelected];
        [self prepareSceneDependOnButtonSelection:anyButtonSelected];
        
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserHome bundle:nil];
        SILBrowserFilterViewController* filterVC = [storyboard instantiateViewControllerWithIdentifier:SILSceneFilter];
    
        [self insertIntoContainerExpandableController:filterVC];
        [self animateExpandableViewControllerIfNeeded:anyButtonSelected];
        filterVC.delegate = self;
        self.expandingViewController = filterVC;
        
        [_filterButton setSelected:YES];
    }
}

- (IBAction)connectionsButtonTapped:(id)sender {
    if (_connectionsButton.isSelected == NO) {
        BOOL anyButtonSelected = [self isAnyButtonSelected];
        [self prepareSceneDependOnButtonSelection:anyButtonSelected];
    
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserHome bundle:nil];
        SILBrowserConnectionsViewController* connectionVC = [storyboard instantiateViewControllerWithIdentifier:SILSceneConnections];
    
        [self insertIntoContainerExpandableController:connectionVC];
        [self animateExpandableViewControllerIfNeeded:anyButtonSelected];
        connectionVC.delegate = self;
        self.expandingViewController = connectionVC;
        
        [_connectionsButton setSelected:YES];
    }
}

- (IBAction)logButtonWasTapped:(id)sender {
    if (_logButton.isSelected == NO) {
        BOOL anyButtonSelected = [self isAnyButtonSelected];
        [self prepareSceneDependOnButtonSelection:anyButtonSelected];
        
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserHome bundle:nil];
        SILBrowserLogViewController* logVC = [storyboard instantiateViewControllerWithIdentifier:SILSceneLog];
    
        [self insertIntoContainerExpandableController:logVC];
        [self animateExpandableViewControllerIfNeeded:anyButtonSelected];
        logVC.delegate = self;
        self.expandingViewController = logVC;
        
        [_logButton setSelected:YES];
    }
}

- (BOOL)isAnyButtonSelected {
    return ! (_logButton.isSelected == NO && _connectionsButton.isSelected == NO && _filterButton.isSelected == NO);
}

- (void)deselectAllButtons {
    [_logButton setSelected:NO];
    [_connectionsButton setSelected:NO];
    [_filterButton setSelected:NO];
}

- (void)prepareSceneDependOnButtonSelection:(BOOL)anyButtonSelected {
    if (anyButtonSelected) {
        [self prepareSceneForChangeExpandableView];
    } else {
        [self prepareSceneForExpandableView];
    }
    
    [self customizeExpandableViewAppearance];
}

- (void)prepareSceneForChangeExpandableView {
    [self deselectAllButtons];
    [self removeExpandableViewController];
}

- (void)prepareSceneForExpandableView {
    if (_expandingViewController != nil) {
        [self prepareSceneForRemoveExpandingController];
    }
    
    [self attachBlurEffectView];
}

- (void)customizeExpandableViewAppearance {
    self.cornerRadius = 20.0;
    self.expandableControllerHeight.constant = self.presentationView.frame.size.height * 0.9;
}

- (void)customizeSceneWithoutExpandableViewContoller {
    self.cornerRadius = 0.0;
    self.expandableControllerHeight.constant = CollapsedViewHeight;
}

- (void)removeExpandableViewController {
    [self willMoveToParentViewController:nil];
    [self.expandingViewController.view removeFromSuperview];
    [self.expandingViewController removeFromParentViewController];
    self.expandingViewController = nil;
}

- (void)insertIntoContainerExpandableController:(UIViewController*)viewController {
    [self addChildViewController:viewController];
    [self.expandableControllerView addSubview:viewController.view];
    viewController.view.frame = self.expandableControllerView.frame;
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [viewController didMoveToParentViewController:self];
    
    [self.view setNeedsUpdateConstraints];
}

- (void)animateExpandableViewControllerIfNeeded:(BOOL)anyButtonSelected {
    if (!anyButtonSelected) {
        [self animateExpandableViewController];
    }
}

- (void)animateExpandableViewController {
    [UIView animateWithDuration:AnimationExpandableControllerTime delay:AnimationExpandableControllerDelay options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionTransitionCurlDown animations:^{
            [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)prepareSceneForRemoveExpandingController {
    [self deselectAllButtons];
    [self removeExpandableViewController];
    [self customizeSceneWithoutExpandableViewContoller];
    [self animateExpandableViewController];
    [self removeBlurEffectView];
}

- (void)attachBlurEffectView {
    UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    _effectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _effectView.frame = self.presentationView.frame;
    [self.discoveredDevicesView addSubview:_effectView];
}

- (void)removeBlurEffectView {
    [_effectView removeFromSuperview];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    if (_cornerRadius != cornerRadius) {
        _cornerRadius = cornerRadius;
        [self adjustView];
    }
}

- (void)adjustView {
    if (_expandableControllerView != nil) {
        self.expandableControllerView.layer.cornerRadius = _cornerRadius;
        self.expandableControllerView.layer.maskedCorners = kCALayerMaxXMaxYCorner | kCALayerMinXMaxYCorner;
        self.expandableControllerView.clipsToBounds = YES;
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
    [self.browserViewModel stopScanning];
    [self stopScanningForDevices];
}

- (void)startScanningAction {
    [self startScanning];
    [self.browserTableView reloadData];
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
    NSIndexPath *indexPath = [_browserTableView indexPathForCell:cell];
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

#pragma mark - Notifications

- (void)unregisterForApplicationDidBecomeActiveNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - Notifcation Methods

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self startScanning];
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
    if (self.browserViewModel.isContentAvailable == NO) {
        self.browserTableView.hidden = YES;
    }
    [self setupBackgroundForScanning:YES];
}

- (void)tableRefreshTimerFired {
    if (self.browserViewModel.isContentAvailable) {
        self.browserTableView.hidden = NO;
        [self.emptyImageView setHidden:YES];
        [self refreshTable];
    }
}

#pragma mark - SILBrowserFilterViewControllerDelegate

- (void)backButtonWasTapped {
    [self prepareSceneForRemoveExpandingController];
}

- (void)searchButtonWasTapped:(SILBrowserFilterViewModel *)filterViewModel {
    [self prepareSceneForRemoveExpandingController];
    [self manageAppearanceOfActiveFilterImage:filterViewModel];
    [self filterBrowser:filterViewModel];
}

- (void)manageAppearanceOfActiveFilterImage:(SILBrowserFilterViewModel*)filterViewModel {
    if ([filterViewModel isFilterActive]) {
        [_activeFilterImage setHidden:NO];
    } else {
        [_activeFilterImage setHidden:YES];
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
         _browserViewModel.searchByDeviceName = filterViewModel.searchByDeviceName;
     } else {
         _browserViewModel.searchByDeviceName = nil;
     }
     if (![filterViewModel.searchByRawAdvertisingData isEqualToString:EmptyText]) {
         _browserViewModel.searchByAdvertisingData = filterViewModel.searchByRawAdvertisingData;
     } else {
         _browserViewModel.searchByAdvertisingData = nil;
     }
     _browserViewModel.currentMinRSSI = [NSNumber numberWithInteger:filterViewModel.dBmValue];
     _browserViewModel.beaconTypes = filterViewModel.beaconTypes;
     _browserViewModel.isFavourite = filterViewModel.isFavouriteFilterSet;
     _browserViewModel.isConnectable = filterViewModel.isConnectableFilterSet;
}

- (void)resetFilters {
    _browserViewModel.searchByDeviceName = nil;
    _browserViewModel.searchByAdvertisingData = nil;
    _browserViewModel.currentMinRSSI = nil;
    _browserViewModel.beaconTypes = nil;
    _browserViewModel.isFavourite = nil;
    _browserViewModel.isConnectable = nil;
}

#pragma mark - SILBrowserConnectionsViewControllerDelegate

- (void)connectionsViewBackButtonPressed {
    [self prepareSceneForRemoveExpandingController];
}

- (void)presentDetailsViewControllerForIndex:(NSInteger)index {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserDetails bundle:nil];
    SILDebugServicesViewController* detailsVC = [storyboard instantiateViewControllerWithIdentifier:SILSceneConnectedDevice];
    SILConnectedPeripheralDataModel* connectedPeripheral = _connectionsViewModel.peripherals[index];
    detailsVC.peripheral = connectedPeripheral.peripheral;
    detailsVC.centralManager = self.browserViewModel.centralManager;
    [self updateCellsWithConnecting:connectedPeripheral.peripheral];
    [self removeUnfiredTimers];
    [self.navigationController pushViewController:detailsVC animated:YES];
}

#pragma mark - SILBrowserLogViewControllerDelegate

- (void)logViewBackButtonPressed {
    [self prepareSceneForRemoveExpandingController];
}

- (IBAction)backToDevelopWasTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self isSignificatantScrollToTop:scrollView]) {
        [_browserViewModel removeAllDiscoveredPeripherals];
        [self reloadTable];
        _isScanning = YES;
        [self setScanningButtonAppearanceWithScanning:_isScanning];
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
