//
//  SILBrowserConnectionsViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 14/01/2020.
//  Copyright © 2020 SiliconLabs. All rights reserved.
//

#import "SILBrowserConnectionsViewController.h"
#import "SILBrowserConnectionsTableViewCell.h"
#import "UIImage+SILImages.h"
#import "SILBrowserConnectionsViewModel.h"
#import "SILConnectedPeripheralDataModel.h"
#import "NSString+SILBrowserNotifications.h"
#import "SILBluetoothBrowser+Constants.h"
#import "SILDebugServicesViewController.h"

@interface SILBrowserConnectionsViewController () <UITableViewDataSource, UITableViewDelegate, SILBrowserDeviceViewCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *connectionsTableView;
@property (weak, nonatomic) IBOutlet UIView *emptyView;
@property (strong, nonatomic) SILBrowserConnectionsViewModel* viewModel;

@end

@implementation SILBrowserConnectionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    [self hideScrollIndicators];
    _viewModel = [SILBrowserConnectionsViewModel sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView) name:SILNotificationReloadConnectionsTableView object:nil];
}

- (void)disconnectAllTapped {
    [_viewModel disconnectAllPeripheral];
    [_delegate connectionsViewBackButtonPressed];
}

- (void)registerNibs {
    _connectionsTableView.delegate = self;
    _connectionsTableView.dataSource = self;
    [_connectionsTableView registerNib:[UINib nibWithNibName:NSStringFromClass([SILBrowserConnectionsTableViewCell class]) bundle:nil] forCellReuseIdentifier:@"SILConnectedDeviceViewCell"];
}

- (void)hideScrollIndicators {
    [_connectionsTableView setShowsHorizontalScrollIndicator:NO];
    [_connectionsTableView setShowsVerticalScrollIndicator:NO];
}

# pragma mark - Log Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger amountOfPeripherals = [_viewModel.peripherals count];
    
    self.emptyView.hidden = amountOfPeripherals > 0;
    self.connectionsTableView.hidden = amountOfPeripherals == 0;
    
    return amountOfPeripherals;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILBrowserDeviceViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SILConnectedDeviceViewCell" forIndexPath:indexPath];
    SILConnectedPeripheralDataModel* peripheralModel = _viewModel.peripherals[indexPath.section];
    cell.delegate = self;
    SILDiscoveredPeripheral *discoveredPeripheral = peripheralModel.discoveredPeripheral;
    NSString* cellIdentifier = discoveredPeripheral.identityKey;
    cell.cellIdentifier = cellIdentifier;
    NSString *deviceName = discoveredPeripheral.advertisedLocalName;
    cell.rssiLabel.text = discoveredPeripheral.rssiDescription;
    cell.title.text = deviceName;
    if ([deviceName isEqualToString:EmptyText] || deviceName == nil) {
        cell.title.text = DefaultDeviceName;
    }
    
    cell.uuidLabel.text = discoveredPeripheral.uuid.UUIDString;
    long long advertisingIntervalsInMS = discoveredPeripheral.advertisingInterval * 1000;
    
    NSMutableString* advertisingIntervalText = [NSMutableString stringWithFormat:@"%lld", advertisingIntervalsInMS];
    [advertisingIntervalText appendString:AppendingMS];
    
    cell.advertisingIntervalLabel.text = advertisingIntervalText;
    
    if (discoveredPeripheral.isConnectable) {
        cell.connectableLabel.text = SILDiscoveredPeripheralConnectableDevice;
        [cell setDisconnectButtonAppearance];
    } else {
        cell.connectableLabel.text = SILDiscoveredPeripheralNonConnectableDevice;
        [cell setHiddenButtonAppearance];
    }
    cell.beaconLabel.text = discoveredPeripheral.beacon.name;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 132.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_viewModel updateConnectionsView:indexPath.section];
    [self presentDetailsViewControllerWithPeripheral:self.viewModel.peripherals[indexPath.section].discoveredPeripheral.peripheral];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [SILTableViewWithShadowCells tableView:tableView willDisplay:cell forRowAt:indexPath];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [SILTableViewWithShadowCells tableView:tableView viewForHeaderInSection:section withHeight: 20.0];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 12;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [self numberOfSectionsInTableView:tableView] - 1 == section ? [SILTableViewWithShadowCells tableView:tableView viewForFooterInSection:section withHeight:LastFooterHeight] : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self numberOfSectionsInTableView:tableView] - 1 == section ? LastFooterHeight : 0;
}

- (void)reloadTableView {
    [_connectionsTableView reloadData];
}

- (void)connectButtonTappedInCell:(SILBrowserDeviceViewCell * _Nullable)cell {
    [self.viewModel disconnectPeripheralWithIdentifier:cell.cellIdentifier];
}

- (void)presentDetailsViewControllerWithPeripheral:(CBPeripheral *)peripheral {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserDetails bundle:nil];
    SILBrowserDetailsTabBarController * detailsTabBarController = [storyboard instantiateViewControllerWithIdentifier: @"SILDetailsTabBarController"];
    SILDebugServicesViewController* detailsVC = detailsTabBarController.viewControllers[0];
    detailsVC.peripheral = peripheral;
    detailsVC.centralManager = self.viewModel.centralManager;
    SILLocalGattServerViewController* localGattServerVC = detailsTabBarController.viewControllers[1];
    localGattServerVC.peripheral = peripheral;
    localGattServerVC.centralManager = self.viewModel.centralManager;
    [self.navigationController pushViewController:detailsTabBarController animated:YES];
}

@end
