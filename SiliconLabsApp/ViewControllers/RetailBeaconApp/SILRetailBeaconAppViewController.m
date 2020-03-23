//
//  SILRetailBeaconAppViewController.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/20/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "SILRetailBeaconAppViewController.h"
#import "SILApp.h"
#import "SILBeacon.h"
#import "SILBeaconRegistry.h"
#import "SILBeaconRegistryEntry.h"
#import "SILBeaconRegistryEntryViewModel.h"
#import "SILRSSIMeasurementTable.h"
#import "SILSettings.h"
#import "UIView+SILAnimations.h"
#import "SILBeaconViewModel.h"
#import "SILBeaconRegistryEntryCell.h"
#import "UITableViewCell+SILHelpers.h"
#import "SILDoubleKeyDictionaryPair.h"
#import "SILRetailBeaconDetailsViewController.h"
#import "WYPopoverController+SILHelpers.h"

#define IS_IOS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

CGFloat const SILRetailBeaconAppRefreshRate = 1.0;
CGFloat const kIBeaconDMPZigbeeMajorNumber = 256.0f;
CGFloat const kIBeaconDMPProprietaryMajorNumber = 512.0f;
CGFloat const kIBeaconMajorNumber = 34987.0f;
CGFloat const kIBeaconMinorNumber = 1025.0f;
CGFloat const kAltBeaconMfgId = 0x0047;
CGFloat const kBeaconListTableViewCellRowHeight = 80.0;

NSString * const kIBeaconUUIDString = @"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0";
NSString * const kIBeaconDMPUUIDString = @"0047E70A-5DC1-4725-8799-830544AE04F6";
NSString * const kAltBeaconUUIDString = @"511AB500511AB500511AB500511AB500";
NSString * const kIBeaconIdentifier = @"com.silabs.retailbeacon";
NSString * const kIBeaconDMPZigbeeIdentifier = @"com.silabs.retailbeacon.dmpZigbee";
NSString * const kIBeaconDMPProprietaryIdentifier = @"com.silabs.retailbeacon.dmpProprietary";
NSString * const kScanningForBeacons = @"Scanning for beacons...";
NSString * const kAdditionalBeacons = @"Scanning for additional beacons...";
NSString * const kScanForNewBeacons = @"Scan for new beacons";

@interface SILRetailBeaconAppViewController () <CBCentralManagerDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, EddystoneScannerDelegate, WYPopoverControllerDelegate, SILRetailBeaconDetailsViewControllerDelegate>

@property (nonatomic, strong) SILBeaconRegistry *beaconRegistry;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CLBeaconRegion *dmpZigbeeBeaconRegion;
@property (nonatomic, strong) CLBeaconRegion *dmpProprietaryBeaconRegion;
@property (nonatomic, strong) NSArray<CLBeaconRegion *> *regions;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, assign) BOOL isScanning;
@property (nonatomic, strong) NSTimer *reloadDataTimer;
@property (nonatomic, strong) SILBeaconRegistryEntryCell *sizingRegistryEntryCell;

@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UILabel *bottomScanningLabel;
@property (weak, nonatomic) IBOutlet UITableView *beaconListTableView;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bottomScanningImageView;
@property (weak, nonatomic) IBOutlet UIButton *bottomScanningImageButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *footerHeightConstraint;
@property (strong, nonatomic) EddystoneScanner *eddystoneScanner;

@property (strong, nonatomic) WYPopoverController *devicePopoverController;

@property (assign, nonatomic) BOOL firstLayout;

@end

@implementation SILRetailBeaconAppViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.app.title;
    self.firstLayout = YES;
    self.bottomScanningLabel.text = kScanningForBeacons;
    self.beaconRegistry = [[SILBeaconRegistry alloc] init];

    [self startScanningImages];
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];
    self.eddystoneScanner = [[EddystoneScanner alloc] init];
    self.eddystoneScanner.delegate = self;
    [self setUpBeaconMonitoring];
    [self setUpTable];
    [self setupAppNotifications];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self startTimers];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    BOOL deviceIsIPhoneX = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone && UIScreen.mainScreen.nativeBounds.size.height == 2436);
    if (deviceIsIPhoneX && self.firstLayout) {
        self.footerHeightConstraint.constant = 75;
        self.firstLayout = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self stopTimers];
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (![parent isEqual:self.parentViewController]) {
        [self removeAppNotifications];
    }
}

- (void)dealloc {
    [self.reloadDataTimer invalidate];
}

#pragma mark - Set Up

- (void)setUpBeaconMonitoring {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;

    [self.locationManager requestAlwaysAuthorization];

    NSUUID *iBeaconUUID = [[NSUUID alloc] initWithUUIDString:kIBeaconUUIDString];
    NSUUID *iBeaconDMPUUID = [[NSUUID alloc] initWithUUIDString:kIBeaconDMPUUIDString];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:iBeaconUUID major:kIBeaconMajorNumber minor:kIBeaconMinorNumber identifier:kIBeaconIdentifier];
    self.dmpZigbeeBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:iBeaconDMPUUID major:kIBeaconDMPZigbeeMajorNumber identifier:kIBeaconDMPZigbeeIdentifier];
    self.dmpProprietaryBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:iBeaconDMPUUID major:kIBeaconDMPProprietaryMajorNumber identifier:kIBeaconDMPProprietaryIdentifier];
    self.regions = @[self.beaconRegion, self.dmpZigbeeBeaconRegion, self.dmpProprietaryBeaconRegion];
    
    for (CLBeaconRegion *beaconRegion in self.regions) {
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)setUpTable {
    NSString *beaconRegistryEntryCellClassString = NSStringFromClass([SILBeaconRegistryEntryCell class]);
    [self.beaconListTableView registerNib:[UINib nibWithNibName:beaconRegistryEntryCellClassString bundle:nil] forCellReuseIdentifier:beaconRegistryEntryCellClassString];
    self.sizingRegistryEntryCell = [[[UINib nibWithNibName:beaconRegistryEntryCellClassString bundle:nil] instantiateWithOwner:nil options:nil] firstObject];
    
    self.beaconListTableView.rowHeight = UITableViewAutomaticDimension;
    self.beaconListTableView.estimatedRowHeight = kBeaconListTableViewCellRowHeight;
}

- (void)setupAppNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)removeAppNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)appDidBecomeActive {
    [self startScanningImages];
}

- (void)appDidEnterBackground {
    [self pauseScanningImages];
}

#pragma mark - Configure

- (SILBeaconRegistryEntryViewModel *)beaconRegistryEntryViewModelForEntry:(SILBeaconRegistryEntry *)entry {
    return [[SILBeaconRegistryEntryViewModel alloc] initWithBeaconRegistryEntry:entry];
}

- (void)updateBeaconList {
    [self.beaconListTableView reloadData];
}

- (SILBeaconRegistryEntryViewModel *)beaconRegistryEntryViewModelForIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    NSArray* entries = [self.beaconRegistry beaconRegistryEntries];
    if (row < entries.count) {
        SILBeaconRegistryEntry *entry = entries[row];
        SILBeaconRegistryEntryViewModel *entryViewModel = [self beaconRegistryEntryViewModelForEntry:entry];
        return entryViewModel;
    }

    return  nil;
}

- (void)configureCell:(SILBeaconRegistryEntryCell *)registryEntryCell forIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    if (row == 0) {
        registryEntryCell.beaconSeparatorView.hidden = true;
    }
    SILBeaconRegistryEntryViewModel *entryViewModel = [self beaconRegistryEntryViewModelForIndexPath:indexPath];
    [registryEntryCell configureWithViewModel:entryViewModel];

    [registryEntryCell setNeedsLayout];
    [registryEntryCell layoutIfNeeded];
}

- (void)reloadData {
    BOOL beaconFound = [self.beaconRegistry beaconRegistryEntries].count > 0;

    if (beaconFound) {
        if (self.isScanning) {
            self.bottomScanningLabel.text = kAdditionalBeacons;
        }
    }

    [self updateBeaconList];
}

- (void)startScanningImages {
    [UIView addContinuousRotationAnimationToLayer:self.bottomScanningImageView.layer withFullRotationDuration:2 forKey:@"rotationAnimation"];
}

- (void)pauseScanningImages {
    [self.bottomScanningImageView.layer removeAllAnimations];
}

#pragma mark - ReloadDataTimer

- (void)startTimers {
    [self.reloadDataTimer invalidate];
    self.reloadDataTimer = [NSTimer scheduledTimerWithTimeInterval:SILRetailBeaconAppRefreshRate
                                                            target:self
                                                          selector:@selector(reloadData)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)stopTimers {
    [self.reloadDataTimer invalidate];
    self.reloadDataTimer = nil;
}

#pragma mark - Scanning

- (IBAction)didTapScanningToggleButton:(UIButton *)sender {
    if (self.isScanning) {
        [self stopScanning];
        [self pauseScanningImages];
    } else {
        self.beaconRegistry = [[SILBeaconRegistry alloc] init];
        [self.beaconListTableView reloadData];
        [self startScanning];
        [self startScanningImages];
    }
    self.bottomScanningLabel.text = self.isScanning ? kScanningForBeacons : kScanForNewBeacons;
    self.bottomScanningImageView.alpha = self.isScanning ? 1.0 : 0.0;
    NSString *imageString = self.isScanning ? @"cancelScanning" : @"startScanning";
    [self.bottomScanningImageButton setImage:[UIImage imageNamed:imageString] forState: UIControlStateNormal];
}

- (void)startScanning {
    if (!self.isScanning) {
        self.isScanning = YES;
        [self.centralManager scanForPeripheralsWithServices:nil
                                                    options:@{
                                                              CBCentralManagerScanOptionAllowDuplicatesKey : @YES,
                                                              }];
        [self.eddystoneScanner scanForEddystoneBeacons];
    }
}

- (void)stopScanning {
    if (self.isScanning) {
        self.isScanning = NO;
        [self.centralManager stopScan];
        [self.eddystoneScanner stopScanningForEddystoneBeacons];
    }
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        [self startScanning];
    } else {
        [self stopScanning];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (advertisementData[CBAdvertisementDataManufacturerDataKey] != nil) {
        NSString *name = peripheral.name;
        [self.beaconRegistry updateWithAdvertisment:advertisementData name:name RSSI:RSSI];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    for (CLBeaconRegion *beaconRegion in self.regions) {
        if ([beaconRegion isEqual:region]) {
           [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    for (CLBeaconRegion *beaconRegion in self.regions) {
        if ([beaconRegion isEqual:region]) {
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
            [self.beaconRegistry removeIBeaconEntriesWithUUID:beaconRegion.proximityUUID];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region {
    for (CLBeacon *foundBeacon in beacons) {
        [self.beaconRegistry updateWithIBeacon:foundBeacon];
    }
}

#pragma mark - UITableViewDataSourceDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.beaconRegistry beaconRegistryEntries].count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    SILBeaconRegistryEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILBeaconRegistryEntryCell class]) forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

#pragma mark - UITableViewDelegate

//Included for compat with iOS7
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self configureCell:self.sizingRegistryEntryCell forIndexPath:indexPath];
    return [self.sizingRegistryEntryCell autoLayoutHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    SILBeaconRegistryEntryViewModel *entryViewModel = [self beaconRegistryEntryViewModelForIndexPath:indexPath];

    SILRetailBeaconDetailsViewController *selectionViewController = [[SILRetailBeaconDetailsViewController alloc] init];
    selectionViewController.delegate = self;
    selectionViewController.entryViewModel = entryViewModel;
    self.devicePopoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:selectionViewController
                                                                                 presentingViewController:self
                                                                                                 delegate:self
                                                                                                 animated:YES];
}

#pragma mark - EddystoneScannerDelegate

- (void)eddystoneScanner:(EddystoneScanner *)eddystoneScanner didFindBeacons:(NSArray<EddystoneBeacon *> *)beacons {
    for (EddystoneBeacon *foundBeacon in beacons) {
        [self.beaconRegistry updateWithEddystoneBeacon:foundBeacon];
    }
}

#pragma mark - SILRetailBeaconDetailsViewControllerDelegate

- (void)didFinishHelpWithBeaconDetailsViewController:(SILRetailBeaconDetailsViewController *)beaconDetailsViewController {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:^{
        self.devicePopoverController = nil;
    }];
}

#pragma mark - WYPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)popoverController {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:nil];
    self.devicePopoverController = nil;
}

@end
