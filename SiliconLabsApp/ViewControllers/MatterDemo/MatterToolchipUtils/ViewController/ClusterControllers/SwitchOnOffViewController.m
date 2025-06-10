//
//  SwitchOnOffViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 03/10/23.
//  Copyright © 2023 SiliconLabs. All rights reserved.
//

#import "SwitchOnOffViewController.h"
#import "CHIPUIViewUtils.h"
#import "SILLightSwitchTableViewCell.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>

@interface SwitchOnOffViewController ()

@property (nonatomic, strong) NSArray *data;
@property (strong, nonatomic) NSMutableArray *selectedIndexPaths;


@end

@implementation SwitchOnOffViewController
@synthesize  nodeId, endPoint, deviceType, deviceName;

NSMutableArray * allDeviceNodeList;
NSMutableArray * allDeviceListTemp;
NSMutableArray * allLightDeviceList;
NSNumber * lightNodeId;
NSString * lightNodeType;
NSString * lightNodeName;
MTRDeviceController * controller;

BOOL isBind;
NSMutableArray *bindedDevice;


- (void)viewDidLoad {
    [super viewDidLoad];
    controller = InitializeMTR();
    // Register cell
    [_tableView registerNib:[UINib nibWithNibName:@"SILLightSwitchTableViewCell" bundle:nil] forCellReuseIdentifier:@"SILLightSwitchTableViewCell"];
    self.selectedIndexPaths = [NSMutableArray array];
    self.selectedIndexPaths = nil;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.data = @[@"Cell 1", @"Cell 2", @"Cell 3", @"Cell 4", @"Cell 5"];
    //[self updateDeviceArray];
    bindedDevice = [[NSMutableArray alloc] init];
    
    [SVProgressHUD showWithStatus: @"Currently fetching binding information, which involves retrieving specific data required to establish secure connections and ensure proper interaction between the app's components and external systems."];
    [self getSwitchBindValue];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupUIElements];
    self.noDeviceFoundView.hidden = true;
    
    [self updateListOfDevice];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSDictionary* userInfo = @{@"controller": @"SwitchOnOffViewController"};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}


//MARK: UI Read Switch bind value
- (void)getSwitchBindValue{
    NSNumber *nodeIdSwitch = nodeId;
    uint64_t swdeviceId = nodeIdSwitch.intValue;
    NSLog(@"%@", [MTRBaseDevice deviceWithNodeID:nodeIdSwitch controller:controller]);
    MTRBaseDevice * _Nullable device = [MTRBaseDevice deviceWithNodeID:nodeIdSwitch controller:controller];
    
    if(device) {
        
        MTRBaseClusterBinding *bnd = [[MTRBaseClusterBinding alloc] initWithDevice:device endpoint:1 queue:dispatch_get_main_queue()];
        MTRReadParams *pr=[[MTRReadParams alloc] init];
        //pr.fabricFiltered = @1;
        
        [bnd readAttributeBindingWithParams:pr completion:^(NSArray * _Nullable value, NSError * _Nullable error) {
            NSLog(@"bind: %@", error);
            [self dismissProgressView];
            if (error) {
                
            }else{
                NSLog(@"bind value: %@", value);
            }
        }];
    }else{
        
    }
}
// MARK: UI Setup

- (void)setupUIElements {
    
    self.cellBGView.layer.cornerRadius = 5;
    self.cellBGView.clipsToBounds = YES;
    
    self.bindButton.layer.cornerRadius = 5;
    self.bindButton.clipsToBounds = YES;
    
    self.bindLightSwitchView.layer.cornerRadius = 5;
    self.bindLightSwitchView.clipsToBounds = YES;
    
    self.noDeviceFoundView.layer.cornerRadius = 5;
    self.noDeviceFoundView.clipsToBounds = YES;
    
    self.bindButton.backgroundColor = UIColor.sil_silverChaliceColor;
    self.bindButton.enabled = NO;
}

- (void) updateListOfDevice {
    allDeviceNodeList = [[NSMutableArray alloc] init];
    allLightDeviceList = [[NSMutableArray alloc]init];
    
    uint64_t nextDeviceID = MTRGetNextAvailableDeviceID();
    
    for (uint64_t i = 0; i < nextDeviceID; i++) {
        if (MTRIsDevicePaired(i)) {
            [allDeviceNodeList addObject:[@(i) stringValue]];
        }
    }
    allDeviceListTemp = [[NSMutableArray alloc]init];
    allDeviceListTemp = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    
    NSLog(@"device List Temp ======== %@\n", allDeviceListTemp);
    [self getDeviceType: allDeviceListTemp];
    
}

- (void)getDeviceType:(NSMutableArray *) allDeviceList {
    allLightDeviceList = [[NSMutableArray alloc] init];

    for (int index = 0; index < [allDeviceList count]; index++) {
        NSString *connectedDevice = [allDeviceListTemp[index] valueForKey:@"isConnected"];
        NSNumber *nodeIdTemp = [allDeviceListTemp[index] valueForKey:@"nodeId"];
        uint64_t devId = nodeIdTemp.intValue;
        if (nodeIdTemp == nodeId) {
            NSString *bindStringValue = [NSString stringWithFormat:@"%@", [allDeviceListTemp[index] valueForKey:@"isBinded"]];
            if ([bindStringValue isEqual:@"true"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    isBind = true;
                    self.bindButton.backgroundColor = UIColor.sil_siliconLabsRedColor;
                    self.bindButton.enabled = YES;
                    [self.bindButton setTitle:@"Unbind" forState:UIControlStateNormal];
                });
            }
        }
        NSLog(@" nodeId: %llu", devId);
        
        NSString *deviceType = [NSString stringWithFormat:@"%@",[allDeviceListTemp[index] valueForKey:@"deviceType"]];
        
        if ([deviceType isEqualToString: DimmingLight] || [deviceType isEqualToString: EnhancedColorLight] || [deviceType isEqualToString: OnOffLight] || [deviceType isEqualToString: TemperatureColorLight]) {
            //if ([connectedDevice isEqual:@"1"]){
                [allLightDeviceList addObject:allDeviceListTemp[index]];
            //}
        }
    }
    
    if (allLightDeviceList.count == 0) {
        self.noDeviceFoundView.hidden = false;
        self.bindLightSwitchView.hidden = true;
    } else {
        [self.tableView reloadData];
        self.noDeviceFoundView.hidden = true;
        self.bindLightSwitchView.hidden = false;
    }
}

//MARK: Bind function

- (void) bindDevice {
    NSLog(@"Bind device fuctionality");
    NSLog(@" Switch Node ID %@", nodeId);
    NSLog(@"Switch end point %@", endPoint);
    NSLog(@"Light node ID %@", lightNodeId);

    [self bindAfterACLWrite:lightNodeId nodeIdOFSwitch:nodeId];
}

//MARK: IBAction

- (IBAction)bindButtonAction:(id)sender {
    if (isBind == true) {
        [SVProgressHUD showWithStatus: @"Unbind is under process..."];
        int nodeIdBind = [nodeId intValue];
        NSUInteger indexNumber = [allDeviceListTemp indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
            BOOL found = [[item objectForKey:@"nodeId"] intValue] == nodeIdBind;
            return found;
        }];
        NSLog(@"%@", [allDeviceListTemp[indexNumber] valueForKey:@"connectedToNodeId"]);
        NSNumber *lightNodeId = [allDeviceListTemp[indexNumber] valueForKey:@"connectedToNodeId"];
        bindedDevice = [[NSMutableArray alloc] init];
        [bindedDevice addObject:nodeId];
        [bindedDevice addObject:lightNodeId];

        [self unBindNode];
    }else{
        [SVProgressHUD showWithStatus: @"Binding is under process..."];
        [self bindDevice];
    }
}

- (void) updateBindInfo:(BOOL) isSelected bindStatus:(BOOL)bindStatus{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    if (bindStatus == true) {
        self.bindButton.backgroundColor = UIColor.sil_siliconLabsRedColor;
        self.bindButton.enabled = YES;
        [self.bindButton setTitle:@"Unbind" forState:UIControlStateNormal];
    }else{
        if (isSelected == true) {
            self.bindButton.backgroundColor = UIColor.sil_regularBlueColor;
            self.bindButton.enabled = YES;
            [self.bindButton setTitle:@"Bind" forState:UIControlStateNormal];
        } else {
            self.bindButton.backgroundColor = UIColor.sil_boulderColor;
            self.bindButton.enabled = NO;
            [self.bindButton setTitle:@"Bind" forState:UIControlStateNormal];
        }
    }
    [self.bindButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return allLightDeviceList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SILLightSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SILLightSwitchTableViewCell" forIndexPath:indexPath];
    
    cell.deviceNameLabel.text = self.data[indexPath.row];
    NSDictionary * deviceDict = allLightDeviceList[indexPath.row];
    [self.tableView setTintColor:[UIColor blueColor]];
    if (self.selectedIndexPaths == nil){
        if ([[deviceDict valueForKey:@"isBinded"] isEqual:@"true"]) {
            cell.tickMarkImage.hidden = false;
        }else{
            cell.tickMarkImage.hidden = true;
        }
    }else{
        if ([indexPath isEqual:self.selectedIndexPaths]) {
            cell.tickMarkImage.hidden = false;
        } else {
            cell.tickMarkImage.hidden = true;
        }
    }
    [cell setupCell:deviceDict];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary * deviceDict = allLightDeviceList[indexPath.row];
    
//    if ([indexPath isEqual:self.selectedIndexPaths]) {
//        self.selectedIndexPaths = nil;
//        NSLog(@"De Selected Cell: %@", deviceDict);
//        [self updateBindInfo:false bindStatus:false];
//    } else {
        self.selectedIndexPaths = indexPath;
        NSLog(@"Selected Cell: %@", deviceDict);
        lightNodeId = [deviceDict valueForKey:@"nodeId"];
        lightNodeType = [deviceDict valueForKey:@"deviceType"];
        lightNodeName = [deviceDict valueForKey:@"title"];
    if ([[deviceDict valueForKey:@"isBinded"] isEqual:@"true"]) {
        [self updateBindInfo:true bindStatus:true];
    }else{
        [self updateBindInfo:true bindStatus:false];
    }
        
    //}
    [tableView reloadData];
}

#pragma  mark - Private function
- (void)bindAfterACLWrite:(NSNumber *)nodeIdOFLight nodeIdOFSwitch:(NSNumber *)nodeIdOFSwitch {
    
    bindedDevice = [[NSMutableArray alloc] init];
    [bindedDevice addObject:nodeIdOFSwitch];
    [bindedDevice addObject:nodeIdOFLight];
    
    NSNumber *nodeIdSwitch = nodeIdOFSwitch;
    NSNumber *nodeIdLight = nodeIdOFLight;
   // NSNumber *subjects = @112233;
    uint64_t lightNodeId = nodeIdLight.intValue;

    NSLog(@"deviceId %llu", lightNodeId);
    NSLog(@"%@", [MTRBaseDevice deviceWithNodeID:nodeIdLight controller:controller]);
    MTRBaseDevice * _Nullable chipDevice = [MTRBaseDevice deviceWithNodeID:nodeIdLight controller:controller];
   // if (MTRGetConnectedDeviceWithID(nodeIdLight, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            //NSLog(@"chipDevice %@", [chipDevice accessibilityAttributedValue]);
            MTRBaseClusterAccessControl  *mTRBaseClusterAccessControl = [[MTRBaseClusterAccessControl alloc] initWithDevice:chipDevice endpointID:@0 queue: dispatch_get_main_queue()];
            
         [mTRBaseClusterAccessControl readAttributeACLWithParams:nil completion:^(NSArray * _Nullable value, NSError * _Nullable error){
                if (error) {
                    NSLog(@"%@", error);
                    [self dismissProgressView];
                    [self showAlertPopup:@"Failed to read Attribute ACL of the device."];

                }else{
                    if (value.count > 0) {
                        MTRAccessControlClusterAccessControlEntryStruct *entryStruc = value[0];
                        //NSLog(@"%@",entryStruc);
                        //NSLog(@"+++++++++++++++++++++++++++++++++++++++++++++++++++++");
                        //NSLog(@"%@",entryStruc.subjects[0]);
                        NSNumber *lightNodeSubject = entryStruc.subjects[0];
                        MTRAccessControlClusterAccessControlEntryStruct *Entstr = [[MTRAccessControlClusterAccessControlEntryStruct alloc] init];
                        Entstr.fabricIndex = @1;
                        Entstr.privilege = @5;
                        Entstr.authMode = @2;
                        Entstr.subjects = @[lightNodeSubject];
                        Entstr.targets = @[];
                        
                        NSMutableArray * aclWriteParamArry = [[NSMutableArray alloc] init];
                        [aclWriteParamArry addObject:Entstr];
                        MTRAccessControlClusterAccessControlEntryStruct *Entstr2 = [[MTRAccessControlClusterAccessControlEntryStruct alloc] init];
                        Entstr2.fabricIndex = @1;
                        Entstr2.privilege = @3;
                        Entstr2.authMode = @2;
                        Entstr2.subjects = @[nodeIdSwitch];
                        Entstr2.targets = @[];
                        
                        [aclWriteParamArry addObject:Entstr2];
                        uint64_t swdeviceId = nodeIdSwitch.intValue;
                        NSLog(@"%@", aclWriteParamArry);
                        [self bindOneToOne:chipDevice MTRBaseClusterAccessControlObjc:mTRBaseClusterAccessControl controlEntryParam:aclWriteParamArry switchNodeId:nodeIdSwitch lightNodeId:nodeIdLight];
                        
                    }
                }
            }];
            
            
        } else {
                    NSLog(@"Failed to establish a connection with the device.");
                    [self dismissProgressView];
                    [self showAlertPopup:@"Failed to establish a connection with the device."];
                }

//            })) {
//                NSLog(@"Waiting for connection with the device.");
//        } else {
//            NSLog(@"Failed to trigger the connection with the light device.");
//            [self showAlertPopup:@"Failed to establish a connection with the device."];
//            [self dismissProgressView];
//        }

}


- (void)updateDeviceArray:(NSString *)type{
    NSMutableArray *allDevice = [[NSMutableArray alloc]init];
    allDevice = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    NSLog(@"%@", allDevice);

    for (int j = 0; j < [bindedDevice count]; j++){
        int nodeIdBind = [bindedDevice[j] intValue];
        NSUInteger indexNumber = [allDevice indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
            BOOL found = [[item objectForKey:@"nodeId"] intValue] == nodeIdBind;
            return found;
        }];
        NSLog(@"%@", [allDevice[indexNumber] valueForKey:@"deviceType"]);
        NSString *deviceTypeStr = [NSString stringWithFormat:@"%@", [allDevice[indexNumber] valueForKey:@"deviceType"]];

        NSString *bind = @"";
        if (isBind) {
            bind = @"true";
        }else{
            bind = @"false";
        }
        if ([type  isEqual: @"unbind"]) {
            if ([deviceTypeStr isEqualToString: DimmingLight] || [deviceTypeStr isEqualToString: EnhancedColorLight] || [deviceTypeStr isEqualToString: OnOffLight] || [deviceTypeStr isEqualToString: TemperatureColorLight]) {
                [self saveTheDictionary:allDevice[indexNumber] indexNumber:indexNumber connectedToDeviceType:@"" connectedToDeviceName:@"" isBinded:bind connectedToNodeId:@""];
            }else if ([deviceTypeStr isEqualToString:@"259"] || [deviceTypeStr isEqualToString:DimmerSwitch]){
                [self saveTheDictionary:allDevice[indexNumber] indexNumber:indexNumber connectedToDeviceType:@"" connectedToDeviceName:@"" isBinded:bind connectedToNodeId:@""];

            }

        }else{
            if ([deviceTypeStr isEqualToString: DimmingLight] || [deviceTypeStr isEqualToString: EnhancedColorLight] || [deviceTypeStr isEqualToString: OnOffLight] || [deviceTypeStr isEqualToString: TemperatureColorLight]) {
                [self saveTheDictionary:allDevice[indexNumber] indexNumber:indexNumber connectedToDeviceType:deviceType connectedToDeviceName:deviceName isBinded:bind connectedToNodeId:[NSString stringWithFormat:@"%@", nodeId]];
            }else if ([deviceTypeStr isEqualToString:@"259"] || [deviceTypeStr isEqualToString:DimmerSwitch]){
                [self saveTheDictionary:allDevice[indexNumber] indexNumber:indexNumber connectedToDeviceType:lightNodeType connectedToDeviceName:lightNodeName isBinded:bind connectedToNodeId:[NSString stringWithFormat:@"%@", lightNodeId]];

            }

        }
        //NSString *deviceTypeStr = [allDevice[indexNumber] valueForKey:@"deviceType"];
     
//        if ([deviceTypeStr isEqualToString: DimmingLight] || [deviceTypeStr isEqualToString: EnhancedColorLight] || [deviceTypeStr isEqualToString: OnOffLight] || [deviceTypeStr isEqualToString: TemperatureColorLight]) {
//            [self saveTheDictionary:allDevice[indexNumber] indexNumber:indexNumber connectedToDeviceType:deviceType connectedToDeviceName:deviceName isBinded:bind connectedToNodeId:[NSString stringWithFormat:@"%@", nodeId]];
//        }else if ([deviceTypeStr isEqualToString:@"259"] || [deviceTypeStr isEqualToString:DimmerSwitch]){
//            [self saveTheDictionary:allDevice[indexNumber] indexNumber:indexNumber connectedToDeviceType:lightNodeType connectedToDeviceName:lightNodeName isBinded:bind connectedToNodeId:[NSString stringWithFormat:@"%@", lightNodeId]];
//
//        }

    }


}
-(void)saveTheDictionary: (NSMutableDictionary *)saveDic indexNumber:(NSUInteger)indexOfArray connectedToDeviceType: (NSString *) connectedToDeviceType  connectedToDeviceName:(NSString *) connectedToDeviceName isBinded: (NSString *)isBinded connectedToNodeId: (NSString *) connectedToNodeId{
    
    NSLog(@"%@", saveDic);
    NSNumber *nodeId = [saveDic valueForKey:@"nodeId"];
    NSString *deviceType = [saveDic valueForKey:@"deviceType"];
    NSNumber *endPoint = [saveDic valueForKey:@"endPoint"];
    NSString *connected = [saveDic valueForKey:@"isConnected"];
    
    NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
    [deviceDic setObject:deviceType forKey:@"deviceType"];
    [deviceDic setObject:nodeId forKey:@"nodeId"];
    [deviceDic setObject:endPoint forKey:@"endPoint"];
    [deviceDic setObject:connected forKey:@"isConnected"];
    [deviceDic setObject:[allDeviceListTemp[indexOfArray] valueForKey:@"title"] forKey:@"title"];
    [deviceDic setObject:isBinded forKey:@"isBinded"];
    [deviceDic setObject:connectedToDeviceType forKey:@"connectedToDeviceType"];
    [deviceDic setObject:connectedToDeviceName forKey:@"connectedToDeviceName"];
    [deviceDic setObject:connectedToNodeId forKey:@"connectedToNodeId"];
    [allDeviceListTemp replaceObjectAtIndex:indexOfArray withObject:deviceDic];
    NSLog(@"%@", deviceDic);
    
    [[NSUserDefaults standardUserDefaults] setObject:allDeviceListTemp forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissProgressView];
}

-(void)dismissProgressView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

-(void) showAlertPopup:(NSString *) message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}


-(void)bindOneToOne:(MTRBaseDevice *) device MTRBaseClusterAccessControlObjc:(MTRBaseClusterAccessControl *)mtrBaseClusterAccessControl controlEntryParam:(NSMutableArray *)controlEntryParams switchNodeId:(NSNumber *) switchNodeId lightNodeId:(NSNumber *)lightNodeId{
        //NSLog(@"chipDevice %@", [device accessibilityAttributedValue]);
            [mtrBaseClusterAccessControl writeAttributeACLWithValue:controlEntryParams completion:^(NSError * _Nullable error) {
                NSLog(@"%@", error);
                
                if (error == nil) {
                   // [self bindFunc:nodeIdSwitch];
                    uint64_t swdeviceId = switchNodeId.intValue;
                    NSLog(@"swdeviceId %llu", switchNodeId);
                    MTRBaseDevice * _Nullable device = [MTRBaseDevice deviceWithNodeID:switchNodeId controller:controller];
                   //if (MTRGetConnectedDeviceWithID(swdeviceId, ^(MTRBaseDevice * _Nullable device, NSError * _Nullable error) {
                        if(device) {
                            MTRBaseClusterBinding *bnd = [[MTRBaseClusterBinding alloc] initWithDevice:device endpoint:1 queue:dispatch_get_main_queue()];
                            
                            MTRBindingClusterTargetStruct *bndStr = [[MTRBindingClusterTargetStruct alloc] init];
                            NSLog(@"nodeIdLight: %@", lightNodeId);
                            bndStr.node = lightNodeId;
                            //bndStr.group = @0;
                            bndStr.endpoint = @1;
                            bndStr.cluster = @6;
                            bndStr.fabricIndex = @1;
                            NSLog(@"%@", bndStr);
                            
                            [bnd writeAttributeBindingWithValue:@[bndStr] completionHandler:^(NSError * _Nullable error) {
                                NSLog(@"bind: %@", error);
                                if (error == nil) {
                                    [self getSwitchBindValue];
                                    isBind = true;
                                    [self updateDeviceArray:@""];
                                    [self updateBindInfo:true bindStatus:true];
                                    
                                }else{
                                    //[self.toste];
                                    [self updateDeviceArray:@"unbind"];
                                    [self updateBindInfo:true bindStatus:false];
                                    [self showAlertPopup:@"Failed in Binding."];
                                    [self dismissProgressView];
                                }
                            }];
                        }else{
                            NSLog(@"Failed to establish a connection with switch in network...");
                            [self updateDeviceArray:@"unbind"];
                            [self updateBindInfo:true bindStatus:false];

                            [self showAlertPopup:@"Failed to establish a connection with switch in network."];
                            [self dismissProgressView];
                        }
                        
//                    })){
//                        NSLog(@"Waiting for connection with the device.");
//                    }else {
//                        NSLog(@"Failed to trigger the connection with the switch device.");
//                        [self updateDeviceArray:@"unbind"];
//                        [self updateBindInfo:true bindStatus:false];
//                        [self showAlertPopup:@"Failed to trigger the connection with the switch device."];
//                        [self dismissProgressView];
//                    }
              
                }else{
                    NSLog(@"Failed in ACL write....");
                    [self updateDeviceArray:@"unbind"];
                    [self updateBindInfo:true bindStatus:false];
                    [self showAlertPopup:@"Failed in ACL write...."];
                    [self dismissProgressView];
                }
            }];
        
}

-(void)unBindNode{
    
    NSNumber *nodeIdSwitch = nodeId;
    uint64_t swdeviceId = nodeIdSwitch.intValue;
    NSLog(@"%@", [MTRBaseDevice deviceWithNodeID:nodeIdSwitch controller:controller]);
    MTRBaseDevice * _Nullable device = [MTRBaseDevice deviceWithNodeID:nodeIdSwitch controller:controller];
    
    //if (MTRGetConnectedDeviceWithID(swdeviceId, ^(MTRBaseDevice * _Nullable device, NSError * _Nullable error) {
        if(device) {
            
            MTRBaseClusterBinding *bnd = [[MTRBaseClusterBinding alloc] initWithDevice:device endpoint:1 queue:dispatch_get_main_queue()];
            MTRReadParams *pr=[[MTRReadParams alloc] init];
            //pr.fabricFiltered = @1;

//            [bnd readAttributeBindingWithParams:pr completion:^(NSArray * _Nullable value, NSError * _Nullable error) {
//                NSLog(@"bind: %@", error);
//                if (error) {
//                    
//                }else{
//                    NSLog(@"bind value: %@", value);
//                }
//            }];

            [bnd writeAttributeBindingWithValue:@[] completionHandler:^(NSError * _Nullable error) {
                NSLog(@"bind: %@", error);
                if (error) {
                    //[self UpdateAfterUnbindNode];
                    [self showAlertPopup:@"Failed to unbind."];
                    [self dismissProgressView];
                }else{
                    [self UpdateAfterUnbindNode];
                }

            }];

           

        }else{
            NSLog(@"Failed to establish a connection with switch in network...");
            //[self UpdateAfterUnbindNode];
            [self showAlertPopup:@"Failed to establish a connection with switch in network."];
            [self dismissProgressView];
        }
        
//    })){
//        NSLog(@"Waiting for connection with the device.");
//    }else {
//        NSLog(@"Failed to trigger the connection with the switch device.");
//        [self showAlertPopup:@"Failed to trigger the connection with the switch device."];
//        [self dismissProgressView];
//    }
    
}

-(void)UpdateAfterUnbindNode {
    dispatch_async(dispatch_get_main_queue(), ^{
        isBind = false;
        [self updateBindInfo:false bindStatus:false];
        //@"unbind"
       // [self updateDeviceArray];
        [self updateDeviceArray:@"unbind"];
        self.selectedIndexPaths = nil;
        allDeviceListTemp = [[NSMutableArray alloc] init];
        allDeviceListTemp = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
        [self getDeviceType: allDeviceListTemp];
    });

}
@end
