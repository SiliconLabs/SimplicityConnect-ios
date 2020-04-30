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
#if WIRELESS
#import "SILConnectedLightingViewController.h"
#endif
#if ENABLE_HOMEKIT
#import "SILHomeKitDebugDeviceViewController.h"
#endif

@interface SILAppSelectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SILDeviceSelectionViewControllerDelegate, SILRangeTestModeSelectionViewControllerDelegate, WYPopoverControllerDelegate, SILAppSelectionInfoViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView *allSpace;
@property (strong, nonatomic) WYPopoverController *devicePopoverController;
@property (weak, nonatomic) IBOutlet UIStackView *tilesSpace;
@property (weak, nonatomic) IBOutlet UIView* appsView;
@property (weak, nonatomic) IBOutlet UICollectionView *appCollectionView;
@property (weak, nonatomic) IBOutlet UIView *selectedIndicatorView;
@property (weak, nonatomic) IBOutlet UIView *unselectedIndicatorView;
@property (weak, nonatomic) IBOutlet UIView *afterSelectedIndicatiorView;
@property (weak, nonatomic) IBOutlet UIImageView *infoImage;
@property (weak, nonatomic) IBOutlet UIView *aboveSpaceAreaView;
@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UILabel *navigationBarTitleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *beforeSelectedConstraintIphone;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *afterSelectedConstraintIphone;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *beforeSelectedConstraintIpad;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *afterSelectedConstraintIpad;
@property BOOL isDisconnectedIntentionally;
@end

@implementation SILAppSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupAppCollectionView];
    [self setupSelectionIndicator];
    [self setupBackground];
    [self setupNavigationBar];
    [self addObseverForNotIntentionallyBackFromThermometer];
    _isDisconnectedIntentionally = NO;
    [[SILBluetoothModelManager sharedManager] populateModels];
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

- (void)setupSelectionIndicator {
    _selectedIndicatorView.backgroundColor = [UIColor sil_strongBlueColor];
    _unselectedIndicatorView.backgroundColor = [UIColor sil_backgroundColor];
    _afterSelectedIndicatiorView.backgroundColor = [UIColor sil_backgroundColor];
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
    [self setConstraintsForSelectionIndicator];
    [self postClearBluetoothBrowserNotification];
    if (_isDisconnectedIntentionally) {
        [self showThermometerPopover];
    }
}

- (void)setConstraintsForSelectionIndicator {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [NSLayoutConstraint deactivateConstraints:@[_beforeSelectedConstraintIpad, _afterSelectedConstraintIpad]];
        [NSLayoutConstraint activateConstraints:@[_beforeSelectedConstraintIphone, _afterSelectedConstraintIphone]];
    } else {
        [NSLayoutConstraint deactivateConstraints:@[_beforeSelectedConstraintIphone, _afterSelectedConstraintIphone]];
        [NSLayoutConstraint activateConstraints:@[_beforeSelectedConstraintIpad, _afterSelectedConstraintIpad]];
    }
    [self.view layoutIfNeeded];
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

- (void)presentRangeTestModeSelectionViewControllerWithApp:(SILApp *)app centralManager:(SILCentralManager*)manager peripheral:(CBPeripheral *)peripheral animated:(BOOL)animated {
    SILRangeTestModeSelectionViewController *selectionViewController = [[SILRangeTestModeSelectionViewController alloc] init];
    
    selectionViewController.app = app;
    selectionViewController.delegate = self;
    selectionViewController.peripheral = [[SILRangeTestPeripheral alloc] initWithPeripheral:peripheral andCentralManager:manager];
    
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

- (void)showHomeKitDebugWithApp:(SILApp *)app animated:(BOOL)animated {
#if ENABLE_HOMEKIT
    SILHomeKitDebugDeviceViewController *appViewController = [[SILHomeKitDebugDeviceViewController alloc] init];
    appViewController.app = app;
    [self.navigationController pushViewController:appViewController animated:animated];
#endif
}

- (void)showRangeTestWithApp:(SILApp *)app forPeripheral:(SILRangeTestPeripheral *)peripheral andBoardInfo:(SILRangeTestBoardInfo *)boardInfo withMode:(SILRangeTestMode)mode animated:(BOOL)animated {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"RangeTestStoryboard" bundle:nil];
    SILRangeTestAppViewController *viewController = [storyboard instantiateInitialViewController];
    SILRangeTestAppViewModel *viewModel = [[SILRangeTestAppViewModel alloc] initWithMode:mode peripheral:peripheral andBoardInfo:boardInfo];
        
    viewController.app = app;
    viewController.viewModel = viewModel;

    [self.navigationController pushViewController:viewController animated:animated];
}

- (void)didSelectApp:(SILApp *)app {
    NSLog(@"didSelectItem: %@", app.title);
    switch (app.appType) {
        case SILAppTypeConnectedLighting:
        case SILAppTypeHealthThermometer:
        case SILAppTypeRangeTest:
            [self presentDeviceSelectionViewControllerWithApp:app animated:YES];
            break;
        case SILAppTypeRetailBeacon:
            [self showRetailBeaconAppWithApp:app animated:YES];
            break;
        case SILAppBluetoothBrowser:
            [self showBluetoothBrowserWithApp:app animated:YES];
            break;
        case SILAppTypeHomeKitDebug:
            [self showHomeKitDebugWithApp:app animated:YES];
            break;
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
      
    CGFloat height = 162.0;
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
#if WIRELESS
            SILConnectedLightingViewController *appViewController = [[SILConnectedLightingViewController alloc] init];
            appViewController.centralManager = viewController.centralManager;
            appViewController.connectedPeripheral = peripheral;
            [self.navigationController pushViewController:appViewController animated:YES];
#endif
        } else if (viewController.viewModel.app.appType == SILAppTypeRangeTest) {
            [self presentRangeTestModeSelectionViewControllerWithApp:viewController.viewModel.app
                                                      centralManager:viewController.centralManager
                                                          peripheral:peripheral
                                                            animated:YES];
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

#pragma mark - SILRangeTestModeSelectionViewControllerDelegate

-(void)didRangeTestModeSelectedForApp:(SILApp *)app peripheral:(SILRangeTestPeripheral *)peripheral andBoardInfo:(SILRangeTestBoardInfo *)boardInfo selectedMode:(enum SILRangeTestMode)mode {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:^{
        self.devicePopoverController = nil;
        [self showRangeTestWithApp:app forPeripheral:peripheral andBoardInfo:boardInfo withMode:mode animated:YES];
    }];
}

- (void)didDismissRangeTestModeSelectionViewController {
    [self.devicePopoverController dismissPopoverAnimated:YES completion:nil];
    self.devicePopoverController = nil;
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



@end
