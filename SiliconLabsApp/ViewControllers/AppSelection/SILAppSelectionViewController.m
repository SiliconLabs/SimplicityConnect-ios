//
//  SILAppSelectionViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 17/12/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

#import "SILAppSelectionViewController.h"
#import "SILApp.h"
#import "SILAppSelectionCollectionViewCell.h"
#import "SILDeviceSelectionViewController.h"
#import "SILCentralManagerBuilder.h"
#import "SILHealthThermometerAppViewController.h"
#import "SILRetailBeaconAppViewController.h"
#import <WYPopoverController/WYPopoverController.h>
#import "WYPopoverController+SILHelpers.h"
#import "SILApp+AttributedProfiles.h"
#import "SILCalibrationViewController.h"
#import "SILBluetoothModelManager.h"
#import "SILBluetoothXMLParser.h"
#import "UIImage+SILImages.h"
#import "SILBluetoothBrowserViewController.h"
#import "SILAppSelectionInfoViewController.h"
#import "SILConstants.h"
#import "SILBluetoothBrowser+Constants.h"
#import "UIView+SILShadow.h"
#import "SILConnectedLightingViewController.h"
#if ENABLE_HOMEKIT
#import "SILHomeKitDebugDeviceViewController.h"
#endif

@interface SILAppSelectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SILDeviceSelectionViewControllerDelegate, WYPopoverControllerDelegate, SILAppSelectionInfoViewControllerDelegate, SILIOPPopupDelegate>

@property (strong, nonatomic) IBOutlet UIView *allSpace;
@property (strong, nonatomic) WYPopoverController *devicePopoverController;
@property (weak, nonatomic) IBOutlet UIStackView *tilesSpace;
@property (weak, nonatomic) IBOutlet UIView* appsView;
@property (weak, nonatomic) IBOutlet UICollectionView *appCollectionView;
@property (weak, nonatomic) IBOutlet UIImageView *infoImage;
@property (weak, nonatomic) IBOutlet UIView *aboveSpaceAreaView;
@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UILabel *navigationBarTitleLabel;
@end

@implementation SILAppSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupAppCollectionView];
    [self setupBackground];
    [self setupNavigationBar];
    [self addObseverForNotIntentionallyBackFromThermometer];
    _isDisconnectedIntentionally = NO;
    [[SILBluetoothModelManager sharedManager] populateModels];
    [self.allSpace bringSubviewToFront:self.navigationBarView];
    self.appCollectionView.bounces = NO;
}

#pragma mark - Setup View (viewDidLoad)

- (void)setupAppCollectionView {
    [self registerNibs];
    [self setupAppCollectionViewDelegates];
    [self setupAppCollectionViewAppearance];
}

- (void)registerNibs {
      [self.appCollectionView registerNib:[UINib nibWithNibName:NSStringFromClass([SILAppSelectionCollectionViewCell class]) bundle:nil] forCellWithReuseIdentifier:NSStringFromClass([SILAppSelectionCollectionViewCell class])];
}

- (void)setupAppCollectionViewDelegates {
    self.appCollectionView.dataSource = self;
    self.appCollectionView.delegate = self;
}

- (void)setupAppCollectionViewAppearance {
    self.appCollectionView.backgroundColor = [UIColor sil_backgroundColor];
    self.appCollectionView.alwaysBounceVertical = YES;
}

- (void)setupBackground {
    _allSpace.backgroundColor = [UIColor sil_backgroundColor];
    _appsView.backgroundColor = [UIColor sil_backgroundColor];
}

- (void)setupNavigationBar {
    [self setupNavigationBarBackgroundColor];
    [self setupNavigatioBarTitleLabel];
    [self addGestureRecognizerForInfoImage];
}

- (void)setupNavigationBarBackgroundColor {
    _aboveSpaceAreaView.backgroundColor = [UIColor sil_siliconLabsRedColor];
    _navigationBarView.backgroundColor = [UIColor sil_siliconLabsRedColor];
}

- (void)setupNavigatioBarTitleLabel {
    _navigationBarTitleLabel.font = [UIFont robotoMediumWithSize:SILNavigationBarTitleFontSize];
    _navigationBarTitleLabel.textColor = [UIColor sil_backgroundColor];
}

- (void)addGestureRecognizerForInfoImage {
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedInfoImage:)];
    [_infoImage addGestureRecognizer:tap];
}

- (void)tappedInfoImage:(UIGestureRecognizer *)gestureRecognizer {
        [self presentAppSelectionInfoViewController:YES];
}

#pragma mark - Setup View (viewDidAppear)

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self postClearBluetoothBrowserNotification];
    if (_isDisconnectedIntentionally) {
        [self showThermometerPopover];
    }
}

- (void)postClearBluetoothBrowserNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DisconnectAllPeripheral" object:self userInfo:nil];
}

- (void)addObseverForNotIntentionallyBackFromThermometer {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setIsDisconnectedIntentionallyFlag) name:@"NotIntentionallyBackFromThermometer" object:nil];
}

# pragma mark - Applications

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

- (void)presentCalibrationViewController:(BOOL)animated {
    SILCalibrationViewController *calibrationViewController = [[SILCalibrationViewController alloc] init];

    self.devicePopoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:calibrationViewController
                                                                                 presentingViewController:self
                                                                                                 delegate:self
                                                                                                 animated:YES];
}

- (void)showRetailBeaconAppWithApp:(SILApp *)app animated:(BOOL)animated  {
    SILRetailBeaconAppViewController *appViewController = [[SILRetailBeaconAppViewController alloc] init];
    appViewController.app = app;
    [self.navigationController pushViewController:appViewController animated:animated];
}

- (void)showBluetoothBrowserWithApp:(SILApp *)app animated:(BOOL)animated {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"SILAppBluetoothBrowser" bundle:nil];
    SILBluetoothBrowserViewController* controller = [storyboard instantiateInitialViewController];
    [self.navigationController pushViewController:controller animated:animated];
}

- (void)showAdvertiserWithApp:(SILApp *)app animated:(BOOL)animated {
    SILAdvertiserHomeWireframe* wireframe = [SILAdvertiserHomeWireframe new];
    [self.navigationController pushViewController:wireframe.viewController animated:animated];
    [wireframe releaseViewController];
}

-(void)showIOPEnterDeviceNamePopup: (SILApp *)app animated:(BOOL)animated {
    SILIOPDeviceNamePopup *popupVC = [[SILIOPDeviceNamePopup alloc] init];
    popupVC.delegate = self;
    self.devicePopoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:popupVC
                                                                                 presentingViewController:self
                                                                                                 delegate:self
                                                                                                 animated:YES];
}

- (void)showIOPTestList: (NSString * _Nonnull)text {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SILIOPTest" bundle:nil];
    SILIOPTesterViewController *iopVC = [storyboard instantiateViewControllerWithIdentifier:@"SILIOPBLETesterVC"];
    iopVC.deviceNameToSearch = text;
    [self.navigationController pushViewController:iopVC animated: YES];
}

- (void)showHomeKitDebugWithApp:(SILApp *)app animated:(BOOL)animated {
#if ENABLE_HOMEKIT
    SILHomeKitDebugDeviceViewController *appViewController = [[SILHomeKitDebugDeviceViewController alloc] init];
    appViewController.app = app;
    [self.navigationController pushViewController:appViewController animated:animated];
#endif
}

- (void)showRangeTestWithApp:(SILApp *)app animated:(BOOL)animated {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SILAppTypeRangeTest" bundle:nil];
    SILRangeTestAppViewController *viewController = [storyboard instantiateInitialViewController];
    [self.navigationController pushViewController:viewController animated:animated];
}

- (void)didSelectApp:(SILApp *)app {
    NSLog(@"didSelectItem: %@", app.title);
    switch (app.appType) {
        case SILAppTypeConnectedLighting:
        case SILAppTypeHealthThermometer:
        case SILAppTypeBlinky:
            [self presentDeviceSelectionViewControllerWithApp:app animated:YES];
            break;
        case SILAppTypeRangeTest:
            [self showRangeTestWithApp:app animated:YES];
            break;
        case SILAppTypeRetailBeacon:
            [self showRetailBeaconAppWithApp:app animated:YES];
            break;
        case SILAppBluetoothBrowser:
            [self showBluetoothBrowserWithApp:app animated:YES];
            break;
        case SILAppTypeAdvertiser:
            [self showAdvertiserWithApp:app animated:YES];
            break;
        case SILAppTypeHomeKitDebug:
            [self showHomeKitDebugWithApp:app animated:YES];
            break;
        case SILAppIopTest:
            [self showIOPEnterDeviceNamePopup:app animated:YES];
        default:
            break;
    }
}

#pragma mark - Info button

- (void)infoTileTapped:(UITapGestureRecognizer*)recognizer {
    [self presentAppSelectionInfoViewController:YES];
}

#pragma mark - Collection View for Applications

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.appsArray.count;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SILAppSelectionCollectionViewCell *cell =  [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SILAppSelectionCollectionViewCell class]) forIndexPath:indexPath];
    
    SILApp *app = self.appsArray[indexPath.row];
    [cell setFieldsInCell:app];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellsInRow = 2.0;
    CGFloat minimumLineSpacing = 16.0;
    CGFloat width = floor((self.appCollectionView.frame.size.width - self.appCollectionView.contentInset.left - self.appCollectionView.contentInset.right - self.appCollectionView.alignmentRectInsets.left - self.appCollectionView.alignmentRectInsets.right) / cellsInRow) - minimumLineSpacing;
      
    CGFloat height = 182.0;
    return CGSizeMake(width, height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    SILApp* app = self.appsArray[indexPath.row];
    [self didSelectApp:app];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 8.0;
}

- (void)deviceSelectionViewController:(SILDeviceSelectionViewController *)viewController didSelectPeripheral:(CBPeripheral *)peripheral {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:^{
        self.devicePopoverController = nil;

        if (viewController.viewModel.app.appType == SILAppTypeHealthThermometer) {
            [self runHealthThermometer:viewController forPeripheral:peripheral];
        } else if (viewController.viewModel.app.appType == SILAppTypeConnectedLighting) {
            SILConnectedLightingViewController *appViewController = [[UIStoryboard storyboardWithName:@"SILAppTypeConnectedLighting" bundle:nil] instantiateInitialViewController];
            appViewController.centralManager = viewController.centralManager;
            appViewController.connectedPeripheral = peripheral;
            [self.navigationController pushViewController:appViewController animated:YES];
        } else if (viewController.viewModel.app.appType == SILAppTypeBlinky) {
            SILAppTypeBlinkyViewController *appViewController = [[UIStoryboard storyboardWithName:@"SILAppTypeBlinky" bundle:nil] instantiateInitialViewController];
            appViewController.centralManager = viewController.centralManager;
            appViewController.connectedPeripheral = peripheral;
            [self.navigationController pushViewController:appViewController animated:YES];
        }
    }];
}

- (void)didDismissDeviceSelectionViewController {
      [self.devicePopoverController dismissPopoverAnimated:YES completion:nil];
}

- (void)runHealthThermometer:(SILDeviceSelectionViewController*)viewController forPeripheral:(CBPeripheral*)peripheral {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"SILAppTypeHealthThermometer" bundle:nil];
    UIViewController* controller = [storyboard instantiateInitialViewController];
    
    if ([controller isKindOfClass:[SILHealthThermometerAppViewController class]]) {
        SILHealthThermometerAppViewController* healthThermometerController = (SILHealthThermometerAppViewController*) controller;
        healthThermometerController.centralManager = viewController.centralManager;
        healthThermometerController.app = viewController.viewModel.app;
        healthThermometerController.connectedPeripheral = peripheral;
        [self.navigationController pushViewController:healthThermometerController animated:YES];
    }
}

- (void)presentAppSelectionInfoViewController:(BOOL)animated {
    SILAppSelectionInfoViewController *infoViewController = [[SILAppSelectionInfoViewController alloc] init];
    infoViewController.delegate = self;

    self.devicePopoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:infoViewController
                                                                                 presentingViewController:self
                                                                                                 delegate:self
                                                                                                 animated:YES];
}

#pragma mark - SILAppSelectionInfoViewControllerDelegate

- (void)didFinishInfoWithAppSelectionInfoViewController:(SILAppSelectionInfoViewController *)infoViewController {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:^{
        self.devicePopoverController = nil;
    }];
}

#pragma mark - WYPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)popoverController {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:nil];
    self.devicePopoverController = nil;
}

- (void)setIsDisconnectedIntentionallyFlag {
    _isDisconnectedIntentionally = YES;
}

- (void)showThermometerPopover {
    NSArray<SILApp*>* app = [SILApp demoApps];
    [self presentDeviceSelectionViewControllerWithApp:app[0] animated:YES];
    _isDisconnectedIntentionally = NO;
}

#pragma mark - SILIOPPopupDelegate

- (void)didTappedOKButtonWithDeviceName:(NSString *)text bluetoothState:(BOOL)bluetoothState {
    [self.devicePopoverController dismissPopoverAnimated:YES];
    self.devicePopoverController = nil;
    if (bluetoothState) {
        [self showIOPTestList:text];
    } else {
        SILBluetoothDisabledAlertObjc* bluetoothDisabledAlert = [[SILBluetoothDisabledAlertObjc alloc] initWithBluetoothDisabledAlert:SILBluetoothDisabledAlertInteroperabilityTest];
        
        [self alertWithOKButtonWithTitle:[bluetoothDisabledAlert getTitle]
                                 message:[bluetoothDisabledAlert getMessage]
                              completion:nil];
    }
}

- (void)didTappedCancelButton {
    [self.devicePopoverController dismissPopoverAnimated:YES];
    self.devicePopoverController = nil;
}

@end
