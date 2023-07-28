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
#import "NSString+SILBrowserNotifications.h"
#import "SILBluetoothBrowser+Constants.h"
#import "SILDebugServicesViewController.h"

@interface SILBrowserConnectionsViewController () <UITableViewDataSource, UITableViewDelegate, SILBrowserDeviceViewCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *connectionsTableView;
@property (weak, nonatomic) IBOutlet UIView *emptyView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *controllerHeight;
@property (strong, nonatomic) SILBrowserConnectionsViewModel* viewModel;
@property (nonatomic, weak) FloatingButtonSettings *floatingButtonSettings;
@property (nonatomic, strong) SILUIScrollViewDelegate *uiScrollViewDelegate;

@end

@implementation SILBrowserConnectionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibs];
    [self hideScrollIndicators];
    [self setupScrollViewBehaviour];
    _viewModel = [SILBrowserConnectionsViewModel sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView) name:SILNotificationReloadConnectionsTableView object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.floatingButtonSettings setPresented:YES];
    self.viewModel.isActiveScrollingUp = NO;
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

- (void)setupScrollViewBehaviour {
    __weak __typeof__(self) weakSelf = self;
    self.uiScrollViewDelegate = [[SILUIScrollViewDelegate alloc] initOnHideUIElements:^(void) {
        [weakSelf.floatingButtonSettings setPresented:NO];
        weakSelf.viewModel.isActiveScrollingUp = YES;
    } onShowUIElements:^(void) {
        [weakSelf.floatingButtonSettings setPresented:YES];
        weakSelf.viewModel.isActiveScrollingUp = NO;
    }];
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
    cell.delegate = self;
    cell.viewModel = _viewModel.peripherals[indexPath.section];
    
    [cell configure];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 132.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
    [self.viewModel disconnectPeripheralWithIdentifier:cell.viewModel.discoveredPeripheral.identityKey];
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

- (void)setupFloatingButtonSettings:(FloatingButtonSettings *)settings {
    self.floatingButtonSettings = settings;
    self.floatingButtonSettings.controllerHeight = self.controllerHeight;
    [self.floatingButtonSettings setButtonText:@"Disconnect All"];
    [self.floatingButtonSettings setPresented:!self.viewModel.isActiveScrollingUp];
    [self.floatingButtonSettings setColor:[UIColor sil_regularBlueColor]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.uiScrollViewDelegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.uiScrollViewDelegate scrollViewWillBeginDragging:scrollView];
}

@end
