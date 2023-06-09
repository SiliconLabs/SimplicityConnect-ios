//
//  SILBluetoothBrowserViewController.m
//  BlueGecko
//
//  Created by Kamil Czajka on 30/12/2019.
//  Copyright © 2019 SiliconLabs. All rights reserved.
//

#import "SILBluetoothBrowserViewController.h"
#import "SILBrowserFilterViewControllerDelegate.h"
#import "SILDebugServicesViewController.h"
#import "SILDiscoveredPeripheralDisplayDataViewModel.h"
#import "SILBrowserFilterViewModel.h"
#import "UIImage+SILImages.h"
#import "UIColor+SILColors.h"
#import "NSString+SILBrowserNotifications.h"
#import "SILBluetoothBrowser+Constants.h"
#import "SILStoryboard+Constants.h"
#import "UIView+SILShadow.h"

@interface SILBluetoothBrowserViewController ()

@property (weak, nonatomic) IBOutlet UIView *presentationView;
@property (weak, nonatomic) IBOutlet UIView *discoveredDevicesView;
@property (weak, nonatomic) IBOutlet UITableView *browserTableView;
@property (weak, nonatomic) IBOutlet UIImageView *noDevicesFoundImageView;
@property (weak, nonatomic) IBOutlet UIStackView *noDevicesFoundStackView;
@property (weak, nonatomic) IBOutlet UILabel *noDevicesFoundLabel;

@property (strong, nonatomic) SILBrowserViewModel *browserViewModel;
@property (nonatomic, weak) FloatingButtonSettings *floatingButtonSettings;
@property (strong, nonatomic) SILBrowserTableDataSource *tableDataSource;
@property (strong, nonatomic) SILBrowserTableViewDelegate *tableDelegate;
@property (strong, nonatomic) SILBrowserPresenter *browserPresenter;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end

@implementation SILBluetoothBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViewModelAndTableManagers];
    [self setupRefreshControl];
    
    if (@available(iOS 15.0, *)) {
        self.browserTableView.sectionHeaderTopPadding = 0;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.browserViewModel.observing = YES;
    [self addObservers];
    if (!ScannerTabSettings.sharedInstance.scanningPausedByUser) {
        [self startScanning];
    }
    [self.browserViewModel applyFilters:SILBrowserFilterViewModel.sharedInstance];
    [self refreshTable];
    [self.floatingButtonSettings setPresented:YES];
    self.browserViewModel.isActiveScrollingUp = NO;
    [self.navigationController.tabBarController showTabBarAndUpdateFrames];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.browserViewModel.observing = NO;
    [self stopScanning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setupRefreshControl {
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self
                            action:@selector(clearAndReloadTable)
                  forControlEvents:UIControlEventValueChanged];
    [self.browserTableView addSubview:self.refreshControl];
}

- (void)registerForApplicationWillResignActiveNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)setupViewModelAndTableManagers {
    self.browserPresenter = [SILBrowserPresenter.alloc initWithPresentingController:self];
    
    self.browserViewModel = [[SILBrowserViewModel alloc] init];
    self.browserViewModel.delegate = self.browserPresenter;
    
    __weak __typeof__(self) weakSelf = self;
    SILUIScrollViewDelegate *uiScrollViewDelegate = [[SILUIScrollViewDelegate alloc] initOnHideUIElements:^(void) {
        [weakSelf.floatingButtonSettings setPresented:NO];
        weakSelf.browserViewModel.isActiveScrollingUp = YES;
        [weakSelf.navigationController.tabBarController hideTabBarAndUpdateFrames];
    } onShowUIElements:^(void) {
        [weakSelf.floatingButtonSettings setPresented:YES];
        weakSelf.browserViewModel.isActiveScrollingUp = NO;
        [weakSelf.navigationController.tabBarController showTabBarAndUpdateFrames];
    }];
    
    self.tableDelegate = [SILBrowserTableViewDelegate.alloc initWithBrowserViewModel:self.browserViewModel
                                                                uiScrollViewDelegate:uiScrollViewDelegate];
    self.tableDataSource = [SILBrowserTableDataSource.alloc initWithBrowserViewModel:self.browserViewModel
                                                                        cellDelegate:self.tableDelegate];
    self.browserTableView.dataSource = self.tableDataSource;
    self.browserTableView.delegate = self.tableDelegate;
}

- (void)addObservers {
    [self addObserversForReloadBrowserTableView];
    [self addObserverForDisplayToastResponse];
    [self registerForApplicationWillResignActiveNotification];
}

- (void)addObserversForReloadBrowserTableView {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable) name:SILNotificationReloadBrowserTable object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:SILNotificationReloadConnectionsTableView object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:SILNotificationRefreshBrowserTable object:nil];
}

- (void)reloadTable {
    [self.browserTableView reloadData];
    [self setScanningAppearance];
}

#pragma mark - Nav bar buttons

- (void)filterButtonTapped {
    [self.browserPresenter presentFilterWithFilterDelegate:self.browserViewModel];
}

- (void)sortButtonTapped {
    [self.browserViewModel sortRSSIWithAscending:NO];
}

- (void)mapButtonTapped {
    [self.browserPresenter presentMappings];
}

#pragma mark - Scanning

- (void)setScanningAppearance {
    BOOL isScanning = self.browserViewModel.isScanning;
    
    NSString *buttonText = TitleForScanningButtonWhenIsNotScanning;
    UIColor *buttonColor = UIColor.sil_regularBlueColor;
    if (isScanning) {
        buttonText = TitleForScanningButtonDuringScanning;
        buttonColor = UIColor.sil_siliconLabsRedColor;
    }
    
    [self.floatingButtonSettings setButtonText:buttonText];
    [self.floatingButtonSettings setColor:buttonColor];
    [self.floatingButtonSettings setPresented:!self.browserViewModel.isActiveScrollingUp];
    
    [self displayNoDeviceViewIfNeeded];
}

- (void)scanningButtonWasTapped {
    [self.browserViewModel scanningButtonTapped];
    [self setScanningAppearance];
}

- (void)startScanning {
    [self.browserViewModel startScanning];
    [self setScanningAppearance];
}

- (void)stopScanning {
    [self.browserViewModel stopScanning];
    [self setScanningAppearance];
}

#pragma mark - Notification Methods

- (void)applicationWillResignActive:(NSNotification*)notification {
    [self stopScanning];
}

- (void)refreshTable {
    for (id<SILConfigurableCell> cell in self.browserTableView.visibleCells) {
        [cell configure];
    }
}

- (void)displayNoDeviceViewIfNeeded {
    self.noDevicesFoundLabel.text = self.browserViewModel.isScanning ? ActiveScanningText : DisabledScanningText;
    [self.noDevicesFoundStackView setHidden:self.browserViewModel.isContentAvailable];
    
    if (self.browserViewModel.isScanning) {
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fromValue = [NSNumber numberWithFloat:0.0f];
        animation.toValue = [NSNumber numberWithFloat: 2*M_PI];
        animation.duration = 5.0f;
        animation.repeatCount = INFINITY;
        [self.noDevicesFoundImageView.layer addAnimation:animation forKey:@"SpinAnimation"];
    } else {
        [self.noDevicesFoundImageView.layer removeAllAnimations];
    }
}

- (void)clearAndReloadTable {
    [self.refreshControl endRefreshing];
    [self stopScanning];
    [self.browserViewModel removeAllDiscoveredPeripherals];
    [self reloadTable];
    [self startScanning];
}

- (void)setupFloatingButtonSettings:(FloatingButtonSettings *)settings {
    self.floatingButtonSettings = settings;
    [self setScanningAppearance];
}

@end
