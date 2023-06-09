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
#import "SILCharacteristicEditEnabler.h"
#import "SILEncodingPseudoFieldRowModel.h"
#import <Crashlytics/Crashlytics.h>
#import "UIViewController+Containment.h"
#import <PureLayout/PureLayout.h>
#import "CBPeripheral+Services.h"
#import "SILUUIDProvider.h"
#import "SILOTAUICoordinator.h"
#import "SILLogDataModel.h"
#import "BlueGecko.pch"
#import "SILBrowserLogViewController.h"
#import "SILBrowserConnectionsViewController.h"
#import "UIImage+SILImages.h"
#import "SILBrowserConnectionsViewModel.h"
#import "NSString+SILBrowserNotifications.h"
#import "SILBluetoothBrowser+Constants.h"
#import "UIView+SILShadow.h"

static NSString * const kSpacerCellIdentifieer = @"spacer";
static NSString * const kCornersCellIdentifieer = @"corners";
static NSString * const kOTAButtonTitle = @"OTA";
static NSString * const kScanningForPeripheralsMessage = @"Loading...";

static float kTableRefreshInterval = 1;

@interface SILDebugServicesViewController () <UITableViewDelegate, UITableViewDataSource, CBPeripheralDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, SILDebugPopoverViewControllerDelegate, WYPopoverControllerDelegate, SILCharacteristicEditEnablerDelegate, SILOTAUICoordinatorDelegate, SILDebugCharacteristicCellDelegate, SILServiceCellDelegate, SILBrowserLogViewControllerDelegate, SILBrowserConnectionsViewControllerDelegate, SILDebugServicesMenuViewControllerDelegate, SILDebugCharacteristicEncodingFieldTableViewCellDelegate, SILErrorDetailsViewControllerDelegate, SILDescriptorTableViewCellDelegate>

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

@property (strong, nonatomic) SILBrowserConnectionsViewModel* connectionsViewModel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (weak, nonatomic) IBOutlet UIButton *otaButton;
@property (weak, nonatomic) IBOutlet UIView *infoView;

@end

@implementation SILDebugServicesViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNibsAndSetUpSizing];
    [self startServiceSearch];
    [self setupBrowserExpandableViewManager];
    [self setupConnectionsViewModel];
    self.isUpdatingFirmware = NO;
    [self setupButtons];
    [self setupInfoShadow];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupRefreshControl];
    self.peripheral.delegate = self;
    [self registerForNotifications];
    [self installRSSITimer];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self dismissPopoverIfExist];
    [self removeUnfiredTimers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupRefreshControl {
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self
                            action:@selector(refresh)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}


- (void)dismissPopoverIfExist {
    if (self.popoverController) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
}

- (void)removeUnfiredTimers {
    [self.tableRefreshTimer invalidate];
    self.tableRefreshTimer = nil;
    [self.rssiTimer invalidate];
    self.rssiTimer = nil;
}

- (void)performOTAAction {
    self.isUpdatingFirmware = YES;
    self.otaUICoordinator = [[SILOTAUICoordinator alloc] initWithPeripheral:self.peripheral
                                                            centralManager:self.centralManager
                                                       presentingViewController:self];
    self.otaUICoordinator.delegate = self;
    [self.otaUICoordinator initiateOTAFlow];
}

- (void)setupBrowserExpandableViewManager {
    self.cornerRadius = CornerRadiusStandardValue;
}

- (void)setupInfoShadow {
    self.infoView.layer.zPosition = 1;
    [self.infoView addShadow];
}

- (void)setupButtons {
    [self setLeftAlignedTitle:self.peripheral.name];
    UIBarButtonItem *logButton = [[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed:@"logsIcon"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(logButtonWasTapped)];
    [self.navigationItem setRightBarButtonItems:@[logButton]];
    
    self.otaButton.hidden = ![self.peripheral hasOTAService];
    [self.otaButton addTarget:self action:@selector(performOTAAction) forControlEvents:UIControlEventPrimaryActionTriggered];
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

- (void)setupConnectionsViewModel {
    self.connectionsViewModel = [SILBrowserConnectionsViewModel sharedInstance];
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

// MARK: - Swipe Actions

- (IBAction)swipeToServer:(UISwipeGestureRecognizer *)sender {
    [(SILTabBarController *)self.tabBarController selectItemWithIndex:1];
}

#pragma mark - SILOTAUICoordinatorDelegate

- (void)otaUICoordinatorDidFishishOTAFlow:(SILOTAUICoordinator *)coordinator {
    [self.navigationController popViewControllerAnimated:YES];
    self.isUpdatingFirmware = NO;
    self.peripheral.delegate = self;
}

- (void)otaUICoordinatorDidCancelOTAFlow:(SILOTAUICoordinator *)coordinator {
    self.isUpdatingFirmware = NO;
    self.peripheral.delegate = self;
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
    NSString* uuid = (NSString*)notification.userInfo[SILNotificationKeyUUID];
    NSLog(@"disconnect in debug service");
    if ([uuid isEqualToString:self.peripheral.identifier.UUIDString]) {
        if (!self.isUpdatingFirmware) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
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
    self.rssiTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer* timer){
        if ([blocksafeSelf.peripheral.delegate respondsToSelector:@selector(peripheral:didReadRSSI:error:)]){
            [blocksafeSelf.peripheral readRSSI];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.modelsToDisplay.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self heightForRowAtIndexPath:indexPath];
}

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
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
            CGFloat tableHeight = 0.0;
            
            for (SILDescriptorTableModel * model in modelCharacteristic.descriptorModels) {
                CGSize size = CGSizeMake(self.tableView.bounds.size.width - 120, CGFLOAT_MAX);
                CGRect rect = [[model getAttributedDescriptor] boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
                tableHeight += ceil(rect.size.height);
            }
            
            return 130 + tableHeight;
        }
    } else {
        if ([model isKindOfClass:[SILEncodingPseudoFieldRowModel class]]) {
            return 132.0;
        }
        return 81.0;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    id<SILGenericAttributeTableModel> model = self.modelsToDisplay[indexPath.row];
    if ([tableView indexPathsForVisibleRows][0] == indexPath) {
        [tableView bringSubviewToFront:cell];
    }
    if ([model isEqual:kSpacerCellIdentifieer]) {
        cell.backgroundColor = UIColor.clearColor;
        cell.contentView.backgroundColor = UIColor.clearColor;
        return;
    }
    if ([model isKindOfClass:[SILServiceTableModel class]]) {
        if (model.isExpanded) {
            [cell roundCornersTop];
            [cell addShadowWhenAtTop];
        }  else {
            [cell roundCornersAll];
            [cell addShadowWhenAlone];
        }
    } else {
        if ([self.modelsToDisplay[indexPath.row + 1] isEqual:kSpacerCellIdentifieer]) {
            [cell roundCornersBottom];
            [cell addShadowWhenAtBottom];
        } else {
            [cell roundCornersNone];
            [cell addShadowWhenInMid];
        }
    }
    cell.clipsToBounds = NO;
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGRect size = CGRectMake(tableView.bounds.origin.x, tableView.bounds.origin.y, tableView.bounds.size.width, 16);
    UIView * view = [[UIView alloc] initWithFrame:size];
    view.backgroundColor = UIColor.clearColor;
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [SILTableViewWithShadowCells tableView:tableView viewForFooterInSection:section withHeight:12];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 12;
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
    [serviceCell expandIfAllowed:serviceTableModel.isExpanded];
    [serviceCell layoutIfNeeded];
    return serviceCell;
}

- (SILDebugCharacteristicTableViewCell *)characteristicCellWithModel:(SILCharacteristicTableModel *)characteristicTableModel forTable:(UITableView *)tableView {
    SILDebugCharacteristicTableViewCell *characteristicCell = (SILDebugCharacteristicTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugCharacteristicTableViewCell class])];
    characteristicCell.delegate = self;
    characteristicCell.descriptorDelegate = self;
    [characteristicCell configureWithCharacteristicModel:characteristicTableModel];
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
    cell.delegate = self;
    cell.hexView.valueLabel.text = [[SILCharacteristicFieldValueResolver sharedResolver] hexStringForData:subjectData decimalExponent:0];
    cell.asciiView.valueLabel.text = [[[SILCharacteristicFieldValueResolver sharedResolver] asciiStringForData:subjectData] stringByReplacingOccurrencesOfString:@"\0" withString:@""];
    cell.decimalView.valueLabel.text = [[SILCharacteristicFieldValueResolver sharedResolver] decimalStringForData:subjectData];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [cell layoutIfNeeded];
    return cell;
}

- (SILDebugCharacteristicToggleFieldTableViewCell *)toggleFieldCellWithModel:(SILBitRowModel *)toggleFieldModel forTable:(UITableView *)tableView {
    SILDebugCharacteristicToggleFieldTableViewCell *toggleFieldCell = (SILDebugCharacteristicToggleFieldTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SILDebugCharacteristicToggleFieldTableViewCell class])];
    [toggleFieldCell configureWithBitRowModel:toggleFieldModel];
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

#pragma mark - SILPopoverViewControllerDelegate

- (void)didClosePopoverViewController:(SILDebugPopoverViewController *)popoverViewController {
    [self closePopover:^{
        self.popoverController = nil;
        [self.tableView reloadData];
    }];
}

#pragma mark - SILCharacteristicEditEnablerDelegate

- (BOOL)saveCharacteristic:(SILCharacteristicTableModel *)characteristicModel withWriteType:(CBCharacteristicWriteType)writeType error:(NSError *__autoreleasing *)error {
    BOOL success = [characteristicModel writeIfAllowedToPeripheral:self.peripheral withWriteType:writeType error:error];
    
    if (success == NO & error != nil) {
        *error = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:@{
            NSUnderlyingErrorKey: *error,
            NSLocalizedDescriptionKey: [self prepareErrorDescription:*error],
        }];
    } else {
        NSData *dataAboutToBeWritten = [characteristicModel dataToWriteWithError:error];
        
        SILCharacteristicTableModel *originalCharacteristicTableModel = [self findCharacteristicTableModelForCharacteristic:characteristicModel.characteristic];
        [originalCharacteristicTableModel setDataToWrite:dataAboutToBeWritten];
    }
    
    return success;
}

- (void)beginValueEditWithValue:(SILValueFieldRowModel *)valueModel {
    
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
    [self closePopover:^{
        self.popoverController = nil;
    }];
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
    SILCharacteristicWriteViewController *characteristicWriteViewController = [[SILCharacteristicWriteViewController alloc] initWithCharacteristic:characteristic delegate:self];
    characteristicWriteViewController.popoverDelegate = self;
    self.popoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:characteristicWriteViewController
                                                                             presentingViewController:self
                                                                                             delegate:self
                                                                                             animated:YES];

}

- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestNotifyForCharacteristic:(CBCharacteristic *)characteristic withValue:(BOOL)value {
    [self.peripheral setNotifyValue:value forCharacteristic:characteristic];
    [self updateClientCharacteristicConfigurationDescriptorValueForCharacteristic:characteristic];
}

- (void)cell:(SILDebugCharacteristicTableViewCell *)cell didRequestIndicateForCharacteristic:(CBCharacteristic *)characteristic withValue:(BOOL)value {
    [self.peripheral setNotifyValue:value forCharacteristic:characteristic];
    [self updateClientCharacteristicConfigurationDescriptorValueForCharacteristic:characteristic];
}

- (void)updateClientCharacteristicConfigurationDescriptorValueForCharacteristic:(CBCharacteristic *)characteristic {
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        if ([descriptor.UUID.UUIDString isEqual:CBUUIDClientCharacteristicConfigurationString]) {
            [self.peripheral readValueForDescriptor:descriptor];
            break;
        }
    }
    [self refreshTable];
}

#pragma mark = SILDescriptorsTableViewCellDelegate

- (void)cellDidRequestReadForDescriptor:(CBDescriptor *)descriptor {
    [self.peripheral readValueForDescriptor:descriptor];
    [self refreshTable];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error != nil) {
        if ([self isATTError:error]) {
            [self showErrorDetailsPopoupWithError:error];
        }
    } else {
        self.tableView.hidden = NO;
        self.headerView.hidden = NO;
        for (CBService *service in peripheral.services) {
            [self addOrUpdateModelForService:service];
            [peripheral discoverCharacteristics:nil forService:service];
        }
        [self markTableForUpdate];
    }
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didDiscoverServices: " andPeripheral:peripheral andError:error]];
    self.otaButton.hidden = !peripheral.hasOTAService;
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error != nil) {
        if ([self isATTError:error]) {
            [self showErrorDetailsPopoupWithError:error];
        }
    } else {
        for (CBCharacteristic *characteristic in service.characteristics) {
            [self addOrUpdateModelForCharacteristic:characteristic forService:service];
            [peripheral discoverDescriptorsForCharacteristic:characteristic];
        }
        [self markTableForUpdate];
    }

    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didDiscoverCharacteristics: " andPeripheral:peripheral andError:error]];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    [CrashlyticsKit setObjectValue:peripheral.name forKey:@"peripheral"];
    [self addOrUpdateModelForCharacteristic:characteristic forService:characteristic.service];
    [self refreshTable];
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescriptionForUpdateValueOfCharacteristic:characteristic andPeripheral:peripheral andError:error]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    BOOL displayLog = NO;
    if (error != nil) {
        if ([self isATTError:error]) {
            [self showErrorDetailsPopoupWithError:error];
        }
        displayLog = YES;
    } else {
        for (CBDescriptor *descriptor in characteristic.descriptors) {
            BOOL wasAddedDescriptor = [self addOrUpdateModelForDescriptor:descriptor forCharacteristic:characteristic];
            displayLog = displayLog || wasAddedDescriptor;
        }
        [self markTableForUpdate];
    }
    
    if (displayLog) {
        [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didDiscoverDescriptorsForCharacteristic: " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    [self addOrUpdateModelForDescriptor:descriptor forCharacteristic:descriptor.characteristic];
    [self markTableForUpdate];
    [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didUpdateValueForDescriptor: " andDescriptor:descriptor andPeripheral:peripheral andError:error]];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    SILCharacteristicTableModel *characteristicTableModel = [self findCharacteristicTableModelForCharacteristic:characteristic];
    if (error) {
        NSLog(@"Write failed, restoring backup");
        [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didWriteValueForCharacteristic: Write failed, restoring backup " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
        if ([self isATTError:error]) {
            [self showErrorDetailsPopoupWithError:error];
        }

        [characteristicTableModel writeFailed];
    } else {
        NSLog(@"Write successful, updating read value");
        [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didWriteValueForCharacteristic: Write successful! " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
        [self showToastWithMessage:@"Characteristic write success"
                         toastType:ToastTypeInfo
               shouldHasSizeOfText:YES
                        completion:^{}];
        
        [characteristicTableModel writeSucceeded];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    NSMutableString* rssiDescription = [NSMutableString stringWithString:[NSString stringWithFormat:@"%@", RSSI]];
    [rssiDescription appendString:@" dBm"];
    self.rssiLabel.text = rssiDescription;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error == nil) {
        [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didUpdateNotificationStateForCharacteristic: Successful! " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
    } else {
        [self postRegisterLogNotification:[SILLogDataModel prepareLogDescription:@"didUpdateNotificationStateForCharacteristic: Failed! " andCharacteristic:characteristic andPeripheral:peripheral andError:error]];
        if ([self isATTError:error]) {
            [self showErrorDetailsPopoupWithError:error];
        }
    }    
    [self refreshTable];
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
    NSLog(@"Did modify services");
    [self refresh];
}

- (BOOL)isATTError:(NSError*)error {
    if (error == nil) {
        return NO;
    }
    
    return error.domain == CBATTErrorDomain && error.code != 0;
}

- (void)showErrorDetailsPopoupWithError:(NSError*)error {
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        SILErrorDetailsViewController* errorDetails = [[SILErrorDetailsViewController alloc] initWithError:error delegate:self];
        self.popoverController = [WYPopoverController sil_presentCenterPopoverWithContentViewController:errorDetails
                                                                                     presentingViewController:self
                                                                                                     delegate:self
                                                                                                     animated:YES];
    });
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
                NSLog(@"Requirements not met for %@ - %@", characteristicModel.bluetoothModel.name, fieldModel.fieldModel.name);
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

// SLMAIN-333 - This is a workaround to disconnect and reconnect to the peripheral when dynamic services/characteristics are toggled.
// If this isn't done, services cannot be refreshed more than once.
- (void)refresh {
    void (^serviceSearch)(void) = ^(void) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self startServiceSearch];
            [self refreshTable];
            [self.tableView setHidden:NO];
        });
    };
    self.allServiceModels = [[NSMutableArray alloc] init];
    [self.centralManager connectToDiscoveredPeripheral: [self.centralManager discoveredPeripheralForPeripheral:self.peripheral]];
    [self.tableView setHidden:YES];
    serviceSearch();
}

- (void)postRegisterLogNotification:(NSString*)description {
    [[NSNotificationCenter defaultCenter] postNotificationName:SILNotificationRegisterLog object:self userInfo:@{ SILNotificationKeyDescription : description}];
}

- (SILCharacteristicTableModel *)findCharacteristicTableModelForCharacteristic:(CBCharacteristic *)characteristic {
    SILServiceTableModel *serviceTableModel = [self findServiceModelForService:characteristic.service];
    SILCharacteristicTableModel *characteristicTableModel = [self findCharacteristicModelForCharacteristic:characteristic forServiceModel:serviceTableModel];
    
    return characteristicTableModel;
}

#pragma mark - dealloc

- (void)dealloc {
    [self removeTimer];
}

#pragma mark - SILDebugCharacteristicEncodingFieldTableViewCellDelegate

- (void)copyButtonWasClicked {
    [self showToastWithMessage:@"Copied to clipboard!" toastType:ToastTypeInfo shouldHasSizeOfText: YES completion:^{}];
}

#pragma mark - SILErrorDetailsViewController

- (void)shouldCloseErrorDetailsViewController:(SILErrorDetailsViewController * _Nonnull)errorDetailsViewController {
    [self closePopover:^{
        self.popoverController = nil;
    }];
}

- (void)closePopover:(void (^)(void))completion {
    [self.popoverController dismissPopoverAnimated:YES completion:completion];
}

- (void)logButtonWasTapped {
    UIStoryboard *logViewStoryboard = [UIStoryboard storyboardWithName:SILAppBluetoothBrowserHome bundle:nil];
    SILBrowserLogViewController *logViewController = [logViewStoryboard instantiateViewControllerWithIdentifier:SILSceneLog];
    [self.navigationController pushViewController:logViewController animated:YES];
}

@end
