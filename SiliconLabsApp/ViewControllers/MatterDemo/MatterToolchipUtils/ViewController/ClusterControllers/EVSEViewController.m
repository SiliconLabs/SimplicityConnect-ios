//
//  EVSEViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 21/08/25.
//  Copyright © 2025 SiliconLabs. All rights reserved.
//

#import "EVSEViewController.h"
#import "CircularProgressView.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import "MatterHomeViewController.h"

typedef NS_ENUM(NSInteger, EVSEChargingState) {
    EVSEChargingStateNotPluggedIn = 0,
    EVSEChargingStatePluggedInNoDemand = 1,
    EVSEChargingStatePluggedInDemand = 2,
    EVSEChargingStatePluggedInCharging = 3,
    EVSEChargingStatePluggedInDischarging = 4,
    EVSEChargingStateSessionEnding = 5,
    EVSEChargingStateFault = 6
};

@interface EVSEViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat currentProgress;

@end

@implementation EVSEViewController
@synthesize  nodeId, endPoint;
NSMutableArray * deviceListEVSE;

- (void)viewDidLoad {
    [super viewDidLoad];
    deviceListEVSE = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    self.parsedModes = @[];
    self.modeLabels = @[];
    self.circularProgressView.progress = 0.0;
    
    [self updateLoaderWithPercent:@0 animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self readOnlineOfflineStatus];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self readEVSECurrentStatus];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    NSDictionary* userInfo = @{@"controller": @"EVSEViewController"};
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"controllerNotification"
     object:self userInfo:userInfo];
}

// MARK: - Progress / State of Charge Display
// Public convenience to update progress with a percentage value (0 - 100)
- (void)updateLoaderWithPercent:(NSNumber *)percent animated:(BOOL)animated {
    if (!percent || percent == (id)kCFNull) { return; }
    CGFloat pct = percent.floatValue;
    if (isnan(pct)) { return; }
    // Clamp 0..100
    pct = fmax(0.0, fmin(100.0, pct));
    self.currentProgress = pct; // store raw percentage
    CGFloat normalized = pct / 100.0f; // circularProgressView expects 0..1
    dispatch_async(dispatch_get_main_queue(), ^{
        if (animated) {
            [UIView animateWithDuration:0.85 animations:^{
                self.circularProgressView.progress = normalized;
            }];
        } else {
            self.circularProgressView.progress = normalized;
        }
    });
}

- (void) readEVSECurrentStatus {
    uint64_t _devId = nodeId.intValue;
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            MTRBaseClusterEnergyEVSE * descriptorCluster = [[MTRBaseClusterEnergyEVSE alloc] initWithDevice:chipDevice
                                                                                                 endpointID:@1 queue:dispatch_get_main_queue()];
            [descriptorCluster readAttributeVehicleIDWithCompletion:^(NSString * _Nullable value, NSError * _Nullable error) {
                if (error) { NSLog(@"Error"); }
                NSLog(@" Vehicle ID=== %@", value);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.vehicleIDLabel.text = value;
                });
            }];
            
//            MTRSubscribeParams *parm1 = [[MTRSubscribeParams alloc] init];
//            parm1.minInterval = @0;
//            parm1.maxInterval = @1000;
//            [descriptorCluster subscribeAttributeStateOfChargeWithParams: parm1 subscriptionEstablished:^{
//                // Subscription established
//            } reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
//                if (error) { NSLog(@"Error"); return; }
//                NSLog(@" subscribe State Of Charge=== %@", value);
//                [self updateLoaderWithPercent:value animated:YES];
//            }];
            
            // Read EVSE connection status:
            [descriptorCluster readAttributeStateWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                if (error) { NSLog(@"Error reading State: %@", error); }
                
                NSLog(@"EV Charging State=== %@", value);
                
                NSString *statusText = [self displayStringForEVSEStateNumber:value];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.evConnectionStatusLabel.text = statusText;
                });
            }];
            
//            MTREnergyEVSEClusterEnableChargingParams *parm = [[MTREnergyEVSEClusterEnableChargingParams alloc] init];
//            
//            parm.minimumChargeCurrent = @0;
//            parm.maximumChargeCurrent = @100;
//            parm.timedInvokeTimeoutMs = @2;
//            
//            [descriptorCluster enableChargingWithParams: parm completion:^(NSError * _Nullable error) {
//                // readAttributeSupportedModesWithCompletion
//                NSLog(@"Enable Charging value===");
//            }];
//            
//            [descriptorCluster readAttributeChargingEnabledUntilWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
//                NSLog(@" Charging Enabled Until=== %@", value); // null
//            }];
            
            // Read EVSE Supported Mode
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self readEVSESupportedMode];
            });
            
        } else {
            //[self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        //[self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        //[self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

- (void) readEVChargeStatus {
    uint64_t _devId = nodeId.intValue;
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        
        [SVProgressHUD showWithStatus: @"Loading EV charge Status..."];

        if (chipDevice) {
            MTRBaseClusterEnergyEVSE * descriptorCluster = [[MTRBaseClusterEnergyEVSE alloc] initWithDevice:chipDevice
                                                                                                 endpointID:@1 queue:dispatch_get_main_queue()];
            
            
            MTRSubscribeParams *parm1 = [[MTRSubscribeParams alloc] init];
            parm1.minInterval = @0;
            parm1.maxInterval = @1000;
            [descriptorCluster subscribeAttributeStateOfChargeWithParams: parm1 subscriptionEstablished:^{
                // Subscription established
            } reportHandler:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                if (error) { NSLog(@"Error"); return; }
                NSLog(@"Subscribe State Of Charge=== %@", value);
                [self updateLoaderWithPercent:value animated:YES];
                
                [SVProgressHUD dismiss];
                
                // time to charge
                
            }];
        } else {
            //[self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        //[self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        //[self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

- (NSString *)displayStringForEVSEStateNumber:(NSNumber *)stateNumber {
    if (!stateNumber) { return @"Unknown"; }
    switch (stateNumber.integerValue) {
        case EVSEChargingStateNotPluggedIn: return @"Not Plugged In";
        case EVSEChargingStatePluggedInNoDemand: return @"Plugged (No Demand)";
        case EVSEChargingStatePluggedInDemand: return @"Plugged (Demand)";
        case EVSEChargingStatePluggedInCharging: return @"Charging";
        case EVSEChargingStatePluggedInDischarging: return @"Discharging";
        case EVSEChargingStateSessionEnding: return @"Session Ending";
        case EVSEChargingStateFault: return @"Fault";
        default:
            return [NSString stringWithFormat:@"Unknown (%@)", stateNumber];
    }
}

// MARK: - Read EVSE Support Mode

- (void)readEVSESupportedMode {
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            [SVProgressHUD showWithStatus: @"Loading..."];
            
            //EnergyEVSEMode
            MTRBaseClusterEnergyEVSEMode * modeCluster = [[MTRBaseClusterEnergyEVSEMode alloc] initWithDevice:chipDevice
                                                                                                   endpointID:@1 queue:dispatch_get_main_queue()];
            
            [modeCluster readAttributeSupportedModesWithCompletion:^(NSArray * _Nullable value, NSError * _Nullable error) {
               
                [SVProgressHUD dismiss];
                if (error || value.count == 0) {
                    NSLog(@"Failed to read supported modes: %@", error);
                    return;
                }
                self.supportedModeStructs = value;
                NSLog(@"Suppoted modes: %@", value);
                self.supportedModes = value;

                NSMutableArray<NSDictionary *> *parsed = [NSMutableArray array];
                NSMutableArray<NSString *> *labels = [NSMutableArray array];
                
                for (MTREnergyEVSEModeClusterModeOptionStruct *opt in value) {
                    NSString *label = opt.label ?: @"";
                    NSNumber *modeNum = opt.mode ?: @0;
                    NSMutableArray *tagValues = [NSMutableArray array];
                    for (MTREnergyEVSEModeClusterModeTagStruct *tagStruct in opt.modeTags) {
                        if (tagStruct.value) {
                            [tagValues addObject:tagStruct.value];
                        }
                    }
                    [parsed addObject:@{ @"label": label, @"mode": modeNum, @"tags": tagValues }];
                    [labels addObject:label];
                }
               
                self.parsedModes = parsed;
                self.modeLabels = labels;
                if (!self.selectedMode && self.modeLabels.count > 0) {
                    self.selectedMode = self.modeLabels.firstObject;
                }
                NSLog(@"modes: %@", self.parsedModes);
                [self readCurrentEVSEMode];
            }];
        } else {
            //[self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        //[self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        //[self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

- (void) readCurrentEVSEMode {
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            [SVProgressHUD showWithStatus: @"Changing Mode..."];
            
            MTRBaseClusterEnergyEVSEMode * modeCluster = [[MTRBaseClusterEnergyEVSEMode alloc] initWithDevice:chipDevice
                                                                                                   endpointID:@1 queue:dispatch_get_main_queue()];
                        
            // Show Updated mode
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [modeCluster readAttributeCurrentModeWithCompletion:^(NSNumber * _Nullable value, NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"CurrentMode read error: %@", error);
                        return;
                    }
                    NSString *modeName = [EVSEModeUtils modeNameForModeValue: value
                                                           fromSupportedModes:self.supportedModes];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"After changed mode value === %@", modeName);
                        // Update button title
                        [self.modeButton setTitle: modeName forState:UIControlStateNormal];
                        // Persist current selection so picker preselects correct row next time
                        if (modeName.length > 0) {
                            self.selectedMode = modeName;
                        }
                        if (value) {
                            self.selectedModeId = value; // store current numeric mode
                        }
                        [SVProgressHUD dismiss];
                        
                        // Read EV Charge Status
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self readEVChargeStatus];
                        });
                    });
                }];
            });
        } else {
            //[self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        //[self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        //[self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

// MARK: - Change EVSE Mode

- (void) changeEVSEMode:(NSNumber *)modeId {
    uint64_t _devId = nodeId.intValue;
    
    [SVProgressHUD showWithStatus: @"Loading Mode..."];

    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            MTRBaseClusterEnergyEVSEMode * modeCluster = [[MTRBaseClusterEnergyEVSEMode alloc] initWithDevice:chipDevice
                                                                                                   endpointID:@1 queue:dispatch_get_main_queue()];
            
            MTREnergyEVSEModeClusterChangeToModeParams *parm1 = [[MTREnergyEVSEModeClusterChangeToModeParams alloc]init];
            parm1.newMode = modeId;
            
            [modeCluster changeToModeWithParams: parm1 completion:^(MTREnergyEVSEModeClusterChangeToModeResponseParams * _Nullable data, NSError * _Nullable error) {
                
                if (error) {
                    NSLog(@"CurrentMode read error: %@", error);
                    //[self showAlertInfoPopup:@"Failed to establish a connection with the device. Please reset the board and try again."];
                   // [SVProgressHUD dismiss];
                    [self setDeviceStatus:@"0" nodeId:self->nodeId];
                    return;
                }
                
                NSLog(@"Changed mode status Value:===  %@", data.status); // 0
                NSLog(@"Changed mode statusText Value:===  %@", data.statusText); // null
                [SVProgressHUD dismiss];
                [self readCurrentEVSEMode];
            }];
            
        } else {
            //[self showAlertInfoPopup:@"Failed to establish a connection with the device. Please reset the board and try again."];
            [self setDeviceStatus:@"0" nodeId:self->nodeId];
        }
    })) {
        //[self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        //[self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

// MARK: - readInitialDeviceStatus

- (void) readOnlineOfflineStatus {
    
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            MTRBaseClusterDescriptor * descriptorCluster =
            [[MTRBaseClusterDescriptor alloc] initWithDevice:chipDevice
                                                    endpoint:1
                                                       queue:dispatch_get_main_queue()];
            
            [descriptorCluster readAttributeDeviceListWithCompletionHandler:^(NSArray * _Nullable value, NSError * _Nullable error) {
                if (error) {
                    [self setDeviceStatus:@"0" nodeId:self->nodeId];
                    return;
                }
                [self setDeviceStatus:@"1" nodeId:self->nodeId];
            }];
        } else {
             [self setDeviceStatus:@"0" nodeId:self->nodeId];
        }
    })) {
    } else {
        // [self setDeviceStatus:@"0" nodeId:self->nodeId];
    }
}

- (void)selectModeTapped {
    if (self.modeLabels.count == 0) {
        [self showAlertPopup:@"Modes not loaded yet."];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Select Mode"
                                                                   message:@"\n\n\n\n\n\n"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIPickerView *picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 40, alert.view.bounds.size.width - 20, 140)];
    picker.dataSource = self;
    picker.delegate = self;
    
    NSInteger preIndex = 0;
    if (self.selectedMode) {
        
        NSLog(@"Selected Mode=== %@", self.selectedMode);
        NSLog(@"Parsed Modes=== %@", self.parsedModes);
        NSLog(@"Current Selected ModeID=== %@", self.currentSelectedModeID);
        
        NSInteger found = [self.modeLabels indexOfObject:self.selectedMode];
        if (found != NSNotFound) {
            preIndex = found;
        }
    }
    [picker selectRow:preIndex inComponent:0 animated:NO];
    [alert.view addSubview:picker];
    
    UIAlertAction *selectAction = [UIAlertAction actionWithTitle:@"Select" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Selected mode Name:=== %@", self.selectedMode);
        [self.modeButton setTitle:self.selectedMode forState:UIControlStateNormal];
        [self changeEVSEMode:self.selectedModeId];
        
    }];
    [alert addAction:selectAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)modeSelectionAction:(id)sender {
    [self selectModeTapped];
}

- (void)setDeviceStatus:(NSString *)connected nodeId:(NSNumber *)node_id {
    NSUInteger index2 = [deviceListEVSE indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];
    
    if([deviceListEVSE count] > 0) {
        
        NSNumber *nodeId = [deviceListEVSE[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [deviceListEVSE[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[deviceListEVSE[index2] valueForKey:@"title"] forKey:@"title"];
        
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @"false"] forKey:@"isBinded"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceType"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceName"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToNodeId"];
        
        [deviceListEVSE replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:deviceListEVSE forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:=== %@",deviceListEVSE);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity."];
    }
}

- (void) showAlertPopup:(NSString *) message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Go back to with payload and add device
            [self.navigationController popViewControllerAnimated: YES];
        });
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) showAlertInfoPopup:(NSString *) message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Go back to with payload and add device
        });
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UIPickerViewDataSource & Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.modeLabels.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.modeLabels[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedMode = self.modeLabels[row];
    NSDictionary *info = self.parsedModes[row];
    
    NSNumber *modeId = nil;
    id rawTags = info[@"tags"];
    
    if ([rawTags isKindOfClass:[NSNumber class]]) {
        modeId = (NSNumber *)rawTags;
    } else if ([rawTags isKindOfClass:[NSString class]]) {
        // Optional: convert numeric string
        NSString *s = (NSString *)rawTags;
        if (s.length) {
            NSNumberFormatter *fmt = [NSNumberFormatter new];
            fmt.numberStyle = NSNumberFormatterDecimalStyle;
            modeId = [fmt numberFromString:s];
        }
    } else if ([rawTags isKindOfClass:[NSArray class]]) {
        // Take the first NSNumber inside the array
        for (id item in (NSArray *)rawTags) {
            if ([item isKindOfClass:[NSNumber class]]) {
                modeId = (NSNumber *)item;
                break;
            }
        }
    } else if ([rawTags isKindOfClass:[NSDictionary class]]) {
        // If dictionary holds an NSNumber under a known key
        id possible = ((NSDictionary *)rawTags)[@"id"];
        if ([possible isKindOfClass:[NSNumber class]]) {
            modeId = (NSNumber *)possible;
        }
    }
    //self.selectedModeId = modeId;
    //NSLog(@"===%@", self.selectedModeId);
    NSLog(@"Selected mode=== %@ (id=%@) tags=%@", info[@"label"], info[@"mode"], info[@"tags"]);
    NSLog(@"mode id ===%@", [self currentSelectedModeID]);
    
    self.selectedModeId = [self currentSelectedModeID];
}

// Helper to get mode ID
- (NSNumber *)currentSelectedModeID {
    NSInteger idx = [self.modeLabels indexOfObject:self.selectedMode];
    if (idx != NSNotFound && idx < self.supportedModeStructs.count) {
        return self.supportedModeStructs[idx].mode;
    }
    return nil;
}

@end
