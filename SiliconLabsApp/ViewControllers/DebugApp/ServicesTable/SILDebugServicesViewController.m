//
//  SILDeviceServicesViewController.m
//  SiliconLabsApp
//
//  Created by Eric Peterson on 10/2/15.
//  Copyright © 2015 SiliconLabs. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "SILCentralManager.h"
#import "SILDebugServicesViewController.h"
#import "SILServiceTableModel.h"
#import "SILCharacteristicTableModel.h"
#import "SILDescriptorTableModel.h"
#import "SILDebugServiceTableViewCell.h"
#import "SILDebugCharacteristicTableViewCell.h"
#import "SILDebugHeaderView.h"
#import "SILDiscoveredPeripheral.h"
#import "SILBluetoothModelManager.h"
#import "SILCharacteristicFieldBuilder.h"
#import "SILEnumerationFieldRowModel.h"
#import "SILBitFieldFieldModel.h"
#import "SILBitRowModel.h"
#import "SILValueFieldRowModel.h"
#import "SILDebugCharacteristicValueFieldTableViewCell.h"
#import "SILDebugCharacteristicToggleFieldTableViewCell.h"
#import "SILDebugCharacteristicEnumerationFieldTableViewCell.h"
#import "SILDebugCharacteristicEncodingFieldTableViewCell.h"
#import "SILDebugSpacerTableViewCell.h"
#import <WYPopoverController/WYPopoverController.h>
#import "WYPopoverController+SILHelpers.h"
#import "SILCharacteristicFieldValueResolver.h"
#import "SILDebugCharacteristicEnumerationListViewController.h"
#import "SILDebugCharacteristicEncodingViewController.h"
#import "SILCharacteristicEditEnabler.h"
#import "SILValueFieldEditorViewController.h"
#import "SILEncodingPseudoFieldRowModel.h"
#import <Crashlytics/Crashlytics.h>
#import "UIViewController+Containment.h"
#import <PureLayout/PureLayout.h>
#import "CBPeripheral+Services.h"
#import "SILUUIDProvider.h"
#import "SILOTAUICoordinator.h"
#import "SILLogDataModel.h"
#import "SILConnectedPeripheralDataModel.h"
#import "BlueGecko.pch"
#import "SILBrowserLogViewController.h"
#import "SILBrowserConnectionsViewController.h"
#import "UIImage+SILImages.h"
#import "SILBrowserConnectionsViewModel.h"
#import "NSString+SILBrowserNotifications.h"
#import "SILBluetoothBrowserExpandableViewManager.h"
#import "SILBluetoothBrowser+Constants.h"

static NSString * const kSpacerCellIdentifieer = @"spacer";
static NSString * const kCornersCellIdentifieer = @"corners";
static NSString * const kOTAButtonTitle = @"OTA";
static NSString * const kScanningForPeripheralsMessage = @"Loading...";

static float kTableRefreshInterval = 1;

@interface SILDebugServicesViewController () <UITableViewDelegate, UITableViewDataSource, CBPeripheralDelegate, UIScrollViewDelegate, SILDebugPopoverViewControllerDelegate, WYPopoverControllerDelegate, SILCharacteristicEditEnablerDelegate, SILOTAUICoordinatorDelegate, SILDebugCharacteristicCellDelegate, SILServiceCellDelegate, SILBrowserLogViewControllerDelegate, SILBrowserConnectionsViewControllerDelegate, SILDebugServicesMenuViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (weak, nonatomic) IBOutlet UIImageView *rssiImageView;
@property (strong, nonatomic) NSMutableArray *allServiceModels;
@property (strong, nonatomic) NSArray *modelsToDisplay;
@property (nonatomic) BOOL isUpdatingFirmware;
@property (nonatomic) BOOL tableNeedsRefresh;
@property (strong, nonatomic) NSTimer *tableRefreshTimer;
@property (strong, nonatomic) NSTimer *rssiTimer;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) SILOTAUICoordinator *otaUICoordinator;
@property (weak, nonatomic) IBOutlet UIView *discoveredDevicesView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) WYPopoverController *popoverController;
@property (weak, nonatomic) IBOutlet UIView *presentationView;
@property (strong, nonatomic) SILDebugHeaderView *headerView;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (weak, nonatomic) IBOutlet UIView *aboveSpaceSaveAreaView;
@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UIButton *connectionsButton;
@property (weak, nonatomic) IBOutlet UIButton *logButton;
@property (weak, nonatomic) IBOutlet UIView *expandableControllerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *expandableControllerHeight;
@property (strong, nonatomic) SILBrowserConnectionsViewModel* connectionsViewModel;
@property (strong, nonatomic) SILBluetoothBrowserExpandableViewManager* browserExpandableViewManager;
@property (weak, nonatomic) IBOutlet UIView *menuContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *menuOptionHeight;

@end

@implementation SILDebugServicesViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.menuButton setHidden:YES];
    [self.menuContainer setHidden:YES];
    [self registerForNotifications];
    [self registerNibsAndSetUpSizing];
    [self startServiceSearch];
    [self setupRefreshControl];
    [self setupNavigationBar];
    [self setupBrowserExpandableViewManager];
    [self setupButtonsTabBar];
    [self setupConnectionsViewModel];
    [self addObserverForUpdateConnectionsButtonTitle];
    [self updateConnectionsButtonTitle];
    [self hideRSSIView];
    self.isUpdatingFirmware = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.deviceNameLabel.text = self.peripheral.name;
    [self installRSSITimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self dismissPopoverIfExist];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dismissPopoverIfExist {
    if (self.popoverController) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
}

- (IBAction)backButtonWasTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)performOTAAction {
    self.isUpdatingFirmware = YES;
    self.otaUICoordinator = [[SILOTAUICoordinator alloc] initWithPeripheral:self.peripheral
                                                            centralManager:self.centralManager
                                                       presentingViewController:self];
    self.otaUICoordinator.delegate = self;
    [self.otaUICoordinator initiateOTAFlow];
}


- (void)setupNavigationBar {
    self.aboveSpaceSaveAreaView.backgroundColor = [UIColor sil_siliconLabsRedColor];
    self.navigationBarView.backgroundColor = [UIColor sil_siliconLabsRedColor];
}

- (void)setupBrowserExpandableViewManager {
    self.cornerRadius = CornerRadiusStandardValue;
    self.browserExpandableViewManager = [[SILBluetoothBrowserExpandableViewManager alloc] initWithOwnerViewController:self];
    [self.browserExpandableViewManager setReferenceForPresentationView:self.presentationView andDiscoveredDevicesView:self.discoveredDevicesView];
    [self.browserExpandableViewManager setReferenceForExpandableControllerView:self.expandableControllerView andExpandableControllerHeight:self.expandableControllerHeight];
    [self.browserExpandableViewManager setValueForCornerRadius:self.cornerRadius];
}
 
- (void)setupButtonsTabBar {
    [self.browserExpandableViewManager setupButtonsTabBarWithLog:self.logButton connections:self.connectionsButton];
}

- (void)setIsUpdatingFirmware:(BOOL)isUpdatingFirmware {
    _isUpdatingFirmware = isUpdatingFirmware;
    if (_isUpdatingFirmware == NO) {
        [self addObserverForDisplayToastResponse];
        [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationDisplayToastRequest object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:SILNotificationDisplayToastResponse object:nil];
    }
}

#pragma mark - setup

- (void)registerNibsAndSetUpSizing {
    NSString *characteristicValueFieldCellClassString = NSStringFromClass([SILDebugCharacteristicValueFieldTableViewCell class]);
    [self.tableView registerNib:[UINib nibWithNibName:characteristicValueFieldCellClassString bundle:nil] forCellReuseIdentifier:characteristicValueFieldCellClassString];
    
    NSString *characteristicToggleFieldCellClassString = NSStringFromClass([SILDebugCharacteristicToggleFieldTableViewCell class]);
    [self.tableView registerNib:[UINib nibWithNibName:characteristicToggleFieldCellClassString bundle:nil] forCellReuseIdentifier:characteristicToggleFieldCellClassString];
    
    NSString *characteristicEnumerationFieldCellClassString = NSStringFromClass([SILDebugCharacteristicEnumerationFieldTableViewCell class]);
    [self.tableView registerNib:[UINib nibWithNibName:characteristicEnumerationFieldCellClassString bundle:nil] forCellReuseIdentifier:characteristicEnumerationFieldCellClassString];
    
    NSString *characteristicEncodingFieldCellClassString = NSStringFromClass([SILDebugCharacteristicEncodingFieldTableViewCell class]);
    [self.tableView registerNib:[UINib nibWithNibName:characteristicEncodingFieldCellClassString bundle:nil] forCellReuseIdentifier:characteristicEncodingFieldCellClassString];
    
    NSString *spacerCellClassString = NSStringFromClass([SILDebugSpacerTableViewCell class]);
    [self.tableView registerNib:[UINib nibWithNibName:spacerCellClassString bundle:nil] forCellReuseIdentifier:spacerCellClassString];
}

- (void)startServiceSearch {
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:nil];
}

- (void)setupRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefreshServices:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl sendSubviewToBack:self.refreshControl];
    self.refreshControl.bounds = CGRectMake(self.refreshControl.bounds.origin.x, self.refreshControl.bounds.origin.y + 50.0, 100.0, 100.0);
}

- (void)setupConnectionsViewModel {
    self.connectionsViewModel = [SILBrowserConnectionsViewModel sharedInstance];
}

- (void)hideRSSIView {
    [self.rssiLabel setHidden:YES];
    [self.rssiImageView setHidden:YES];
}

#pragma mark -Lazy Intanstiation

- (NSMutableArray *)allServiceModels {
    if (!_allServiceModels) {
        _allServiceModels = [[NSMutableArray alloc] init];
    }
    return _allServiceModels;
}

- (NSArray *)modelsToDisplay {
    if (!_modelsToDisplay) {
        _modelsToDisplay = [[NSArray alloc] init];
    }
    return _modelsToDisplay;
}

#pragma mark - Menu

- (IBAction)menuButtonWasTapped:(id)sender {
    [self showMenu];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"OpenMenuSegue"]) {
        SILDebugServicesMenuViewController* menuVC = (SILDebugServicesMenuViewController*) segue.destinationViewController;
        menuVC.delegate = self;
        [menuVC addMenuOptionWithTitle:@"OTA DFU" completion:^{
            [self performOTAAction];
        }];
        self.menuOptionHeight.constant = [menuVC getMenuOptionHeight];
    }
}

- (void)performActionForMenuOptionUsing:(void (^ NS_NOESCAPE)(void))completion {
    [self hideMenu];
    completion();
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self hideMenu];
}

- (void)showMenu {
    [self.menuContainer setHidden:NO];
    self.tableView.userInteractionEnabled = NO;
}

- (void)hideMenu {
    [self.menuContainer setHidden:YES];
    self.tableView.userInteractionEnabled = YES;
}

#pragma mark - Expandable Controllers

- (IBAction)connectionsButtonTapped:(id)sender {
    SILBrowserConnectionsViewController* connectionsVC = [self.browserExpandableViewManager connectionsButtonWasTappedAction];
    if (connectionsVC.delegate == nil) {
        connectionsVC.delegate = self;
    }
}

- (IBAction)logButtonWasTapped:(id)sender {
    SILBrowserLogViewController* logVC = [self.browserExpandableViewManager logButtonWasTappedAction];
    if (logVC.delegate == nil) {
        logVC.delegate = self;
    }
}

#pragma mark - Actions

// SLMAIN-333 - This is a workaround to disconnect and reconnect to the peripheral when dynamic services/characteristics are toggled.
// If this isn't done, services cannot be refreshed more than once.
- (void)handleRefreshServices: (UIRefreshControl *)sender {
    void (^serviceSearch)(void) = ^(void) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self startServiceSearch];
            [self.tableView setHidden:NO];
        });
    };

    if (self.refreshControl == sender) {
        self.allServiceModels = [[NSMutableArray alloc] init];
        [self.centralManager connectToDiscoveredPeripheral: [self.centralManager discoveredPeripheralForPeripheral:self.peripheral]];
        [self.tableView setHidden:YES];
        serviceSearch();
    }
}

#pragma mark - SILOTAUICoordinatorDelegate

- (void)otaUICoordinatorDidFishishOTAFlow:(SILOTAUICoordinator *)coordinator {
    [self.navigationController popViewControllerAnimated:YES];
    self.isUpdatingFirmware = NO;
}

- (void)otaUICoordinatorDidCancelOTAFlow:(SILOTAUICoordinator *)coordinator {
    self.isUpdatingFirmware = NO;
}

#pragma mark - Notifications

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDisconnectPeripheralNotifcation:)
                                                 name:SILCentralManagerDidDisconnectPeripheralNotification
                                               object:self.centralManager];
}

- (void)addObserverForUpdateConnectionsButtonTitle {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectionsButtonTitle) name:SILNotificationReloadConnectionsTableView object:nil];
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

#pragma mark - Notification Methods

- (void)didDisconnectPeripheralNotifcation:(NSNotification *)notification {
    NSString* uuid = (NSString*)notification.userInfo[SILNotificationKeyUUID];
    
    if ([uuid isEqualToString:self.peripheral.identifier.UUIDString]) {
        if (!self.isUpdatingFirmware) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)updateConnectionsButtonTitle {
    NSUInteger connections = [self.connectionsViewModel.peripherals count];
    [self.browserExpandableViewManager updateConnectionsButtonTitle:connections];
}

#pragma mark - Timers

- (void)startRefreshTimer {
    self.tableRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:kTableRefreshInterval
                                                              target:self
                                                            selector:@selector(tableRefreshTimerFired)
                                                            userInfo:nil
                                                             repeats:YES];
}

- (void)tableRefreshTimerFired {
    if (self.tableNeedsRefresh) {
        [self refreshTable];
    }
    [self removeTimer];
}

- (void)removeTimer {
    if (self.tableRefreshTimer) {
        [self.tableRefreshTimer invalidate];
        self.tableRefreshTimer = nil;
    }
}

- (void)installRSSITimer {
    __weak SILDebugServicesViewController *blocksafeSelf = self;
    self.rssiTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer* timer){ [blocksafeSelf.peripheral readRSSI];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.modelsToDisplay.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.modelsToDisplay[indexPath.row] isEqual:kCornersCellIdentifieer]) {
        SILBottomCornersCell *spacerCell = [tableView dequeueReusableCellWithIdentifier:@"SILBottomCornersCell"];
        return spacerCell;
    }
    if ([self.modelsToDisplay[indexPath.row] isEqual:kSpacerCellIdentifieer]) {
        SILDebugSpacerTableViewCell *spacerCell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugSpacerTableViewCell class])];
        return spacerCell;
    }
    
    id<SILGenericAttributeTableModel> model = self.modelsToDisplay[indexPath.row];
    if ([model isKindOfClass:[SILServiceTableModel class]]) {
        return [self serviceCellWithModel:model forTable:tableView];
    } else if ([model isKindOfClass:[SILCharacteristicTableModel class]]) {
        SILCharacteristicTableModel *characteristicTableModel = (SILCharacteristicTableModel *)model;
        return [self characteristicCellWithModel:characteristicTableModel forTable:tableView];
    } else {
        id<SILCharacteristicFieldRow> fieldModel = self.modelsToDisplay[indexPath.row];
        if ([model isKindOfClass:[SILEnumerationFieldRowModel class]]) {
            return [self enumerationFieldCellWithModel:fieldModel forTable:tableView];
        } else if ([model isKindOfClass:[SILBitRowModel class]]) {
            return [self toggleFieldCellWithModel:fieldModel forTable:tableView];
        } else if ([model isKindOfClass:[SILEncodingPseudoFieldRowModel class]]) {
            return [self encodingFieldCellWithModel:fieldModel forTable:tableView];
        } else {
            return [self valueFieldCellWithModel:fieldModel forTable:tableView];
        }
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[SILDebugCharacteristicTableViewCell class]]) {
        SILCharacteristicTableModel *characteristicModel = self.modelsToDisplay[indexPath.row];
        if ([characteristicModel isUnknown]) {
            [characteristicModel toggleExpansionIfAllowed];
            id<SILGenericAttributeTableCell> cell = [tableView cellForRowAtIndexPath:indexPath];
            [cell expandIfAllowed:characteristicModel.isExpanded];
            [self refreshTable];
            return;
        }
    }
    
    if ([self.modelsToDisplay[indexPath.row] respondsToSelector:@selector(canExpand)]) {
        id<SILGenericAttributeTableModel> model = self.modelsToDisplay[indexPath.row];
        if ([model canExpand]) {
            [model toggleExpansionIfAllowed];
            id<SILGenericAttributeTableCell> cell = [tableView cellForRowAtIndexPath:indexPath];
            [cell expandIfAllowed:model.isExpanded];
        }
        [self refreshTable];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.modelsToDisplay[indexPath.row] isEqual:kSpacerCellIdentifieer]) {
        return 24.0;
    }
    if ([self.modelsToDisplay[indexPath.row] isEqual:kCornersCellIdentifieer]) {
        return 16.0;
    }
    
    id<SILGenericAttributeTableModel> model = self.modelsToDisplay[indexPath.row];
    if ([model isKindOfClass:[SILServiceTableModel class]]) {
        return 104.0;
    } else if ([model isKindOfClass:[SILCharacteristicTableModel class]]) {
        SILCharacteristicTableModel* modelCharacteristic = (SILCharacteristicTableModel*)model;
        NSInteger descriptors = modelCharacteristic.descriptorModels.count;
        if (descriptors == 0) {
            return 107.0;
        } else {
            return 107.0 + (descriptors + 1) * 18.0;
        }
    } else {
        if ([model isKindOfClass:[SILEncodingPseudoFieldRowModel class]]) {
            return 228.0;
        }
        return 81.0;
    }
}

#pragma mark - SILServiceCellDelegate

- (void)showMoreInfoForCell:(SILServiceCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Fix for SLMAIN-124. Header jumps on plus sized iPhones when opening services sometimes.
    UIView *view = self.headerView;
    CGRect rect = view.frame;
    rect.origin.y = MAX(0, -(scrollView.contentOffset.y + rect.size.height));
    self.headerView.frame = rect;
}

#pragma mark - Configure Cells

- (SILServiceCell *)serviceCellWithModel:(SILServiceTableModel *)serviceTableModel forTable:(UITableView *)tableView {
    SILServiceCell *serviceCell = (SILServiceCell *)[tableView dequeueReusableCellWithIdentifier:@"SILServiceCell"];
    serviceCell.delegate = self;
    [serviceCell.nameEditButton setHidden:!serviceTableModel.isMappable];
    serviceCell.serviceNameLabel.text = [serviceTableModel name];
    serviceCell.serviceUuidLabel.text = [serviceTableModel hexUuidString] ?: @"";
    [serviceCell configureAsExpandanble:[serviceTableModel canExpand]];
    [serviceCell customizeMoreInfoText:serviceTableModel.isExpanded];
    [serviceCell layoutIfNeeded];
    return serviceCell;
}

- (SILDebugCharacteristicTableViewCell *)characteristicCellWithModel:(SILCharacteristicTableModel *)characteristicTableModel forTable:(UITableView *)tableView {
    SILDebugCharacteristicTableViewCell *characteristicCell = (SILDebugCharacteristicTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugCharacteristicTableViewCell class])];
    [characteristicCell configureWithCharacteristicModel:characteristicTableModel];
    characteristicCell.delegate = self;
    [characteristicCell.nameEditButton setHidden:!characteristicTableModel.isMappable];
    return characteristicCell;
}

- (SILDebugCharacteristicEnumerationFieldTableViewCell *)enumerationFieldCellWithModel:(SILEnumerationFieldRowModel *)enumerationFieldModel forTable:(UITableView *)tableView {
    SILDebugCharacteristicEnumerationFieldTableViewCell *enumerationFieldCell = (SILDebugCharacteristicEnumerationFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugCharacteristicEnumerationFieldTableViewCell class])];
    [enumerationFieldCell configureWithEnumerationModel:enumerationFieldModel];
    enumerationFieldCell.writeChevronImageView.hidden = YES;
    return enumerationFieldCell;
}

- (SILDebugCharacteristicEncodingFieldTableViewCell *)encodingFieldCellWithModel:(SILEncodingPseudoFieldRowModel *)encodingFieldModel forTable:(UITableView *)tableView {
    NSError *dataError = nil;
    SILDebugCharacteristicEncodingFieldTableViewCell *cell = (SILDebugCharacteristicEncodingFieldTableViewCell *) [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugCharacteristicEncodingFieldTableViewCell class])];
    NSData* subjectData = [encodingFieldModel dataForFieldWithError:&dataError];
    
    //Hidden is set to YES in the Bluetooth Browser feature after adding button properties SLMAIN-276. Hidden state was left conditional in HomeKit feature.
    cell.editLabel.hidden = YES;
    cell.hexValueLabel.text = [[SILCharacteristicFieldValueResolver sharedResolver] hexStringForData:subjectData decimalExponent:0];
    cell.asciiValueLabel.text = [[[SILCharacteristicFieldValueResolver sharedResolver] asciiStringForData:subjectData] stringByReplacingOccurrencesOfString:@"\0" withString:@""];
    cell.decimalValueLabel.text = [[SILCharacteristicFieldValueResolver sharedResolver] decimalStringForData:subjectData];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [cell layoutIfNeeded];
    return cell;
}

- (SILDebugCharacteristicToggleFieldTableViewCell *)toggleFieldCellWithModel:(SILBitRowModel *)toggleFieldModel forTable:(UITableView *)tableView {
    SILDebugCharacteristicToggleFieldTableViewCell *toggleFieldCell = (SILDebugCharacteristicToggleFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugCharacteristicToggleFieldTableViewCell class])];
    [toggleFieldCell configureWithBitRowModel:toggleFieldModel];
    toggleFieldCell.editDelegate = self;
    return toggleFieldCell;
}

- (SILDebugCharacteristicValueFieldTableViewCell *)valueFieldCellWithModel:(SILValueFieldRowModel *)valueFieldModel forTable:(UITableView *)tableView {
    SILDebugCharacteristicValueFieldTableViewCell *valueFieldCell = (SILDebugCharacteristicValueFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugCharacteristicValueFieldTableViewCell class])];
    [valueFieldCell configureWithValueModel:valueFieldModel];
    //Hidden is set to YES in the Bluetooth Browser feature after adding button properties SLMAIN-276. Hidden state was left conditional in HomeKit feature.
    valueFieldCell.editButton.hidden = YES;
    valueFieldCell.editDelegate = self;
    return valueFieldCell;
}

#pragma mark - SILCharacteristicEditEnablerDelegate

- (void)beginValueEditWithValue:(SILValueFieldRowModel *)valueModel {
    [self displayValueEditor:valueModel];
}

- (void)displayValueEditor:(SILValueFieldRowModel *)valueModel {
    SILValueFieldEditorViewController *valueEditViewController = [[SILValueFieldEditorViewController alloc] initWithValueFieldModel:valueModel];
    valueEditViewController.popoverDelegate = self;
    valueEditViewController.editDelegate = self;
    self.popoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:valueEditViewController
                                                                             presentingViewController:self
                                                                                             delegate:self
                                                                                             animated:YES];
}

- (void)displayEnumerationDetails:(SILEnumerationFieldRowModel *)enumerationModel {
    SILDebugCharacteristicEnumerationListViewController *listViewController = [[SILDebugCharacteristicEnumerationListViewController alloc] initWithEnumeration:enumerationModel canEdit:YES];
    listViewController.popoverDelegate = self;
    listViewController.editDelegate = self;
    self.popoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:listViewController
                                                                             presentingViewController:self
                                                                                             delegate:self
                                                                                             animated:YES];
}

- (void)displayCharacteristicEncoding:(SILCharacteristicTableModel *)characteristicModel canEdit:(BOOL)canEdit {
    SILDebugCharacteristicEncodingViewController *encodingViewController = [[SILDebugCharacteristicEncodingViewController alloc] initWithCharacteristicTableModel:characteristicModel canEdit:canEdit];
    encodingViewController.popoverDelegate = self;
    encodingViewController.editDelegate = self;
    encodingViewController.view.layer.cornerRadius = CornerRadiusStandardValue;
    encodingViewController.view.layer.masksToBounds = TRUE;
    self.popoverController.contentViewController.view.layer.cornerRadius = CornerRadiusStandardValue;
    self.popoverController.contentViewController.view.layer.masksToBounds = TRUE;
    WYPopoverBackgroundView* appearance = [WYPopoverBackgroundView appearance];
    [appearance setOuterCornerRadius:CornerRadiusStandardValue];
    [appearance setInnerCornerRadius:CornerRadiusStandardValue];
    self.popoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:encodingViewController
                                                                             presentingViewController:self
                                                                                             delegate:self
                                                                                             animated:YES];
}

#pragma mark - SILPopoverViewControllerDelegate

- (void)didClosePopoverViewController:(SILDebugPopoverViewController *)popoverViewController {
    [self.popoverController dismissPopoverAnimated:YES completion:^{
        self.popoverController = nil;
        [self.tableView reloadData];
    }];
}

- (void)saveCharacteristic:(SILCharacteristicTableModel *)characteristicModel error:(NSError *__autoreleasing *)error {
    if (!(*error)) {
        [characteristicModel writeIfAllowedToPeripheral:self.peripheral error:error];
    }
    
    if (*error) {
        *error = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:@{
            NSUnderlyingErrorKey: *error,
            NSLocalizedDescriptionKey: [self prepareErrorDescription:*error],
        }];
    }
}

- (NSString *)prepareErrorDescription:(NSError *)error {
    NSString * const errorKind = error.userInfo[@"errorKind"];
    
    if ([@"Parse" isEqualToString:errorKind]) {
        return [self prepareParseErrorDescription:error];
    } else if ([@"Range" isEqualToString:errorKind]) {
        return [self prepareRangeErrorDescription:error];
    }
    
    return @"Unknown error";
}

- (NSString *)prepareParseErrorDescription:(NSError *)error {
    return @"Input parsing error";
}

- (NSString *)prepareRangeErrorDescription:(NSError *)error {
    NSNumber * minRange = error.userInfo[@"minRange"];
    NSNumber * maxRange = error.userInfo[@"maxRange"];
    NSNumber * const valueExponent = error.userInfo[@"valueExponent"];
    
    if (valueExponent && ![valueExponent isEqualToNumber:@0]) {
        NSDecimalNumber * const minDecNumber = [NSDecimalNumber decimalNumberWithDecimal:[minRange decimalValue]];
        minRange = [minDecNumber decimalNumberByMultiplyingByPowerOf10:[valueExponent shortValue]];
        
        NSDecimalNumber * const maxDecNumber = [NSDecimalNumber decimalNumberWithDecimal:[maxRange decimalValue]];
        maxRange = [maxDecNumber decimalNumberByMultiplyingByPowerOf10:[valueExponent shortValue]];
    }

    return [NSString stringWithFormat:@"Value out of range (%@, %@)", minRange.stringValue, maxRange.stringValue];
}

#pragma mark - WYPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)popoverController {
    [self.popoverController dismissPopoverAnimated:YES completion:nil];
    self.popoverController = nil;
}

#pragma mark - SILMapCellDelegate

- (void)editNameWithCell:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    id<SILGenericAttributeTableModel> model = self.modelsToDisplay[indexPath.row];
    if ([model isKindOfClass:[SILServiceTableModel class]]) {
        [self editNameForService:model];
    } else if ([model isKindOfClass:[SILCharacteristicTableModel class]]) {
        [self editNameForCharacteristic:model];
    }
}

- (void)editNameForService:(SILServiceTableModel*)model {
    SILMapNameEditorViewController *nameEditor = [[SILMapNameEditorViewController alloc] init];
    SILServiceMap* serviceModel = [SILServiceMap getWith:model.uuidString];
    if (serviceModel == nil) {
        serviceModel = [SILServiceMap createWith:model.name uuid:model.uuidString];
    }
    nameEditor.model = serviceModel;
    nameEditor.popoverDelegate = self;
    self.popoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:nameEditor
    presentingViewController:self
                    delegate:self
                    animated:YES];
}

- (void)editNameForCharacteristic:(SILCharacteristicTableModel*)model {
    SILMapNameEditorViewController *nameEditor = [[SILMapNameEditorViewController alloc] init];
    SILCharacteristicMap* characteristicModel = [SILCharacteristicMap getWith:model.uuidString];
    if (characteristicModel == nil) {
        characteristicModel = [SILCharacteristicMap createWith:model.name uuid:model.uuidString];
    }
    nameEditor.model = characteristicModel;
    nameEditor.popoverDelegate = self;
    self.popoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:nameEditor
    presentingViewController:self
                    delegate:self
                    animated:YES];
}

#pragma mark - SILDebugCharacteristicCellDelegate

- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestReadForCharacteristic:(CBCharacteristic *)characteristic {
    BOOL isPerformed = [cell.characteristicTableModel clearModel];
    if (!isPerformed) {
        [self performManualClearingValuesIntoEncodingFieldTableViewCell:characteristic];
    } else {
        [self refreshTable];
    }
    [self.peripheral readValueForCharacteristic:characteristic];
}

- (void)performManualClearingValuesIntoEncodingFieldTableViewCell:(CBCharacteristic*)characteristic {
    for (id<SILGenericAttributeTableModel> model in self.modelsToDisplay) {
        if ([model isKindOfClass:[SILCharacteristicTableModel class]]) {
            SILCharacteristicTableModel* characteristicModel = (SILCharacteristicTableModel*)model;
            if ([characteristicModel isUnknown] && characteristicModel.characteristic == characteristic) {
                NSUInteger index = [self.modelsToDisplay indexOfObject:model] + 1;
                SILDebugCharacteristicTableViewCell* cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
                if ([cell isKindOfClass:[SILDebugCharacteristicEncodingFieldTableViewCell class]]) {
                    SILDebugCharacteristicEncodingFieldTableViewCell* encodingCell = (SILDebugCharacteristicEncodingFieldTableViewCell*)cell;
                    [encodingCell clearValues];
                }
            }
        }
    }
}

- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestWriteForCharacteristic:(CBCharacteristic *)characteristic {
    [self refreshTable];
    if (cell.characteristicTableModel.isUnknown) {
        SILEncodingPseudoFieldRowModel *model = [[SILEncodingPseudoFieldRowModel alloc]initForCharacteristicModel:cell.characteristicTableModel];
        [self displayCharacteristicEncoding:model.parentCharacteristicModel canEdit:model.parentCharacteristicModel.canWrite];
    } else {
        id<SILCharacteristicFieldRow> model = cell.characteristicTableModel.fieldTableRowModels.firstObject;
        [self performWriteActionForCharacteristicFieldRow:model];
    }
}

- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestWriteNoResponseForCharacteristic:(CBCharacteristic *)characteristic {
    id<SILCharacteristicFieldRow> model = cell.characteristicTableModel.fieldTableRowModels.firstObject;
    [self performWriteActionForCharacteristicFieldRow:model];
}

- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestNotifyForCharacteristic:(CBCharacteristic *)characteristic withValue:(BOOL)value {
    [self.peripheral setNotifyValue:value forCharacteristic:characteristic];
}

- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestIndicateForCharacteristic:(CBCharacteristic *)characteristic withValue:(BOOL)value {
    [self.peripheral setNotifyValue:value forCharacteristic:characteristic];
}

- (void)performWriteActionForCharacteristicFieldRow:(id<SILCharacteristicFieldRow>)characteristicFieldRow {
    if ([characteristicFieldRow isKindOfClass:[SILEnumerationFieldRowModel class]]) {
        [self displayEnumerationDetails:characteristicFieldRow];
    } else {
        [self displayValueEditor:characteristicFieldRow];
    }
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSString* title;
    SILDiscoveredPeripheral* discoveredPeripheral = [self.centralManager discoveredPeripheralForPeripheral:self.peripheral];
    if (discoveredPeripheral) {
        title = discoveredPeripheral.advertisedLocalName;
    }
    if (!title) {
        title = self.peripheral.name ?: DefaultDeviceName;
    }
    self.title = title;
    self.tableView.hidden = NO;
    self.headerView.hidden = NO;
    for (CBService *service in peripheral.services) {
        [self addOrUpdateModelForService:service];
        [peripheral discoverCharacteristics:nil forService:service];
    }
    [self markTableForUpdate];
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didDiscoverServices: " andPeripheral:peripheral andError:error]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *characteristic in service.characteristics) {
        [self addOrUpdateModelForCharacteristic:characteristic forService:service];
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
    [self markTableForUpdate];
    [self configureOtaButtonWithPeripheral:peripheral];
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didDiscoverCharacteristics: " andPeripheral:peripheral andError:error]];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    [CrashlyticsKit setObjectValue:peripheral.name forKey:@"peripheral"];
    [self addOrUpdateModelForCharacteristic:characteristic forService:characteristic.service];
    [self refreshTable];
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didUpdateValueForCharacteristic: " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        [self addOrUpdateModelForDescriptor:descriptor forCharacteristic:characteristic];
    }
    [self markTableForUpdate];
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didDiscoverDescriptorsForCharacteristic: " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    [self addOrUpdateModelForDescriptor:descriptor forCharacteristic:descriptor.characteristic];
    [self markTableForUpdate];
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didUpdateValueForDescriptor: " andDescriptor:descriptor andPeripheral:peripheral andError:error]];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *message;
    if (error) {
        NSLog(@"Write failed, restoring backup");
        message = [NSString stringWithFormat:@"Write failed. Error: code=%ld \"%@\"", (long)error.code, error.localizedDescription];
        [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didWriteValueForCharacteristic: Write failed, restoring backup " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
    } else {
        NSLog(@"Write successful, updating read value");
        message = @"Write successful!";
        [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didWriteValueForCharacteristic: Write successful! " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
    }
    [peripheral readValueForCharacteristic:characteristic];
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    [self.rssiLabel setHidden:NO];
    [self.rssiImageView setHidden:NO];
    NSMutableString* rssiDescription = [NSMutableString stringWithString:[NSString stringWithFormat:@"%@", RSSI]];
    [rssiDescription appendString:@" dBm"];
    self.rssiLabel.text = rssiDescription;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"%@", error);
    if (error == nil) {
        [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didUpdateNotificationStateForCharacteristic: Successful! " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
    } else {
        [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didUpdateNotificationStateForCharacteristic: Failed! " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
        
        SILGattPropertiesErrorToastModel* errorToast = [[SILGattPropertiesErrorToastModel alloc] initWithPeripheralName:peripheral.name errorCode:error.code];
        NSString* ErrorMessage = [errorToast getErrorMessageForToast];
        [self showToastWithMessage:ErrorMessage toastType:ToastTypeGattPropertiesError completion:^{}];
    }    
    [self refreshTable];
}

#pragma mark - Add or Update Attribute Models

- (BOOL)addOrUpdateModelForService:(CBService *)service {
    BOOL addedService = NO;
    SILServiceTableModel *serviceModel = [self findServiceModelForService:service];
    if (!serviceModel) {
        serviceModel = [[SILServiceTableModel alloc] initWithService:service];
        [self.allServiceModels addObject:serviceModel];
        addedService = YES;
    } else {
        serviceModel.service = service;
    }
    return addedService;
}

- (BOOL)addOrUpdateModelForCharacteristic:(CBCharacteristic *)characteristic forService:(CBService *)service {
    BOOL addedCharacteristic = NO;
    SILServiceTableModel *serviceModel = [self findServiceModelForService:service];
    SILCharacteristicTableModel *characteristicModel = [self findCharacteristicModelForCharacteristic:characteristic forServiceModel:serviceModel];
    if (serviceModel) {
        NSMutableArray *mutableCharacteristicModels = [serviceModel.characteristicModels mutableCopy] ?: [NSMutableArray new];
        if (!characteristicModel) {
            characteristicModel = [[SILCharacteristicTableModel alloc] initWithCharacteristic:characteristic];
            [characteristicModel updateRead:characteristic];
            [mutableCharacteristicModels addObject:characteristicModel];
            serviceModel.characteristicModels = [mutableCharacteristicModels copy];
            addedCharacteristic = YES;
        } else {
            characteristicModel.characteristic = characteristic;
            [characteristicModel updateRead:characteristic];
        }
    }
    return addedCharacteristic;
}

- (BOOL)addOrUpdateModelForDescriptor:(CBDescriptor *)descriptor forCharacteristic:(CBCharacteristic *)characteristic {
    BOOL addedDescriptor = NO;
    SILServiceTableModel *serviceModel = [self findServiceModelForService:characteristic.service];
    SILCharacteristicTableModel *characteristicModel = [self findCharacteristicModelForCharacteristic:characteristic forServiceModel:serviceModel];
    SILDescriptorTableModel *descriptorModel = [self findDescriptorModelForDescriptor:descriptor forCharacteristicModel:characteristicModel];
    
    if (characteristicModel) {
        NSMutableArray *mutableDescriptorModels = [characteristicModel.descriptorModels mutableCopy] ?: [NSMutableArray new];
        if (!descriptorModel) {
            descriptorModel = [[SILDescriptorTableModel alloc] initWithDescriptor:descriptor];
            [mutableDescriptorModels addObject:descriptorModel];
            characteristicModel.descriptorModels = [mutableDescriptorModels copy];
            addedDescriptor = YES;
        } else {
            descriptorModel.descriptor = descriptor;
        }
    }
    
    return addedDescriptor;
}

- (NSArray *)characteristicModelsForCharacteristics:(NSArray *)characteristics {
    NSMutableArray *characteristicModels = [[NSMutableArray alloc] init];
    for (CBCharacteristic *characteristic in characteristics) {
        SILCharacteristicTableModel *characteristicModel = [[SILCharacteristicTableModel alloc] initWithCharacteristic:characteristic];
        [characteristicModels addObject:characteristicModel];
    }
    return characteristicModels;
}

- (NSArray *)descriptorModelsForDescriptors:(NSArray *)descriptors {
    NSMutableArray *descriptorModels = [[NSMutableArray alloc] init];
    for (CBDescriptor *descriptor in descriptors) {
        SILDescriptorTableModel *attributeModel = [[SILDescriptorTableModel alloc] initWithDescriptor:descriptor];
        [descriptorModels addObject:attributeModel];
    }
    return descriptorModels;
}

#pragma mark - Find Attribute Models

- (SILServiceTableModel *)findServiceModelForService:(CBService *)service {
    for (SILServiceTableModel *serviceModel in self.allServiceModels) {
        if ([serviceModel.service.UUID isEqual:service.UUID]) {
            return serviceModel;
        }
    }
    return nil;
}

- (SILCharacteristicTableModel *)findCharacteristicModelForCharacteristic:(CBCharacteristic *)characteristic forServiceModel:(SILServiceTableModel *)serviceModel {
    if (serviceModel) {
        for (SILCharacteristicTableModel *characteristicModel in serviceModel.characteristicModels) {
            if ([characteristicModel.characteristic isEqual:characteristic]) {
                return characteristicModel;
            }
        }
    }
    return nil;
}

- (SILDescriptorTableModel *)findDescriptorModelForDescriptor:(CBDescriptor *)descriptor forCharacteristicModel:(SILCharacteristicTableModel *)characteristicModel {
    if (characteristicModel) {
        for (SILDescriptorTableModel *descriptorModel in characteristicModel.descriptorModels) {
            if ([descriptorModel.descriptor.UUID isEqual:descriptor.UUID]) {
                return descriptorModel;
            }
        }
    }
    return nil;
}

#pragma mark - Display Array

- (NSArray *)buildDisplayArray {
    NSMutableArray *displayArray = [[NSMutableArray alloc] init];
    
    bool firstService = YES;
    for (SILServiceTableModel *serviceModel in self.allServiceModels) {
        serviceModel.hideTopSeparator = firstService;
        [displayArray addObject:serviceModel];
        
        if (serviceModel.isExpanded) {
            [self buildDisplayCharacteristics:displayArray forServiceModel:serviceModel];
        }
        firstService = NO;
        [displayArray addObject:kCornersCellIdentifieer];
        [displayArray addObject:kSpacerCellIdentifieer];
    }
    
    return displayArray;
}

- (void)buildDisplayCharacteristics:(NSMutableArray *)displayArray forServiceModel:(SILServiceTableModel *)serviceModel {
    for (SILCharacteristicTableModel *characteristicModel in serviceModel.characteristicModels) {
        characteristicModel.hideTopSeparator = NO;
        [displayArray addObject:characteristicModel];
        
        if (characteristicModel.isExpanded) {
            [self buildDisplayCharacteristicFields:displayArray forCharacteristicModel:characteristicModel];
        }
    }
}

- (void)buildDisplayCharacteristicFields:(NSMutableArray *)displayArray forCharacteristicModel:(SILCharacteristicTableModel *)characteristicModel {
    if ([characteristicModel isUnknown]) {
        // We are unknown. But lets display our encoding information as if we were a field.
        [displayArray addObject:[[SILEncodingPseudoFieldRowModel alloc] initForCharacteristicModel:characteristicModel]];
    } else {
        for (id<SILCharacteristicFieldRow> fieldModel in characteristicModel.fieldTableRowModels) {
            [fieldModel setParentCharacteristicModel:characteristicModel];
            if ([fieldModel requirementsSatisfied]) {
                fieldModel.hideTopSeparator = NO;
                if ([fieldModel isKindOfClass:[SILBitFieldFieldModel class]]) {
                    SILBitFieldFieldModel *bitFieldModel = fieldModel;
                    [displayArray addObjectsFromArray:[bitFieldModel bitRowModels]];
                } else {
                    [displayArray addObject:fieldModel];
                }
            } else {
                NSLog(@"Requirements not met for %@", characteristicModel.bluetoothModel.name);
            }
        }
    }
}

#pragma mark - Helpers

- (void)markTableForUpdate {
    self.tableNeedsRefresh = YES;
    if (!self.tableRefreshTimer) {
        [self refreshTable];
        [self startRefreshTimer];
        [self.refreshControl endRefreshing];
    }
}

- (void)refreshTable {
    self.modelsToDisplay = [self buildDisplayArray];
    [self.tableView reloadData];
    self.tableNeedsRefresh = NO;
}

- (void)configureOtaButtonWithPeripheral:(CBPeripheral *)peripheral {
    if ([peripheral hasOTAService]) {
        [self.menuButton setHidden:NO];
    } else {
        [self.menuButton setHidden:YES];
    }
}

- (void)postRegisterLogNotification:(NSString*)description {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationRegisterLog object:self userInfo:@{ SILNotificationKeyDescription : description}];
}

#pragma mark - dealloc

- (void)dealloc {
    [self removeTimer];
}

#pragma mark - SILBrowserLogViewControllerDelegate

- (void)logViewBackButtonPressed {
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
}

#pragma mark - SILBrowserConnectionViewControllerDelegate

- (void)connectionsViewBackButtonPressed {
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
}

- (void)presentDetailsViewControllerForIndex:(NSInteger)index {
    [self.browserExpandableViewManager removeExpandingControllerIfNeeded];
    SILConnectedPeripheralDataModel* connectedPeripheral = self.connectionsViewModel.peripherals[index];
    self.peripheral = connectedPeripheral.peripheral;
    [self.refreshControl removeFromSuperview];
    self.refreshControl = nil;
    self.allServiceModels = nil;
    [self viewDidLoad];
    [self viewWillAppear:YES];
    [self viewDidAppear:YES];
    [self.connectionsViewModel updateConnectionsView:index];
}

@end
