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
#import "SILDebugProperty.h"
#import "SILDebugHeaderView.h"
#import "SILDiscoveredPeripheral.h"
#import "UIView+NibInitable.h"
#import "UIColor+SILColors.h"
#import "SILAlertBarView.h"
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
#import "UITableViewCell+SILHelpers.h"
#import "SILActivityBarViewController.h"
#import <Crashlytics/Crashlytics.h>
#import "UIViewController+Containment.h"
#import <PureLayout/PureLayout.h>
#import "CBPeripheral+Services.h"
#import "SILUUIDProvider.h"
#import "SILOTAUICoordinator.h"

static NSInteger const kTableViewEdgePadding = 36;
static NSString * const kSpacerCellIdentifieer = @"spacer";
static NSString * const kOTAButtonTitle = @"OTA";
static NSString * const kUnknownPeripheralName = @"Unknown";
static NSString * const kScanningForPeripheralsMessage = @"Loading...";

static float kOnPriority = 999;
static float kOffPriority = 1;
static float kTableRefreshInterval = 1;

@interface SILDebugServicesViewController () <UITableViewDelegate, UITableViewDataSource, CBPeripheralDelegate, UIScrollViewDelegate, SILDebugPopoverViewControllerDelegate, WYPopoverControllerDelegate, SILCharacteristicEditEnablerDelegate, SILOTAUICoordinatorDelegate, SILDebugCharacteristicCellDelegate>

@property (weak, nonatomic) IBOutlet SILAlertBarView *alertBarView;
@property (weak, nonatomic) IBOutlet UIView *activityBarViewControllerContainer;
@property (strong, nonatomic) NSMutableArray *allServiceModels;
@property (strong, nonatomic) NSArray *modelsToDisplay;
@property (nonatomic) BOOL isUpdatingFirmware;

@property (nonatomic) BOOL tableNeedsRefresh;
@property (strong, nonatomic) NSTimer *tableRefreshTimer;

@property (nonatomic) UIRefreshControl *refreshControl;

@property (strong, nonatomic) SILOTAUICoordinator *otaUICoordinator;

@property (weak, nonatomic) IBOutlet UILabel *disconnectedMessageLabel;
@property (weak, nonatomic) IBOutlet UITableView *servicesTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *servicesTableViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *servicesTableViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *servicesTableViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *disconnectedBarHideConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *disconnectedBarRevealConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *activityBarViewControllerHideConstraint;
@property (strong, nonatomic) WYPopoverController *popoverController;

@property (strong, nonatomic) SILDebugHeaderView *headerView;
@property (strong, nonatomic) SILActivityBarViewController *activityBarViewController;

@end

@implementation SILDebugServicesViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerForNotifications];
    [self registerNibsAndSetUpSizing];
    [self setupActivityBarViewController];
    [self setUpServicesTableView];
    [self setUpSubviews];
    [self startServiceSearch];
    [self setupTableHeaderView];
    [self setupRefreshControl];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (![parent isEqual:self.parentViewController]) {
        [self.centralManager disconnectConnectedPeripheral];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGRect headerFrame = self.headerView.frame;
    headerFrame.size.width = self.view.bounds.size.width;
    self.headerView.frame = headerFrame;
}

#pragma mark - setup

-(void)registerNibsAndSetUpSizing {
    NSString *serviceCellClassString = NSStringFromClass([SILDebugServiceTableViewCell class]);
    [self.servicesTableView registerNib:[UINib nibWithNibName:serviceCellClassString bundle:nil] forCellReuseIdentifier:serviceCellClassString];
    
    NSString *characteristicCellClassString = NSStringFromClass([SILDebugCharacteristicTableViewCell class]);
    [self.servicesTableView registerNib:[UINib nibWithNibName:characteristicCellClassString bundle:nil] forCellReuseIdentifier:characteristicCellClassString];
    
    NSString *characteristicValueFieldCellClassString = NSStringFromClass([SILDebugCharacteristicValueFieldTableViewCell class]);
    [self.servicesTableView registerNib:[UINib nibWithNibName:characteristicValueFieldCellClassString bundle:nil] forCellReuseIdentifier:characteristicValueFieldCellClassString];
    
    NSString *characteristicToggleFieldCellClassString = NSStringFromClass([SILDebugCharacteristicToggleFieldTableViewCell class]);
    [self.servicesTableView registerNib:[UINib nibWithNibName:characteristicToggleFieldCellClassString bundle:nil] forCellReuseIdentifier:characteristicToggleFieldCellClassString];
    
    NSString *characteristicEnumerationFieldCellClassString = NSStringFromClass([SILDebugCharacteristicEnumerationFieldTableViewCell class]);
    [self.servicesTableView registerNib:[UINib nibWithNibName:characteristicEnumerationFieldCellClassString bundle:nil] forCellReuseIdentifier:characteristicEnumerationFieldCellClassString];
    
    NSString *characteristicEncodingFieldCellClassString = NSStringFromClass([SILDebugCharacteristicEncodingFieldTableViewCell class]);
    [self.servicesTableView registerNib:[UINib nibWithNibName:characteristicEncodingFieldCellClassString bundle:nil] forCellReuseIdentifier:characteristicEncodingFieldCellClassString];
    
    NSString *spacerCellClassString = NSStringFromClass([SILDebugSpacerTableViewCell class]);
    [self.servicesTableView registerNib:[UINib nibWithNibName:spacerCellClassString bundle:nil] forCellReuseIdentifier:spacerCellClassString];
}

- (void)setUpServicesTableView {
    self.servicesTableView.rowHeight = UITableViewAutomaticDimension;
    self.servicesTableView.sectionHeaderHeight = 40;
    self.servicesTableView.hidden = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.servicesTableViewLeadingConstraint.constant = kTableViewEdgePadding;
        self.servicesTableViewTrailingConstraint.constant = kTableViewEdgePadding;
        self.servicesTableView.estimatedRowHeight = 96;
        self.servicesTableViewTopConstraint.constant = kTableViewEdgePadding;
    } else {
        self.servicesTableViewLeadingConstraint.constant = 0;
        self.servicesTableViewTrailingConstraint.constant = 0;
        self.servicesTableViewTopConstraint.constant = 0;
        self.servicesTableView.estimatedRowHeight = 100;
    }
}

- (void)setUpSubviews {
    self.title = self.peripheral.name ?: kUnknownPeripheralName;
    self.activityBarViewControllerHideConstraint.priority = kOffPriority;
    [self.activityBarViewController scanningAnimationWithMessage:kScanningForPeripheralsMessage];
    [self.alertBarView configureLabel:self.disconnectedMessageLabel revealConstraint:self.disconnectedBarRevealConstraint hideConstraint:self.disconnectedBarHideConstraint];
}

- (void)startServiceSearch {
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:nil];
}

- (void)setupActivityBarViewController {
    self.activityBarViewController = [[SILActivityBarViewController alloc] init];
    [self ip_addChildViewController:self.activityBarViewController toView:self.activityBarViewControllerContainer];
    [self.activityBarViewController.view autoPinEdgesToSuperviewEdges];
}

- (void)setupTableHeaderView {
    self.headerView = (SILDebugHeaderView *)[self.view initWithNibNamed:NSStringFromClass([SILDebugHeaderView class])];
    self.headerView.headerLabel.text = @"SERVICES";
    self.headerView.hidden = YES;
    [self.view addSubview:self.headerView];

    self.servicesTableView.contentInset = UIEdgeInsetsMake(self.headerView.bounds.size.height, 0, 0, 0);
}

- (void)setupRefreshControl {
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefreshServices:) forControlEvents:UIControlEventValueChanged];
    [self.servicesTableView addSubview:self.refreshControl];
    [self.refreshControl sendSubviewToBack:self.refreshControl];
    self.refreshControl.bounds = CGRectMake(self.refreshControl.bounds.origin.x, self.refreshControl.bounds.origin.y + 50.0, 100.0, 100.0);
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

#pragma mark - Actions

- (void)didTapOTABarButtonItem {
    self.isUpdatingFirmware = YES;
    self.otaUICoordinator = [[SILOTAUICoordinator alloc] initWithPeripheral:self.peripheral
                                                             centralManager:self.centralManager
                                                   presentingViewController:self];
    self.otaUICoordinator.delegate = self;
    [self.otaUICoordinator initiateOTAFlow];
}

// SLMAIN-333 - This is a workaround to disconnect and reconnect to the peripheral when dynamic services/characteristics are toggled.
// If this isn't done, services cannot be refreshed more than once.
- (void)handleRefreshServices: (UIRefreshControl *)sender {
    void (^serviceSearch)(void) = ^(void){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self startServiceSearch];
        });
    };

    if (self.refreshControl == sender) {
        self.allServiceModels = [[NSMutableArray alloc] init];
        [self.centralManager disconnectConnectedPeripheral];
        [self.centralManager connectToDiscoveredPeripheral: [self.centralManager discoveredPeripheralForPeripheral:self.peripheral]];
        serviceSearch();
    }
}

#pragma mark - SILOTAUICoordinatorDelegate

- (void)otaUICoordinatorDidFishishOTAFlow:(SILOTAUICoordinator *)coordinator {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Activity Bar

- (void)hideActivityBarViewController {
    __weak SILDebugServicesViewController *weakSelf = self;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.5 animations:^{
        weakSelf.activityBarViewControllerHideConstraint.priority = kOnPriority;
        [weakSelf.view layoutIfNeeded];
        [weakSelf.view updateConstraints];
    }];
}

#pragma mark - Notifications

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDisconnectPeripheralNotifcation:)
                                                 name:SILCentralManagerDidDisconnectPeripheralNotification
                                               object:self.centralManager];
}

#pragma mark - Notification Methods

- (void)didDisconnectPeripheralNotifcation:(NSNotification *)notification {
    if (!self.isUpdatingFirmware) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Table Timer

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

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.modelsToDisplay.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self configuredCellForIndexPath:indexPath tableView:tableView];
}

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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Fix for SLMAIN-124. Header jumps on plus sized iPhones when opening services sometimes.
    UIView *view = self.headerView;
    CGRect rect = view.frame;
    rect.origin.y = MAX(0, -(scrollView.contentOffset.y + rect.size.height));
    self.headerView.frame = rect;
}

#pragma mark - Configure Cells

- (SILDebugServiceTableViewCell *)serviceCellWithModel:(SILServiceTableModel *)serviceTableModel forTable:(UITableView *)tableView {
    SILDebugServiceTableViewCell *serviceCell = (SILDebugServiceTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugServiceTableViewCell class])];
    [serviceCell configureWithServiceModel:serviceTableModel];
    return serviceCell;
}

- (SILDebugCharacteristicTableViewCell *)characteristicCellWithModel:(SILCharacteristicTableModel *)characteristicTableModel forTable:(UITableView *)tableView {
    SILDebugCharacteristicTableViewCell *characteristicCell = (SILDebugCharacteristicTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugCharacteristicTableViewCell class])];
    [characteristicCell configureWithCharacteristicModel:characteristicTableModel];
    characteristicCell.delegate = self;
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
    self.popoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:encodingViewController
                                                                             presentingViewController:self
                                                                                             delegate:self
                                                                                             animated:YES];
}

#pragma mark - SILPopoverViewControllerDelegate

- (void)didClosePopoverViewController:(SILDebugPopoverViewController *)popoverViewController {
    [self.popoverController dismissPopoverAnimated:YES completion:^{
        self.popoverController = nil;
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

#pragma mark - SILDebugCharacteristicCellDelegate

- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestReadForCharacteristic:(CBCharacteristic *)characteristic {
    [self.peripheral readValueForCharacteristic:characteristic];
}

- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestWriteForCharacteristic:(CBCharacteristic *)characteristic {
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
    } else if ([characteristicFieldRow isKindOfClass:[SILValueFieldRowModel class]]) {
        [self displayValueEditor:characteristicFieldRow];
    }
}


#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    [self hideActivityBarViewController];
    NSString* title;
    SILDiscoveredPeripheral* discoveredPeripheral = [self.centralManager discoveredPeripheralForPeripheral:self.peripheral];
    if (discoveredPeripheral) {
        title = discoveredPeripheral.advertisedLocalName;
    }
    if (!title) {
        title = self.peripheral.name ?: kUnknownPeripheralName;
    }
    self.title = title;

    self.servicesTableView.hidden = NO;
    self.headerView.hidden = NO;
    for (CBService *service in peripheral.services) {
        [self addOrUpdateModelForService:service];
        [peripheral discoverCharacteristics:nil forService:service];
    }
    [self markTableForUpdate];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *characteristic in service.characteristics) {
        [self addOrUpdateModelForCharacteristic:characteristic forService:service];
        [peripheral readValueForCharacteristic:characteristic];
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
    [self markTableForUpdate];
    [self configureNavigationItemWithPeripheral:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    [CrashlyticsKit setObjectValue:peripheral.name forKey:@"peripheral"];
    [self addOrUpdateModelForCharacteristic:characteristic forService:characteristic.service];
    [self markTableForUpdate];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        [self addOrUpdateModelForDescriptor:descriptor forCharacteristic:characteristic];
        [peripheral readValueForDescriptor:descriptor];
    }
    [self markTableForUpdate];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    [self addOrUpdateModelForDescriptor:descriptor forCharacteristic:descriptor.characteristic];
    [self markTableForUpdate];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *message;
    if (error) {
        NSLog(@"Write failed, restoring backup");
        message = [NSString stringWithFormat:@"Write failed. Error: code=%ld \"%@\"", (long)error.code, error.localizedDescription];
    } else {
        NSLog(@"Write successful, updating read value");
        message = @"Write successful!";
    }
    [peripheral readValueForCharacteristic:characteristic];
    [self.alertBarView revealAlertBarWithMessage:message revealTime:0.4 displayTime:3];
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
        [displayArray addObject:kSpacerCellIdentifieer];
    }
    
    return displayArray;
}

- (void)buildDisplayCharacteristics:(NSMutableArray *)displayArray forServiceModel:(SILServiceTableModel *)serviceModel {
    bool firstCharacteristic = YES;
    for (SILCharacteristicTableModel *characteristicModel in serviceModel.characteristicModels) {
        characteristicModel.hideTopSeparator = firstCharacteristic;
        [displayArray addObject:characteristicModel];
        
        if (characteristicModel.isExpanded) {
            [self buildDisplayCharacteristicFields:displayArray forCharacteristicModel:characteristicModel];
        }
        
        firstCharacteristic = NO;
    }
}

- (void)buildDisplayCharacteristicFields:(NSMutableArray *)displayArray forCharacteristicModel:(SILCharacteristicTableModel *)characteristicModel {
    bool firstField = YES;
    if ([characteristicModel isUnknown]) {
        // We are unknown. But lets display our encoding information as if we were a field.
        [displayArray addObject:[[SILEncodingPseudoFieldRowModel alloc] initForCharacteristicModel:characteristicModel]];
    } else {
        for (id<SILCharacteristicFieldRow> fieldModel in characteristicModel.fieldTableRowModels) {
            [fieldModel setParentCharacteristicModel:characteristicModel];
            if ([fieldModel requirementsSatisfied]) {
                fieldModel.hideTopSeparator = firstField;
                if ([fieldModel isKindOfClass:[SILBitFieldFieldModel class]]) {
                    SILBitFieldFieldModel *bitFieldModel = fieldModel;
                    [displayArray addObjectsFromArray:[bitFieldModel bitRowModels]];
                } else {
                    [displayArray addObject:fieldModel];
                }
                firstField = NO;
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
    [self.servicesTableView reloadData];
    self.tableNeedsRefresh = NO;
}

- (UITableViewCell *)configuredCellForIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
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

- (void)configureNavigationItemWithPeripheral:(CBPeripheral *)peripheral {
    UIBarButtonItem *otaBarButtonItem;
    if ([peripheral hasOTAService]) {
        otaBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:kOTAButtonTitle
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(didTapOTABarButtonItem)];
    }
    [self.navigationItem setRightBarButtonItem:otaBarButtonItem];
}

#pragma mark - dealloc

- (void)dealloc {
    [self removeTimer];
}

@end
