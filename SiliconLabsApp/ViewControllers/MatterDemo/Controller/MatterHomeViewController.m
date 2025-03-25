//
//  MatterHomeViewController.m
//  MatterMyTool
//
//  Created by Mantosh Kumar on 21/09/23.
//

#import "MatterHomeViewController.h"
#import "OnOffViewController.h"
#import "QRCodeViewController.h"
#import "UnpairDevicesViewController.h"
#import "SILSelectedMatterDeviceCell.h"

#import "WindowOpenCloseViewController.h"
#import "DoorLockViewController.h"
#import "SwitchOnOffViewController.h"
#import "TemperatureViewController.h"
#import "PlugViewController.h"
#import "TemperatureSensorController.h"
#import "OccupancySensorViewController.h"
#import "ContactSensorViewController.h"
#import "DishwasherViewController.h"
#import "DefaultsUtils.h"
#import "CHIPUIViewUtils.h"
#import <Matter/Matter.h>
#import "DeviceSelector.h"
#import "FRHyperLabel.h"

@protocol MatterDeviceListDelegate <NSObject>
- (void) didCommissionComplete:(BOOL)isCommissioned;
@end

@interface MatterHomeViewController () <MatterDeviceListDelegate, QRCodeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *noDevicesAddedView;
@property (nonatomic, weak) IBOutlet FRHyperLabel *guidanceLabel;

@property (weak, nonatomic) QRCodeViewController * qrCodeViewController;
@property (weak, nonatomic) OnOffViewController * onOffViewController;
@property (weak, nonatomic) WindowOpenCloseViewController * windowOpenCloseViewController;
@property (weak, nonatomic) DoorLockViewController * doorLockViewController;
@property (weak, nonatomic) SwitchOnOffViewController * switchOnOffViewController;
@property (weak, nonatomic) TemperatureViewController * temperatureViewController;
@property (weak, nonatomic) PlugViewController * plugViewController;
@property (weak, nonatomic) TemperatureSensorController * temperatureSensorController;
@property (weak, nonatomic) OccupancySensorViewController * occupancySensorViewController;
@property (weak, nonatomic) ContactSensorViewController * contactSensorViewController;
@property (weak, nonatomic) DishwasherViewController * dishwasherViewController;
@property (strong, nonatomic) MTRDescriptorClusterDeviceTypeStruct * descriptorClusterDeviceTypeStruct;
@property (strong, nonatomic) NSTimer *tempRefreshTimerHome;
@property (weak, nonatomic) IBOutlet UIView *matterSetupInfoView;

@end

@implementation MatterHomeViewController

NSMutableArray * deviceNodeList;
NSMutableArray * deviceListTemp;
int arrayCount;
int isTimerOn;
int commissiond;

// MARK: View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Matter Devices";
    self.tabBarController.tabBar.hidden = YES;
    self.tableView.hidden = YES;
    self.noDevicesAddedView.hidden = YES;
    // Register cell
    [_tableView registerNib:[UINib nibWithNibName:@"SILSelectedMatterDeviceCell" bundle:nil] forCellReuseIdentifier:@"SILSelectedMatterDeviceCell"];
    
    commissiond = 0;
    isTimerOn = 0;
    [self updateListOfDevice];
    //[self fetchFabricsList];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveTestNotification:) name:@"controllerNotification" object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    // Load connected device
    [self setRightBarButton];
    [self initialSetup];
    self.matterSetupInfoView.hidden = true;
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.matterSetupInfoView.bounds];
    self.matterSetupInfoView.layer.masksToBounds = NO;
    self.matterSetupInfoView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.matterSetupInfoView.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.matterSetupInfoView.layer.shadowOpacity = 0.2f;
    self.matterSetupInfoView.layer.shadowPath = shadowPath.CGPath;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([_tempRefreshTimerHome isValid]) {
        [_tempRefreshTimerHome invalidate];
    }
    _tempRefreshTimerHome = nil;
    isTimerOn = 1;
    //commissiond = 0;
}

-(void) initialSetup {
    _guidanceLabel.numberOfLines = 0;
    
    // Define a normal attributed string
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont helveticaNeueWithSize:14]};
    _guidanceLabel.attributedText = [[NSAttributedString alloc]initWithString:kQuickStartGuide attributes:attributes];
    
    // Define a selection handler block
    void(^handler)(FRHyperLabel *label, NSString *substring) = ^(FRHyperLabel *label, NSString *substring){
        // Go to link
        UIApplication *application = [UIApplication sharedApplication];
          NSURL *URL = [NSURL URLWithString:@"https://docs.silabs.com/matter/2.1.0/matter-overview/"];
          [application openURL:URL options:@{} completionHandler:^(BOOL success) {
              if (success) {
                  // success action
              }
          }];
    };
    // Add link to substrings
    [_guidanceLabel setLinksForSubstrings:@[@"Quick-Start Guide"] withLinkHandler:handler];
}

- (void) updateListOfDevice {
    uint64_t nextDeviceID = MTRGetNextAvailableDeviceID();
    deviceNodeList = [[NSMutableArray alloc] init];
    
    for (uint64_t i = 0; i < nextDeviceID; i++) {
        if (MTRIsDevicePaired(i)) {
            [deviceNodeList addObject:[@(i) stringValue]];
        }
    }
    deviceListTemp = [[NSMutableArray alloc]init];
    arrayCount = 0;
    
    deviceListTemp = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    //NSLog(@" MKdeviceListTemp ======== %@\n", deviceListTemp);
    if ([deviceListTemp count] > 0){
        self.noDevicesAddedView.hidden = YES;
        if(isTimerOn == 0){
            [SVProgressHUD showWithStatus: @"Connecting to commissioned device..."];
        }
    }else{
        self.noDevicesAddedView.hidden = NO;
    }
    [self getDeviceType: deviceListTemp];
}

- (void) receiveTestNotification:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"controllerNotification"])
        NSLog (@"Successfully received the test notification!");
    // NSLog(@"%@", [[notification object] isEqual:QRCodeViewController]);
    NSDictionary *tempDic = [notification userInfo];
    NSString *controllerName = [tempDic valueForKey:@"controller"];
    [self refreshTable];
}

//- (void) setLeftAlignedTitle:(NSString*) text {
//    
//    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    UIImage *backBtnImage = [UIImage imageNamed:@"btn_navbar_back.png"]  ;
//    [backBtn setBackgroundImage: backBtnImage forState:UIControlStateNormal];
//    [backBtn addTarget:self action:@selector(goback) forControlEvents:UIControlEventTouchUpInside];
//    backBtn.frame = CGRectMake(0, 0, 54, 30);
//    backBtn.titleLabel.text = @"Matter Demo";
//    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:backBtn] ;
//    self.navigationItem.leftBarButtonItem = backButton;
//}

- (void) setRightBarButton {
    UIImage* qrImg = [UIImage imageNamed:@"qr"];
    //UIButton *btn = [[UIButton alloc] initWithFrame: CGRectMake(0,0,25,25)];
    UIButton *btn = [[UIButton alloc] initWithFrame: CGRectMake(10,0,60,50)];
    //[btn setBackgroundImage:qrImg forState:UIControlStateNormal];
    [btn setImage:qrImg forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(goToScanScreen:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightButton =[[UIBarButtonItem alloc] initWithCustomView:btn];
    
    UIImage* qrImg1 = [UIImage imageNamed:@"refresh"];
    //UIButton *btn1 = [[UIButton alloc] initWithFrame: CGRectMake(-15,0,30,30)];
    UIButton *btn1 = [[UIButton alloc] initWithFrame: CGRectMake(-15,0,35,35)];
    [btn1 setBackgroundImage:qrImg1 forState:UIControlStateNormal];
    //[btn1 setImage:qrImg1 forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(refressListScreen:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightButton1 =[[UIBarButtonItem alloc] initWithCustomView:btn1];
    
    self.navigationItem.rightBarButtonItems = @[rightButton, rightButton1];
}

- (void)goback {
    [self.navigationController popViewControllerAnimated: YES];
}

// MARK: tableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return deviceListTemp.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"SILSelectedMatterDeviceCell";
    
    SILSelectedMatterDeviceCell *cell = (SILSelectedMatterDeviceCell *)[tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SimpleTableCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    NSDictionary * deviceDic = deviceListTemp[indexPath.row];
    //NSLog(@" deviceType:- %@",[deviceDic valueForKey:@"deviceType"]);
    //cell.delegate = self;
    [cell setCell: deviceDic];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    commissiond = 0;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary * deviceDic = deviceListTemp[indexPath.row];
    NSNumber *nodeNumber = [deviceDic valueForKey:@"nodeId"];
    NSNumber *endPointNumber = [deviceDic valueForKey:@"endPoint"];
    NSString *connectedDevice = [deviceDic valueForKey:@"isConnected"];
    if ([connectedDevice isEqual:@"1"]){
        [self pushToClusterView:[NSString stringWithFormat:@"%@",[deviceDic valueForKey:@"deviceType"]] node:nodeNumber endpoint:endPointNumber];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //remove the deleted object from your data source.
        NSDictionary * deviceDic = deviceListTemp[indexPath.row];
        NSLog(@"selected DeviceID :- %@", deviceDic);
        NSNumber *nodeNumber = [deviceDic valueForKey:@"nodeId"];
        NSNumber *endPointNumber = [deviceDic valueForKey:@"endPoint"];
        uint64_t deviceId = nodeNumber.intValue;
        [self showDeletePopup:deviceId cellIndex:indexPath.row];
    }
}

- (void)pushQRCodeScannerWithSkipCheck:(BOOL)skipIosCheck {
    NSLog(@"%@", deviceListTemp);
    if (skipIosCheck) {
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Cluster" bundle:[NSBundle mainBundle]];
        _qrCodeViewController = [story instantiateViewControllerWithIdentifier:@"QRCodeViewController"];
        _qrCodeViewController.delegate = self;
        [self.navigationController pushViewController:_qrCodeViewController animated: YES];
    } else {
        if (@available(iOS 15.4, *)) {
            // Device using the required iOS version (>= 15.4)
            [self pushQRCodeScannerWithSkipCheck:YES];
        } else {
            // Device NOT using the required iOS version (< 15.4)
            // Show a warning, but let the user continue
            UIAlertController * alertController =
            [UIAlertController alertControllerWithTitle:@"Warning"
                                                message:@"QRCode scanner to pair a matter device requires iOS >= 15.4"
                                         preferredStyle:UIAlertControllerStyleAlert];
            __weak typeof(self) weakSelf = self;
            [alertController addAction:[UIAlertAction actionWithTitle:@"I understand"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                typeof(self) strongSelf = weakSelf;
                if (strongSelf) {
                    [strongSelf pushQRCodeScannerWithSkipCheck:YES];
                }
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
}

- (void)pushToClusterView:(NSString *)deviceType node:(NSNumber *)nodeId endpoint:(NSNumber *)endPoint {
    
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Cluster" bundle:[NSBundle mainBundle]];
    
    if ([deviceType isEqualToString:@"514"]) {
        _windowOpenCloseViewController = [story instantiateViewControllerWithIdentifier:@"WindowOpenCloseViewController"];
        _windowOpenCloseViewController.nodeId = nodeId;
        _windowOpenCloseViewController.endPoint = endPoint;
        [self.navigationController pushViewController:_windowOpenCloseViewController animated: YES];
    } else if ([deviceType isEqualToString:@"10"]){
        _doorLockViewController = [story instantiateViewControllerWithIdentifier:@"DoorLockViewController"];
        _doorLockViewController.nodeId = nodeId;
        _doorLockViewController.endPoint = endPoint;
        [self.navigationController pushViewController:_doorLockViewController animated: YES];
    } else if ([deviceType isEqualToString:DimmingLight] || [deviceType isEqualToString:EnhancedColorLight] || [deviceType isEqualToString:OnOffLight] || [deviceType isEqualToString:TemperatureColorLight]){
        _onOffViewController = [story instantiateViewControllerWithIdentifier:@"OnOffViewController"];
        _onOffViewController.nodeId = nodeId;
        _onOffViewController.endPoint = endPoint;
        [self.navigationController pushViewController:_onOffViewController animated: YES];
    } else if ([deviceType isEqualToString:@"769"]){
        _temperatureViewController = [story instantiateViewControllerWithIdentifier:@"TemperatureViewController"];
        _temperatureViewController.nodeId = nodeId;
        _temperatureViewController.endPoint = endPoint;
        [self.navigationController pushViewController:_temperatureViewController animated: YES];
    } else if ([deviceType isEqualToString:@"267"]){
        _plugViewController = [story instantiateViewControllerWithIdentifier:@"PlugViewController"];
        _plugViewController.nodeId = nodeId;
        _plugViewController.endPoint = endPoint;
        [self.navigationController pushViewController:_plugViewController animated: YES];
    }else if ([deviceType isEqualToString:@"770"]){
        _temperatureSensorController = [story instantiateViewControllerWithIdentifier:@"TemperatureSensorController"];
        _temperatureSensorController.nodeId = nodeId;
        _temperatureSensorController.endPoint = endPoint;
        [self.navigationController pushViewController:_temperatureSensorController animated: YES];
    }else if ([deviceType isEqualToString:@"21"]){
        _contactSensorViewController = [story instantiateViewControllerWithIdentifier:@"ContactSensorViewController"];
        _contactSensorViewController.nodeId = nodeId;
        _contactSensorViewController.endPoint = endPoint;
        [self.navigationController pushViewController:_contactSensorViewController animated: YES];
    }else if ([deviceType isEqualToString:@"263"]){
        _occupancySensorViewController = [story instantiateViewControllerWithIdentifier:@"OccupancySensorViewController"];
        _occupancySensorViewController.nodeId = nodeId;
        _occupancySensorViewController.endPoint = endPoint;
        [self.navigationController pushViewController:_occupancySensorViewController animated: YES];
    }else if ([deviceType isEqualToString:@"259"]){
        _switchOnOffViewController = [story instantiateViewControllerWithIdentifier:@"SwitchOnOffViewController"];
        _switchOnOffViewController.nodeId = nodeId;
        _switchOnOffViewController.endPoint = endPoint;
        [self.navigationController pushViewController:_switchOnOffViewController animated: YES];
    } else if ([deviceType isEqualToString:Dishwasher]){
        NSString *currentVersion = [[UIDevice currentDevice] systemVersion];
        NSString *targetVersion = @"17.4";
        NSComparisonResult result = [currentVersion compare:targetVersion options:NSNumericSearch];
        if (result == NSOrderedAscending) {
            NSLog(@"The device is running older then IOS 17.4");
            [self showAlertMessage:@"Dishwasher Demo requires iOS 17.4 or later. Please update your iOS version to access the feature"];
        } else {
            NSLog(@"The device is running iOS 17.4 or later.");
            _dishwasherViewController = [story instantiateViewControllerWithIdentifier:@"DishwasherViewController"];
            _dishwasherViewController.nodeId = nodeId;
            _dishwasherViewController.endPoint = endPoint;
            [self.navigationController pushViewController:_dishwasherViewController animated: YES];
        } 
    } else if ([deviceType isEqualToString: AirQuality]){
        _temperatureViewController = [story instantiateViewControllerWithIdentifier:@"AirQualityViewController"];
        _temperatureViewController.nodeId = nodeId;
        _temperatureViewController.endPoint = endPoint;
        [self.navigationController pushViewController:_temperatureViewController animated: YES];
    }
}

- (void)pushUnpairDevices {
    UnpairDevicesViewController * controller = [UnpairDevicesViewController new];
    [self.navigationController pushViewController:controller animated:YES];
}

// MARK: Actions
- (IBAction)goToScanScreen:(id)sender {
    [self pushQRCodeScannerWithSkipCheck: NO];
}

- (IBAction)refressListScreen:(id)sender {
    // refressListScreen
//    isTimerOn = 0;
//    [self updateListOfDevice];
    [self viewDidLoad];
}
- (IBAction)setupInfoAction:(id)sender {
    self.matterSetupInfoView.hidden = false;
//    [self showAlertMessage:@"To use matter "];
}

- (IBAction)dismissPopupView:(id)sender {
    self.matterSetupInfoView.hidden = true;
}


- (void) didCommissionComplete:(BOOL)isCommissioned {
    
}

-(void) showDeletePopup:(uint64_t)deviceId cellIndex:(uint64_t)indexValue {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:@"Do you want to delete Device?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //arrayCount = 0;
        MTRUnpairDeviceWithID(deviceId);
        // need to update index
        //[deviceListTemp removeObjectAtIndex:indexValue.intValue];
        NSUInteger unsignedInt = (NSUInteger)indexValue;
        [deviceListTemp removeObjectAtIndex:unsignedInt];
        [[NSUserDefaults standardUserDefaults] setObject:deviceListTemp forKey:@"saved_list"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        //[self updateListOfDevice];
        //[self showHideTableView: deviceListTemp];
        [ self deleteDishwasherSavedStatus];
        [_tableView reloadData];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (deviceListTemp.count > 0) {
                self.tableView.hidden = NO;
                self.noDevicesAddedView.hidden = YES;
            } else {
                self.tableView.hidden = YES;
                self.noDevicesAddedView.hidden = NO;
            }
        });
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

// Store Dishwasher Status
- (void)deleteDishwasherSavedStatus {
    
    bool isDWBackButtonFlow = [[NSUserDefaults standardUserDefaults] boolForKey:@"isBackButtonFlow"];
    if (isDWBackButtonFlow) {
        NSUserDefaults *dwValue = [NSUserDefaults standardUserDefaults];
        [dwValue removeObjectForKey:@"isBackButtonFlow"];
        [dwValue synchronize];
    }
}

-(void) showAlertMessage:(NSString *) message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) didDeleteAction:(NSDictionary *_Nullable)selectedDevice  tableCell:(UITableViewCell * _Nullable) cell {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSDictionary * deviceDic = deviceListTemp[indexPath.row];
    NSLog(@"selected DeviceID :- %@", deviceDic);
    NSNumber *nodeNumber = [deviceDic valueForKey:@"nodeId"];
    NSNumber *endPointNumber = [deviceDic valueForKey:@"endPoint"];
    uint64_t deviceId = nodeNumber.intValue;
    [self showDeletePopup: deviceId cellIndex:indexPath.row];
}

- (void)getDeviceType:(NSMutableArray *) nodeIds {
    
    for (int j = 0; j < [nodeIds count]; j++){
        NSString *connectedDevice = [deviceListTemp[j] valueForKey:@"isConnected"];
        NSLog(@"%@",connectedDevice);
        NSNumber *nodeId = [deviceListTemp[j] valueForKey:@"nodeId"];
        uint64_t devId = nodeId.intValue;
        
        if (MTRGetConnectedDeviceWithID(devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
            if (chipDevice) {
                NSLog(@"%@",chipDevice.isAccessibilityElement);
                MTRBaseClusterDescriptor * descriptorCluster =
                [[MTRBaseClusterDescriptor alloc] initWithDevice:chipDevice
                                                        endpoint:1
                                                           queue:dispatch_get_main_queue()];
                
                [descriptorCluster readAttributeDeviceListWithCompletionHandler:^( NSArray * _Nullable value, NSError * _Nullable error) {
                    if (error) {
                        arrayCount ++;
                        //[SVProgressHUD dismiss];
                        [self updateDeviceList:@"0" nodeId:nodeId deviceType:@""];
                        return;
                    }
                    _descriptorClusterDeviceTypeStruct = value[0];
//                    NSLog(@"%@",_descriptorClusterDeviceTypeStruct.deviceType);
//                    NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
//                    [deviceDic setObject:self->_descriptorClusterDeviceTypeStruct.deviceType forKey:@"deviceType"];
//                    [deviceDic setObject:nodeId forKey:@"nodeId"];
//                    [deviceDic setObject:@1 forKey:@"endPoint"];
//                    [deviceDic setObject:@"1" forKey:@"isConnected"];
//                    [deviceListTemp addObject:deviceDic];
//                    NSLog(@"deviceListTemp:- %@",deviceListTemp);
                    arrayCount ++;
                    //[self showHideTableView: deviceListTemp];
                    [self updateDeviceList:@"1" nodeId:nodeId deviceType:[self->_descriptorClusterDeviceTypeStruct.deviceType stringValue]];
                }];
            } else {
                NSLog(@"Failed to establish a connection with the device");
                arrayCount ++;
                [self updateDeviceList:@"0" nodeId:nodeId deviceType:@""];
            }
        })) {
            NSLog(@"Waiting for connection with the device");
        } else {
            NSLog(@"Failed to trigger the connection with the device");
            arrayCount ++;
            [self updateDeviceList:@"0" nodeId:nodeId deviceType:@""];
        }
    }
}

-(void)updateDeviceList:(NSString *)connected nodeId:(NSNumber *)node_id deviceType:(NSString *)typeOfDevice{
    //NSArray *filtered = [deviceListTemp filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(nodeId == %@)", @(7)]];
    NSUInteger index2 = [deviceListTemp indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];
    //NSLog(@" index2 ======== %d\n", index2);
    if([deviceListTemp count] > 0){
        NSString *deviceType =@"";
        if ([typeOfDevice isEqualToString:@""]){
            deviceType = [deviceListTemp[index2] valueForKey:@"deviceType"];
        }else{
            deviceType = typeOfDevice;
        }
        NSNumber *nodeId = [deviceListTemp[index2] valueForKey:@"nodeId"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[deviceListTemp[index2] valueForKey:@"title"] forKey:@"title"];
        
        [deviceListTemp replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:deviceListTemp forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",deviceListTemp);
    
    [self showHideTableView: deviceListTemp];
}
-(void) showHideTableView:(NSMutableArray*) deviceCount {
    dispatch_async(dispatch_get_main_queue(), ^{
        deviceListTemp = [[NSMutableArray alloc] init];
        deviceListTemp = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
        [_tableView reloadData];
    });
    if (arrayCount >= [deviceListTemp count]){
        [SVProgressHUD dismiss];
        dispatch_async(dispatch_get_main_queue(), ^{
//            deviceListTemp = [[NSMutableArray alloc] init];
//            deviceListTemp = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
//            [_tableView reloadData];
            if(isTimerOn == 0){
                //[self autoRefress];
            }
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (deviceListTemp.count > 0) {
            self.tableView.hidden = NO;
            self.noDevicesAddedView.hidden = YES;
        } else {
            self.tableView.hidden = YES;
            self.noDevicesAddedView.hidden = NO;
        }
    });
}

//MARK: QRCodeViewControllerDelegate
- (void) affterCommission:(NSNumber *_Nullable)nodeId{
    [self refreshTable];
}

-(void)refreshTable{
    deviceListTemp = [[NSMutableArray alloc] init];
    deviceListTemp = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (deviceListTemp.count > 0) {
            self.tableView.hidden = NO;
            self.noDevicesAddedView.hidden = YES;
        } else {
            self.tableView.hidden = YES;
            self.noDevicesAddedView.hidden = NO;
        }
    });
    [_tableView reloadData];
}
#pragma mark - Timers

- (void)autoRefress {
    self.tempRefreshTimerHome = [NSTimer scheduledTimerWithTimeInterval:30.0f
                                                                 target:self
                                                               selector:@selector(getCurrent:)
                                                               userInfo:nil repeats:YES];
}

- (void) getCurrent:(NSTimer *)timer {
    isTimerOn = 1;
    [self updateListOfDevice];
}
- (void)startTimer {
    self.tempRefreshTimerHome = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                                 target:self
                                                               selector:@selector(startRefress:)
                                                               userInfo:nil repeats:NO];
}

- (void) startRefress:(NSTimer *)timer {
    isTimerOn = 1;
    [self autoRefress];
}

@end
