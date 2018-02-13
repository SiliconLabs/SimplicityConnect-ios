//
//  SILAppSelectionViewController.m
//  SiliconLabsApp
//
//  Created by Colden Prime on 1/13/15.
//  Copyright (c) 2015 SiliconLabs. All rights reserved.
//

#import "SILAppSelectionViewController.h"
#import "SILApp.h"
#import "SILAppSelectionTableViewCell.h"
#import "SILDeviceSelectionViewController.h"
#import "SILCentralManagerBuilder.h"
#import "SILHealthThermometerAppViewController.h"
#import "SILRetailBeaconAppViewController.h"
#import "SILDebugDeviceViewController.h"
#import <WYPopoverController/WYPopoverController.h>
#import "WYPopoverController+SILHelpers.h"
#import "SILApp+AttributedProfiles.h"
#import "SILAppSelectionHelpViewController.h"
#import "SILKeyFobViewController.h"
#import "SILCalibrationViewController.h"
#import "SILBluetoothModelManager.h"
#import "SILBluetoothXMLParser.h"
#if WIRELESS
#import "SILConnectedLightingViewController.h"
#endif
#if ENABLE_HOMEKIT
#import "SILHomeKitDebugDeviceViewController.h"
#endif

@interface SILAppSelectionViewController () <UITableViewDataSource, UITableViewDelegate, SILDeviceSelectionViewControllerDelegate, SILAppSelectionHelpViewControllerDelegate, WYPopoverControllerDelegate>

@property (strong, nonatomic) NSArray *appsArray;
@property (strong, nonatomic) WYPopoverController *devicePopoverController;

@property (weak, nonatomic) IBOutlet UITableView *appTableView;

- (IBAction)didTapHelpButton:(id)sender;

@end

@implementation SILAppSelectionViewController

- (void)presentCalibrationViewController:(BOOL)animated {
    SILCalibrationViewController *calibrationViewController = [[SILCalibrationViewController alloc] init];

    self.devicePopoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:calibrationViewController
                                                                                 presentingViewController:self
                                                                                                 delegate:self
                                                                                                 animated:YES];
}

- (void)presentDeviceSelectionViewControllerWithApp:(SILApp *)app animated:(BOOL)animated {
    SILDeviceSelectionViewModel *viewModel = [[SILDeviceSelectionViewModel alloc] initWithAppType:app];
    SILDeviceSelectionViewController *selectionViewController = [[SILDeviceSelectionViewController alloc] initWithDeviceSelectionViewModel:viewModel];
    
    selectionViewController.centralManager = [SILCentralManagerBuilder buildCentralManagerWithAppType:app.appType];
    selectionViewController.delegate = self;

    self.devicePopoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:selectionViewController
                                                                                 presentingViewController:self
                                                                                                 delegate:self
                                                                                                 animated:YES];
}

- (void)presentAppSelectionHelpViewController:(BOOL)animated {
    SILAppSelectionHelpViewController *helpViewController = [[SILAppSelectionHelpViewController alloc] init];
    helpViewController.delegate = self;

    self.devicePopoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:helpViewController
                                                                                 presentingViewController:self
                                                                                                 delegate:self
                                                                                                 animated:YES];
}

- (void)showKeyFobAppWithApp:(SILApp *)app animated:(BOOL)animated {
    SILKeyFobViewController *appViewController = [[SILKeyFobViewController alloc] init];
    appViewController.app = app;
    [self.navigationController pushViewController:appViewController animated:animated];
}

- (void)showRetailBeaconAppWithApp:(SILApp *)app animated:(BOOL)animated  {
    SILRetailBeaconAppViewController *appViewController = [[SILRetailBeaconAppViewController alloc] init];
    appViewController.app = app;
    [self.navigationController pushViewController:appViewController animated:animated];
}

- (void)showDebugWithApp:(SILApp *)app animated:(BOOL)animated {
    SILDebugDeviceViewController *appViewController = [[SILDebugDeviceViewController alloc] init];
    appViewController.app = app;
    [self.navigationController pushViewController:appViewController animated:animated];
}

- (void)showHomeKitDebugWithApp:(SILApp *)app animated:(BOOL)animated {
#if ENABLE_HOMEKIT
    SILHomeKitDebugDeviceViewController *appViewController = [[SILHomeKitDebugDeviceViewController alloc] init];
    appViewController.app = app;
    [self.navigationController pushViewController:appViewController animated:animated];
#endif
}

- (void)didSelectApp:(SILApp *)app {
    NSLog(@"didSelectItem: %@", app.title);
    switch (app.appType) {
        case SILAppTypeConnectedLighting:
        case SILAppTypeHealthThermometer:
            [self presentDeviceSelectionViewControllerWithApp:app animated:YES];
            break;
        case SILAppTypeRetailBeacon:
            [self showRetailBeaconAppWithApp:app animated:YES];
            break;
        case SILAppTypeKeyFob:
            [self showKeyFobAppWithApp:app animated:YES];
            break;
        case SILAppTypeDebug:
            [self showDebugWithApp:app animated:YES];
            break;
        case SILAppTypeHomeKitDebug:
            [self showHomeKitDebugWithApp:app animated:YES];
            break;
        default:
            break;
    }
}

#pragma mark - Button Actions

- (IBAction)didTapHelpButton:(id)sender {
    [self presentAppSelectionHelpViewController:YES];
}

#pragma mark - Secret Button

- (void)setupSecretButton {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [button setTitle:@"Calibration" forState:UIControlStateHighlighted];
    [button sizeToFit];
    [button addTarget:self action:@selector(didTapSecretButton:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)didTapSecretButton:(id)sender {
    [self presentCalibrationViewController:YES];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Bluetooth Applications";

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"Application List" : @" "
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self.navigationController
                                                                            action:@selector(popNavigationItemAnimated:)];
    [self.appTableView registerNib:[UINib nibWithNibName:NSStringFromClass([SILAppSelectionTableViewCell class]) bundle:nil]
              forCellReuseIdentifier:NSStringFromClass([SILAppSelectionTableViewCell class])];
    self.appsArray = [SILApp allApps];
    [self setupSecretButton];
    
    [[SILBluetoothModelManager sharedManager] populateModels];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.appsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILAppSelectionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILAppSelectionTableViewCell class])
                                                                          forIndexPath:indexPath];

    SILApp *app = self.appsArray[indexPath.row];
    cell.titleLabel.text = app.title;
    cell.descriptionLabel.text = app.appDescription;
    cell.profileLabel.attributedText = [app showcasedProfilesAttributedStringWithUserInterfaceIdiom:UI_USER_INTERFACE_IDIOM()];;
    cell.iconImageView.image = [UIImage imageNamed:app.imageName];

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CGRectGetHeight(self.appTableView.bounds) / self.appsArray.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    SILApp *app = self.appsArray[indexPath.row];

    [self didSelectApp:app];
}

#pragma mark - SILDeviceSelectionViewControllerDelegate

- (void)deviceSelectionViewController:(SILDeviceSelectionViewController *)viewController didSelectPeripheral:(CBPeripheral *)peripheral {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:^{
        self.devicePopoverController = nil;

        if (viewController.viewModel.app.appType == SILAppTypeHealthThermometer) {
            SILHealthThermometerAppViewController *appViewController = [[SILHealthThermometerAppViewController alloc] init];
            appViewController.centralManager = viewController.centralManager;
            appViewController.app = viewController.viewModel.app;
            appViewController.connectedPeripheral = peripheral;
            [self.navigationController pushViewController:appViewController animated:YES];
        } else if (viewController.viewModel.app.appType == SILAppTypeConnectedLighting) {
#if WIRELESS
            SILConnectedLightingViewController *appViewController = [[SILConnectedLightingViewController alloc] init];
            appViewController.centralManager = viewController.centralManager;
            appViewController.connectedPeripheral = peripheral;
            [self.navigationController pushViewController:appViewController animated:YES];
#endif
        }
    }];
}

- (void)didDismissDeviceSelectionViewController {
      [self.devicePopoverController dismissPopoverAnimated:YES completion:nil];
}

#pragma mark - SILAppSelectionHelpViewControllerDelegate

- (void)didFinishHelpWithAppSelectionHelpViewController:(SILAppSelectionHelpViewController *)helpViewController {
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
