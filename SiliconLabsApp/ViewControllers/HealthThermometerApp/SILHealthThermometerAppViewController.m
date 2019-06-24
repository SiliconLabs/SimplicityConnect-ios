//
//  SILHealthThermometerAppViewController.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/15/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILHealthThermometerAppViewController.h"
#import "SILCentralManager.h"
#import "SILApp.h"
#import "SILTemperatureMeasurement.h"
#import "SILBarGraphCollectionViewCell.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "SILCollectionViewRightAlignedFlowLayout.h"
#import "UIColor+SILColors.h"
#import "SILSegmentedControl.h"
#import "SILDeviceSelectionViewController.h"
#import "WYPopoverController.h"
#import "WYPopoverController+SILHelpers.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "SILConstants.h"
#import "UIImage+SILImages.h"

typedef NS_ENUM(NSInteger, SILThermometerUnitControlType) {
    SILThermometerUnitControlTypeFahenheit = 0,
    SILThermometerUnitControlTypeCelsius = 1,
};

@interface SILHealthThermometerAppViewController () <CBPeripheralDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SILDeviceSelectionViewControllerDelegate, WYPopoverControllerDelegate>

@property (strong, nonatomic) CBCharacteristic *temperatureMeasurementCharacteristic;
@property (strong, nonatomic) SILTemperatureMeasurement *recentTemperatureMeasurement;
@property (strong, nonatomic) NSMutableArray *temperatureMeasurements;
@property (strong, nonatomic) WYPopoverController *devicePopoverController;

@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *recentTemperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *recentTemperatureDecimalLabel;
@property (weak, nonatomic) IBOutlet UILabel *recentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *recentTypeLabel;
@property (weak, nonatomic) IBOutlet UIButton *changeButton;
@property (weak, nonatomic) IBOutlet UIButton *clearButton;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UICollectionView *measurementCollectionView;
@property (weak, nonatomic) IBOutlet SILSegmentedControl *typeControl;
@property (assign, nonatomic) BOOL isConnected;

- (IBAction)didTapChangeButton:(id)sender;
- (IBAction)didTapClearButton:(id)sender;
- (IBAction)didTapAddButton:(id)sender;

- (IBAction)typeControlValueDidChange:(id)sender;

@end

@implementation SILHealthThermometerAppViewController

- (void)clearData {
    self.recentTemperatureMeasurement = nil;
    [self.temperatureMeasurements removeAllObjects];

    [self reloadData];
}

- (BOOL)displayInFahrenheit {
    return self.typeControl.selectedIndex == SILThermometerUnitControlTypeFahenheit;
}

- (void)setRecentTemperatureMeasurement:(SILTemperatureMeasurement *)recentTemperatureMeasurement {
    _recentTemperatureMeasurement = recentTemperatureMeasurement;

    [self updateRecentMeasurement];
}

- (void)addTemperatureMeasurement:(SILTemperatureMeasurement *)temperatureMeasurement animated:(BOOL)animated {
    if (self.temperatureMeasurements.count == 0) {
        [self.temperatureMeasurements addObject:temperatureMeasurement];
    } else {
        [self.temperatureMeasurements insertObject:temperatureMeasurement atIndex:0];
    }

    if (animated) {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.measurementCollectionView insertItemsAtIndexPaths:@[newIndexPath]];
        [self.measurementCollectionView scrollToItemAtIndexPath:newIndexPath
                                               atScrollPosition:UICollectionViewScrollPositionRight
                                                       animated:YES];
    } else {
        [self.measurementCollectionView reloadData];
    }
}

#pragma mark - Presentation

- (void)presentDeviceSelectionViewController:(BOOL)animated {
    SILDeviceSelectionViewModel *viewModel = [[SILDeviceSelectionViewModel alloc] initWithAppType:self.app];
    SILDeviceSelectionViewController *selectionViewController = [[SILDeviceSelectionViewController alloc] initWithDeviceSelectionViewModel:viewModel];
    selectionViewController.centralManager = self.centralManager;
    selectionViewController.delegate = self;

    self.devicePopoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:selectionViewController
                                                                                 presentingViewController:self
                                                                                                 delegate:self
                                                                                                 animated:YES];
}

#pragma mark - Button Actions

- (IBAction)didTapChangeButton:(id)sender {
    [self disconnectPeripheral];
    [self resetConnectedPeripheralData];
    [self presentDeviceSelectionViewController:YES];
}

- (IBAction)didTapClearButton:(id)sender {
    [self.temperatureMeasurements removeAllObjects];
    [self.measurementCollectionView reloadData];
}

- (IBAction)didTapAddButton:(id)sender {
    if (self.recentTemperatureMeasurement) {
        if(![self.temperatureMeasurements containsObject:self.recentTemperatureMeasurement]) {
            [self addTemperatureMeasurement:self.recentTemperatureMeasurement animated:YES];
        }
    }
}

- (IBAction)typeControlValueDidChange:(id)sender {
    [self reloadData];
}

#pragma mark - Setup

- (void)setup {
    self.title = self.app.title;

    [self setupCustomBackButton];
    [self setupDeviceInfo];
    [self setupTypeControl];
    [self setupMeasurementCollectionView];

    [self updateRecentMeasurement];
}

- (void)setupDeviceInfo {
    self.deviceNameLabel.text = self.connectedPeripheral.name;

    self.changeButton.layer.borderColor = [UIColor sil_siliconLabsRedColor].CGColor;
    self.changeButton.layer.borderWidth = 2.0;
}

- (void)setupTypeControl {
    [self.typeControl addTarget:self action:@selector(typeControlValueDidChange:) forControlEvents:UIControlEventValueChanged];

    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {
        self.typeControl.firstSegmentLabel.text = @"F";
        self.typeControl.secondSegmentLabel.text = @"C";

        self.typeControl.selectedTextColor = [UIColor whiteColor];
        self.typeControl.unselectedTextColor = [UIColor whiteColor];
        self.typeControl.selectedIndicatorColor = [UIColor sil_siliconLabsRedColor];
        self.typeControl.unselectedIndicatorColor = [UIColor sil_silverColor];

        self.typeControl.firstSegmentIndicatorView.layer.cornerRadius = self.typeControl.firstSegmentIndicatorView.frame.size.width * 0.5;
        self.typeControl.secondSegmentIndicatorView.layer.cornerRadius = self.typeControl.firstSegmentIndicatorView.frame.size.width * 0.5;
    } else {
        self.typeControl.firstSegmentLabel.text = @"ºF";
        self.typeControl.secondSegmentLabel.text = @"ºC";

        self.typeControl.selectedTextColor = [UIColor sil_siliconLabsRedColor];
        self.typeControl.unselectedTextColor = [UIColor sil_silverColor];
        self.typeControl.selectedIndicatorColor = [UIColor sil_siliconLabsRedColor];
        self.typeControl.unselectedIndicatorColor = [UIColor sil_silverColor];
    }
}

- (void)setupMeasurementCollectionView {
    if ([self.measurementCollectionView.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.measurementCollectionView.collectionViewLayout;
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    self.measurementCollectionView.contentInset = UIEdgeInsetsMake(0,
                                                                   0,
                                                                   0,
                                                                   (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 18 : 5);
    [self.measurementCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([SILBarGraphCollectionViewCell class]) bundle:nil]
                     forCellWithReuseIdentifier:NSStringFromClass([SILBarGraphCollectionViewCell class])];
}

- (void)reloadData {
    [self.measurementCollectionView reloadData];
    [self updateRecentMeasurement];
}

- (void)updateRecentMeasurement {
    if (self.recentTemperatureMeasurement) {
        float value = self.displayInFahrenheit ? [self.recentTemperatureMeasurement valueInFahrenheit] : [self.recentTemperatureMeasurement valueInCelsius];
        NSString *valueString = [NSString stringWithFormat:@"%.1f", value];
        NSArray *components = [valueString componentsSeparatedByString:@"."];
        if (components.count >= 2) {
            self.recentTemperatureLabel.text = components[0];
            self.recentTemperatureDecimalLabel.text = components[1];
        } else if (components.count == 1) {
            self.recentTemperatureLabel.text = components[0];
            self.recentTemperatureDecimalLabel.text = @"0";
        } else {
            self.recentTemperatureLabel.text = @"0";
            self.recentTemperatureDecimalLabel.text = @"0";
        }

        if (self.recentTemperatureMeasurement.measurementDate) {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"HH:mm"];
            self.recentTimeLabel.text = [dateFormat stringFromDate:self.recentTemperatureMeasurement.measurementDate];
        } else {
            self.recentTimeLabel.text = @"N/A";
        }

        self.recentTypeLabel.text = SILTemperatureTypeDisplayName(self.recentTemperatureMeasurement.temperatureType);
    } else {
        self.recentTemperatureLabel.text = @"0";
        self.recentTemperatureDecimalLabel.text = @"0";
        self.recentTimeLabel.text = @"N/A";
        self.recentTypeLabel.text = @"N/A";
    }
}

- (void)setupCustomBackButton {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [button setTitle:@"     " forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:SILImageNameBackIcon] forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self action:@selector(disconnectedAndPop) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

#pragma mark - UIViewController

- (void)disconnectedAndPop {
    if (self.isConnected) {
        [SVProgressHUD showErrorWithStatus:@"Disconnecting Thermometer..."];
        [self disconnectPeripheral];

        // If the peripheral is disconnected too close to the centralManager being released, the central manager won't
        //      send the disconnect message before being released. Adding a brief pause ensures that the messages are
        //      sent before the centralManager loses scope.
        [self.navigationController performSelector:@selector(popViewControllerAnimated:) withObject:@(YES) afterDelay:1.5];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.temperatureMeasurements = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setup];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self registerForBluetoothControllerNotifications];
    [self preparePeripheral];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (self.isConnected) {
        [SVProgressHUD showErrorWithStatus:@"Disconnecting Thermometer..."];
        [self disconnectPeripheral];
    }
}

- (void)dealloc {
    [self unregisterForBluetoothControllerNotifications];
}

#pragma mark - Bluetooth

- (void)disconnectPeripheral {
    self.isConnected = NO;
    [self unregisterForBluetoothControllerNotifications];
    self.connectedPeripheral.delegate = nil;
    [self.connectedPeripheral setNotifyValue:NO forCharacteristic:self.temperatureMeasurementCharacteristic];
    self.temperatureMeasurementCharacteristic = nil;
    self.connectedPeripheral = nil;
    [self.centralManager disconnectConnectedPeripheral];
}

- (void)resetConnectedPeripheralData {
    self.deviceNameLabel.text = @"";
    [self clearData];
}

- (void)preparePeripheral {
    if ([self.connectedPeripheral state] == CBPeripheralStateConnected) {
        self.isConnected = YES;
        self.connectedPeripheral.delegate = self;
        if ([self.connectedPeripheral services].count > 0) {
            [self discoverPeripheralCharacteristicsForServices];
        } else {
            [self.connectedPeripheral discoverServices:self.centralManager.serviceUUIDs];
        }
    } else if ([self.connectedPeripheral state] == CBPeripheralStateDisconnected) {
        [self disconnectPeripheral];
        [self resetConnectedPeripheralData];
        [self presentDeviceSelectionViewController:YES];
    } else {
        NSLog(@"The app has entered an unhandled state, bailing back to the menu.");
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)discoverPeripheralCharacteristicsForServices {
    for (CBService *service in self.connectedPeripheral.services) {
        [self.connectedPeripheral discoverCharacteristics:@[
                                                            [CBUUID UUIDWithString:SILCharacteristicNumberTemperatureMeasurement],
                                                            ]
                                               forService:service];
    }
}

#pragma mark - Central Manager Notifications

- (void)registerForBluetoothControllerNotifications {
    [self unregisterForBluetoothControllerNotifications];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCentralManagerDidDisconnectPeripheralNotification:)
                                                 name:SILCentralManagerDidDisconnectPeripheralNotification
                                               object:self.centralManager];
}

- (void)unregisterForBluetoothControllerNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:SILCentralManagerDidDisconnectPeripheralNotification
                                                  object:self.centralManager];
}

- (void)handleCentralManagerDidDisconnectPeripheralNotification:(NSNotification *)notification {
    [self disconnectPeripheral];
    [self resetConnectedPeripheralData];
    [self presentDeviceSelectionViewController:YES];
    [SVProgressHUD showErrorWithStatus:@"Thermometer Disconnected..."];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"didDiscoverServices error: %@", error);
    } else {
        NSLog(@"didDiscoverService: %@", [peripheral services]);
        [self discoverPeripheralCharacteristicsForServices];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"didDiscoverCharacteristicsForService: %@ error: %@", service, error);
    } else {
        NSLog(@"didDiscoverCharacteristicsForService: %@ characteristics: %@", [peripheral services], service.characteristics);
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SILCharacteristicNumberTemperatureMeasurement]]) {
                self.temperatureMeasurementCharacteristic = characteristic;
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"didUpdateValueForCharacteristic: %@ error: %@", characteristic, error);
    } else {
        NSLog(@"didUpdateValueForCharacteristic: %@ data: %@", characteristic, [characteristic value]);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:SILCharacteristicNumberTemperatureMeasurement]]) {
            self.recentTemperatureMeasurement = [SILTemperatureMeasurement decodeTemperatureMeasurementWithData:[characteristic value]];
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.temperatureMeasurements.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SILBarGraphCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SILBarGraphCollectionViewCell class])
                                                                           forIndexPath:indexPath];
    SILTemperatureMeasurement *temperatureMeasurement = self.temperatureMeasurements[indexPath.row];

    NSRange temperatureRange;
    if (self.displayInFahrenheit) {
        temperatureRange = NSMakeRange(32, 90);
    } else {
        temperatureRange = NSMakeRange(0, 50);
    }
    [cell  configureWithTemperatureMeasurement:temperatureMeasurement
                                  isFahrenheit:self.displayInFahrenheit
                                         range:temperatureRange];
    cell.alpha = 1.0 - (0.05 * indexPath.row);

    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake(146, collectionView.bounds.size.height);
    } else {
        CGFloat screenWidth = [[[UIApplication sharedApplication] delegate] window].frame.size.width;
        return CGSizeMake((screenWidth - 10) / 5.0, collectionView.bounds.size.height);
    }
}

#pragma mark - SILDeviceSelectionViewControllerDelegate

- (void)deviceSelectionViewController:(SILDeviceSelectionViewController *)viewController didSelectPeripheral:(CBPeripheral *)peripheral {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:^{
        self.devicePopoverController = nil;

        self.connectedPeripheral = peripheral;
        self.deviceNameLabel.text = self.connectedPeripheral.name;
        [self registerForBluetoothControllerNotifications];
        [self preparePeripheral];
    }];
}

- (void)didDismissDeviceSelectionViewController {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:nil];
}

#pragma mark - WYPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)popoverController {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:nil];
    self.devicePopoverController = nil;

    [self.navigationController popViewControllerAnimated:YES];
}

@end
