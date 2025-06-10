//
//  DishwasherViewController.m
//  BlueGecko
//
//  Created by Mantosh Kumar on 26/09/24.
//  Copyright © 2024 SiliconLabs. All rights reserved.
//

#import "DishwasherViewController.h"
#import "CHIPUIViewUtils.h"
#import "DefaultsUtils.h"
#import "DeviceSelector.h"
#import <Matter/Matter.h>
#import "MatterHomeViewController.h"

@interface DishwasherViewController ()

@end

@implementation DishwasherViewController
@synthesize  nodeId, endPoint;
NSMutableArray * dishwasherDeviceList;

float previousTotalEnergyValue = 0.0;
float inTotalEnergyValue = 0.0;
float currentCycleEnergyValue = 0.0;
float averageEnergyValue = 0.0;
int cycleCount = 0.0;
float initialTotalEnergyValue = 0.0;

bool isFirstCycle = true;
bool isBackButtonFlow = false;

// MARK: Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    dishwasherDeviceList = [[NSMutableArray alloc] init];
    dishwasherDeviceList = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"saved_list"]];
    _totalWashTimeLabel.text = @"10 min";
    _dishwasherCurrentState = @"stop";
    
    isBackButtonFlow = [[NSUserDefaults standardUserDefaults] boolForKey:@"isBackButtonFlow"];
    NSLog(@" isBackButtonFlow: %@", isBackButtonFlow ? @"YES" : @"NO");
    
    if (isBackButtonFlow) {
        [self setValueFromStroedDiswasherStatus];
    } else {
        self.timeLeft = 600; // 10 minutes in seconds
        self.progressBar.progress = 0;
        [self updateUI];
        self.isPaused = NO;
        isFirstCycle = true;
        cycleCount = -1;
        currentCycleEnergyValue = 0.0;
        [self stopDishwasher];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupUIElements];
    [self readDWCurrentStatus];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSDictionary* userInfo = @{@"controller": @"DishwasherViewController"};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"controllerNotification" object:self userInfo:userInfo];
    [self stopGettingDishwasherEMData];
}

// MARK: UI Setup

- (void)setupUIElements {
    _startButton.layer.cornerRadius = 10;
    _startButton.clipsToBounds = YES;
    
    _stopButton.layer.cornerRadius = 10;
    _stopButton.clipsToBounds = YES;
    
    _pauseResumeButton.layer.cornerRadius = 10;
    _pauseResumeButton.clipsToBounds = YES;
    
    _energyView.layer.cornerRadius = 10;
    _energyView.clipsToBounds = YES;
    
    _powerImage.layer.cornerRadius = 4;
    _powerImage.clipsToBounds = YES;
    _powerImage.layer.borderWidth = 1.5;
    _powerImage.layer.borderColor = UIColor.sil_regularBlueColor.CGColor;
    
    [self customBackButton];
}

- (void) customBackButton {
    // Create a custom back button
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"BackIcon"] forState:UIControlStateNormal];
    //    [backButton setTitle:@"Dishwasher" forState: UIControlStateNormal];
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; // Adjust color as needed
    backButton.titleLabel.font = [UIFont systemFontOfSize:16];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -50, 0, 0); // Moves the image left
    backButton.frame = CGRectMake(0, 0, 80, 30);
    
    // Add target action for the button
    [backButton addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    // Wrap the button in a UIBarButtonItem
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backBarButtonItem;
}

// MARK: UIButton actions

- (IBAction)dishwasherStartAction:(id)sender {
    [self startDishwasher];
    [self startButtonTappedFunction];
}

- (IBAction)dishwasherPauseAction:(id)sender {
    if (self.isPaused == YES) {
        [self resumeDishwasher];
    } else {
        [self pauseDishwasher];
    }
}

- (IBAction)dishwasherStopAction:(id)sender {
    [self stopDishwasher];
    [self stopButtonTappedFunction];
}

// MARK: local methods

- (void) backButtonTapped {
    
    if ([_dishwasherCurrentState isEqual: @"start"] || [_dishwasherCurrentState isEqual: @"resume"]) {
        [self showPopupToPauseStatus];
    } else {
        [self saveDishwasherStatus];
    }
}

- (void)updateResult:(NSString *)result {
    if([result isEqual: @"On"]) {
        self.dishwasherImage.image = [UIImage imageNamed:@"dishwasher"];
        self.currentStatusLabel.text = @"ON";
        self.dishwasherImage.tintColor = UIColor.sil_regularBlueColor;
    } else if ([result  isEqual: @"Off"]) {
        self.dishwasherImage.image = [UIImage imageNamed:@"dishwasher_pause"];
        self.currentStatusLabel.text = @"OFF";
        self.dishwasherImage.tintColor = UIColor.sil_boulderColor;
    }else if ([result  isEqual: @"Pause"]) {
        self.dishwasherImage.image = [UIImage imageNamed:@"dishwasher_pause"];
        self.currentStatusLabel.text = @"PAUSE";
        self.dishwasherImage.tintColor = UIColor.sil_regularBlueColor;
    } else {
        // Do nothing
    }
}

- (void) setValueFromStroedDiswasherStatus {
    
    NSDictionary *retrievedDishwaserDic = [[NSUserDefaults standardUserDefaults] objectForKey:@"dishwaserSavedStatus"];
    
    if (retrievedDishwaserDic) {
        NSLog(@"Retrieved Dishwaser Dic: %@", retrievedDishwaserDic);
        
        NSNumber *_previousTotalEnergyValue = retrievedDishwaserDic[@"previousTotalEnergyValue"];
        NSNumber *_inTotalEnergyValue = retrievedDishwaserDic[@"inTotalEnergyValue"];
        NSNumber *_currentCycleEnergyValue = retrievedDishwaserDic[@"currentCycleEnergyValue"];
        NSNumber *_averageEnergyValue = retrievedDishwaserDic[@"averageEnergyValue"];
        NSNumber *_cycleCount = retrievedDishwaserDic[@"cycleCount"];
        NSNumber *_timeLeft = retrievedDishwaserDic[@"timeLeft"];
        NSString *_dishwasherCurrentState = retrievedDishwaserDic[@"dishwasherCurrentState"];
        NSString *_initialTotalEnergyValue = retrievedDishwaserDic[@"initialTotalEnergyValue"];
        bool _isFirstCycle = retrievedDishwaserDic[@"isFirstCycle"];
        
        NSLog(@"_previousTotalEnergyValue:- %@",_previousTotalEnergyValue);
        NSLog(@"_inTotalEnergyValue:- %@",_inTotalEnergyValue);
        NSLog(@"_currentCycleEnergyValue:- %@",_currentCycleEnergyValue);
        NSLog(@"_averageEnergyValue:- %@",_averageEnergyValue);
        NSLog(@"_cycleCount:- %@",_cycleCount);
        NSLog(@"_timeLeft:- %@",_timeLeft);
        NSLog(@"_initialTotalEnergyValue:- %@",_initialTotalEnergyValue);
        
        // Need to update
        self.energyValueInTotalLabel.text = [NSString stringWithFormat:@"%.3f %s", [_inTotalEnergyValue floatValue], "kWh"];
        inTotalEnergyValue = [_inTotalEnergyValue floatValue];
        
        self.energyValueCurrentCycleLabel.text = [NSString stringWithFormat:@"%.3f %s", [_currentCycleEnergyValue floatValue], "kWh"];
        self.energyValueInAveragePerCycleLabel.text = [NSString stringWithFormat:@"%.3f %s", [_averageEnergyValue floatValue], "kWh"];
        
        self.completedCycleLabel.text = [NSString stringWithFormat:@"%d", [_cycleCount intValue]];
        cycleCount = [_cycleCount intValue];
        
        initialTotalEnergyValue = [_initialTotalEnergyValue floatValue];
        previousTotalEnergyValue = [_previousTotalEnergyValue floatValue];
        
        self.timeLeft = [_timeLeft integerValue];
        self.timerLabel.text = [self formatTime:self.timeLeft];
        self.progressBar.progress = (600 - self.timeLeft) / 600.0;
        
        if ([_dishwasherCurrentState isEqual: @"stop"]) {
            self.isPaused = NO;
            isFirstCycle = true;
            currentCycleEnergyValue = 0.0;
            [self updateUI];
            
        } else {
            [self pauseDishwasher];
            self.isPaused = YES;
            self.isRunning = NO;
            isFirstCycle = _isFirstCycle;
            [self readDishwaserEM];
            [self startGettingDishwasherEMData];
        }
        
    } else {
        NSLog(@"No dictionary found in NSUserDefaults");
    }
}

// MARK: Dishwasher Cluster

- (void) readDWCurrentStatus {
    NSInteger endpoint = 1;
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
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

// Start Dishwasher
- (void) startDishwasher {
    
    NSInteger endpointVal = 1;
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            if (@available(iOS 17.4, *)) {
                MTRBaseClusterOperationalState *operationalState = [[MTRBaseClusterOperationalState alloc] initWithDevice: chipDevice
                                                                                                               endpointID: @(endpointVal)
                                                                                                                    queue: dispatch_get_main_queue()];
                
                [operationalState startWithCompletion:^(MTROperationalStateClusterOperationalCommandResponseParams * _Nullable data, NSError * _Nullable error) {
                    NSString * resultString = (error != nil)
                    ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code] : @"On";
                    
                    [self updateResult:resultString];
                    [self readDishwaserEM];
                    [self startGettingDishwasherEMData];
                    self.dishwasherCurrentState = @"start";
                }];
                
            } else {
                NSLog(@" Error:-  %@", error);
            }
            
        } else {
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

// Pause Dishwasher
- (void) pauseDishwasher {
    
    NSInteger endpointVal = 1;
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            if (@available(iOS 16.4, *)) {
                
                MTRBaseClusterOperationalState *operationalState = [[MTRBaseClusterOperationalState alloc] initWithDevice: chipDevice
                                                                                                               endpointID: @(endpointVal)
                                                                                                                    queue: dispatch_get_main_queue()];
                
                [operationalState pauseWithCompletion:^(MTROperationalStateClusterOperationalCommandResponseParams * _Nullable data, NSError * _Nullable error) {
                    NSString * resultString = (error != nil)
                    ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code] : @"Pause";
                    [self updateResult:resultString];
                    [self pauseResumeButtonTappedFunction];
                    self.dishwasherCurrentState = @"pause";
                }];
            }
        } else {
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

// Resume Dishwasher
- (void) resumeDishwasher {
    
    NSInteger endpointVal = 1;
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            if (@available(iOS 17.4, *)) {
                MTRBaseClusterOperationalState *operationalState = [[MTRBaseClusterOperationalState alloc] initWithDevice: chipDevice
                                                                                                               endpointID: @(endpointVal)
                                                                                                                    queue: dispatch_get_main_queue()];
                
                [operationalState resumeWithCompletion:^(MTROperationalStateClusterOperationalCommandResponseParams * _Nullable data, NSError * _Nullable error) {
                    NSString * resultString = (error != nil)
                    ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code] : @"On";
                    [self updateResult:resultString];
                    [self pauseResumeButtonTappedFunction];
                    self.dishwasherCurrentState = @"resume";
                }];
                
            } else {
                NSLog(@" Error:-  %@", error);
            }
        } else {
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

// Stop Dishwasher
- (void) stopDishwasher {
    
    NSInteger endpointVal = 1;
    uint64_t _devId = nodeId.intValue;
    
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            if (@available(iOS 16.4, *)) {
                MTRBaseClusterOperationalState *operationalState = [[MTRBaseClusterOperationalState alloc] initWithDevice: chipDevice
                                                                                                               endpointID: @(endpointVal)
                                                                                                                    queue: dispatch_get_main_queue()];
                
                [operationalState stopWithCompletion:^(MTROperationalStateClusterOperationalCommandResponseParams * _Nullable data, NSError * _Nullable error) {
                    NSString * resultString = (error != nil)
                    ? [NSString stringWithFormat:@"An error occurred: 0x%02lx", error.code] : @"Off";
                    
                    cycleCount = cycleCount + 1;
                    self.completedCycleLabel.text = [NSString stringWithFormat:@"%d", cycleCount];
                    [self updateResult:resultString];
                    self.dishwasherCurrentState = @"stop";
                    [self readDishwaserEM];
                    [self stopGettingDishwasherEMData];
                    previousTotalEnergyValue = inTotalEnergyValue;
                }];
            }
        } else {
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

// Read Dishwasehr Energy Measurement
- (void) readDishwaserEM {
    NSInteger endpoint = 2;
    uint64_t _devId = nodeId.intValue;
    if (MTRGetConnectedDeviceWithID(_devId, ^(MTRBaseDevice * _Nullable chipDevice, NSError * _Nullable error) {
        if (chipDevice) {
            
            // Energy Measurement
            MTRBaseClusterElectricalEnergyMeasurement *em = [[MTRBaseClusterElectricalEnergyMeasurement alloc] initWithDevice:chipDevice endpointID:@(endpoint) queue:dispatch_get_main_queue()];
            
            [em readAttributeCumulativeEnergyImportedWithCompletion:^(MTRElectricalEnergyMeasurementClusterEnergyMeasurementStruct * _Nullable value, NSError * _Nullable error) {
                
                NSLog(@" Cumulative Energy Imported == %@", value.energy);
                
                if (value.energy != nil) {
                    float energyFloat = [value.energy floatValue];
                    
                    if (energyFloat == 0) {
                        inTotalEnergyValue = 0.00;
                        return;
                    } else {
                        // To convert mWh to kWh
                        inTotalEnergyValue = (energyFloat / (1000.0 * 1000.0));
                    }
                    
                    // Keep this logic for future referance
                    //--
                    //  NSLog(@"previousTotalEnergyValue: %.3f", previousTotalEnergyValue);
                    //  NSLog(@"inTotalEnergyValue: %.3f", inTotalEnergyValue);
                    
                    //  if (inTotalEnergyValue != previousTotalEnergyValue) {
                    //      inTotalEnergyValue = inTotalEnergyValue - previousTotalEnergyValue;
                    //}
                    //--
                    
                    // Total energy value calculation
                    self.energyValueInTotalLabel.text = [NSString stringWithFormat:@"%.3f %s", inTotalEnergyValue, "kWh"];
                    
                    // Current cycle value calculation
                    
                    if (initialTotalEnergyValue == 0.0) {
                        initialTotalEnergyValue = inTotalEnergyValue;
                    }
                    
                    if (cycleCount == 0) {
                        if (isFirstCycle == true) {
                            currentCycleEnergyValue = inTotalEnergyValue;
                        } else {
                            currentCycleEnergyValue = 0.0;
                        }
                        self.energyValueCurrentCycleLabel.text = [NSString stringWithFormat:@"%.3f %s", currentCycleEnergyValue, "kWh"];
                    } else {
                        
                        currentCycleEnergyValue = inTotalEnergyValue - initialTotalEnergyValue;
                        
                        if (isBackButtonFlow && [_dishwasherCurrentState isEqual: @"stop"] && currentCycleEnergyValue == 0.0 ) {
                            currentCycleEnergyValue = 0.0;
                        }
                        self.energyValueCurrentCycleLabel.text = [NSString stringWithFormat:@"%.3f %s", currentCycleEnergyValue, "kWh"];
                    }
                    
                    // Average energy value = (total energy / cycle count) = average count
                    if (cycleCount < 1) {
                        averageEnergyValue = inTotalEnergyValue;
                    } else {
                        averageEnergyValue =  inTotalEnergyValue / cycleCount ;
                    }
                    NSLog(@"inTotalEnergyValue: %f",inTotalEnergyValue);
                    NSLog(@"currentCycleEnergyValue: %f",currentCycleEnergyValue);
                    NSLog(@"energyValueinCycle: %f",averageEnergyValue);
                    
                    self.energyValueInAveragePerCycleLabel.text = [NSString stringWithFormat:@"%.3f %s", averageEnergyValue, "kWh"];
                } else {
                    NSLog(@"Energy value is nil");
                }
            }];
        } else {
            [self updateResult:[NSString stringWithFormat:@"Failed to establish a connection with the device"]];
            //[self setDeviceStatus:@"0" nodeId:self->nodeId];
        }
    })) {
        [self updateResult:[NSString stringWithFormat:@"Waiting for connection with the device"]];
    } else {
        //[self setDeviceStatus:@"0" nodeId:self->nodeId];
        [self updateResult:[NSString stringWithFormat:@"Failed to trigger the connection with the device"]];
    }
}

//MARK: Set Device Status

- (void)setDeviceStatus:(NSString *)connected nodeId:(NSNumber *)node_id{
    NSUInteger index2 = [dishwasherDeviceList indexOfObjectPassingTest:^BOOL(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        BOOL found = [[item objectForKey:@"nodeId"] intValue] == node_id.intValue;
        return found;
    }];
    
    if([dishwasherDeviceList count] > 0){
        NSNumber *nodeId = [dishwasherDeviceList[index2] valueForKey:@"nodeId"];
        NSString *deviceType = [dishwasherDeviceList[index2] valueForKey:@"deviceType"];
        
        NSMutableDictionary * deviceDic = [[NSMutableDictionary alloc] init];
        [deviceDic setObject:deviceType forKey:@"deviceType"];
        [deviceDic setObject:nodeId forKey:@"nodeId"];
        [deviceDic setObject:@1 forKey:@"endPoint"];
        [deviceDic setObject:connected forKey:@"isConnected"];
        [deviceDic setObject:[dishwasherDeviceList[index2] valueForKey:@"title"] forKey:@"title"];
        
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @"false"] forKey:@"isBinded"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceType"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToDeviceName"];
        [deviceDic setObject:[NSString stringWithFormat:@"%@", @""] forKey:@"connectedToNodeId"];

        [dishwasherDeviceList replaceObjectAtIndex:index2 withObject:deviceDic];
    }
    [[NSUserDefaults standardUserDefaults] setObject:dishwasherDeviceList forKey:@"saved_list"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"deviceListTemp:- %@",dishwasherDeviceList);
    [SVProgressHUD dismiss];
    if([connected isEqualToString:@"0"]){
        [self showAlertPopup:@"Device is offline, Please check the device connectivity." back: true];
    }
}

- (void) showAlertPopup:(NSString *) message back: (BOOL) isBack {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message: message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isBack) {
                //                [self stopGettingDishwasherEMData];
                [self.navigationController popViewControllerAnimated: YES];
            }
        });
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - EM Function

// Store Dishwasher Status
- (void)saveDishwasherStatus {
    
    [[NSUserDefaults standardUserDefaults] setBool: true forKey:@"isBackButtonFlow"];
    
    NSNumber *_inTotalEnergyValue = @(inTotalEnergyValue);
    NSNumber *_currentCycleEnergyValue = @(currentCycleEnergyValue);
    NSNumber *_averageEnergyValue = @(averageEnergyValue);
    NSNumber *_cycleCount = @(cycleCount);
    NSNumber *_timeLeft = @(self.timeLeft);
    NSNumber *_initialTotalEnergyValue = @(initialTotalEnergyValue);
    
    NSDictionary *dishwaserStatus = @{
        @"inTotalEnergyValue": _inTotalEnergyValue,
        @"currentCycleEnergyValue": _currentCycleEnergyValue,
        @"averageEnergyValue": _averageEnergyValue,
        @"cycleCount": _cycleCount,
        @"timeLeft": _timeLeft,
        @"dishwasherCurrentState": _dishwasherCurrentState,
        @"isFirstCycle": @(isFirstCycle),
        @"initialTotalEnergyValue": _initialTotalEnergyValue
    };
    
    NSLog(@" dishwaser Status before save:- %@", dishwaserStatus);
    
    // Store the dictionary in NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setObject:dishwaserStatus forKey:@"dishwaserSavedStatus"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //    [self stopGettingDishwasherEMData];
    [self.navigationController popViewControllerAnimated: YES];
}

- (void) showPopupToPauseStatus {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert" message:@"Navigating back will cause the dishwasher to enter the pause state." preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
        [self saveAction];
    }];
    [alertController addAction:okAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
        NSLog(@"Cancel button tapped");
    }];
    [alertController addAction:cancelAction];
    // Present the alert
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void) saveAction {
    if ([_dishwasherCurrentState isEqual: @"stop"]) {
        // [self stopDishwasher];
    } else {
        [self pauseDishwasher];
    }
    [self saveDishwasherStatus];
}

- (void) updateUI {
    // Update button states based on timer status
    
    if (self.isPaused) {
        self.startButton.enabled = NO;
        self.startButton.backgroundColor = UIColor.sil_silverChaliceColor;
        
        self.stopButton.enabled = YES;
        self.stopButton.backgroundColor = UIColor.sil_regularBlueColor;
        
        self.pauseResumeButton.enabled = YES;
        self.pauseResumeButton.backgroundColor = UIColor.sil_regularBlueColor;
        
        [self.pauseResumeButton setTitle:@"RESUME" forState:UIControlStateNormal];
        
    } else if (self.isRunning) {
        self.startButton.enabled = NO;
        self.startButton.backgroundColor = UIColor.sil_silverChaliceColor;
        
        self.stopButton.enabled = YES;
        self.stopButton.backgroundColor = UIColor.sil_regularBlueColor;
        
        self.pauseResumeButton.enabled = YES;
        self.pauseResumeButton.backgroundColor = UIColor.sil_regularBlueColor;
        
        [self.pauseResumeButton setTitle:@"PAUSE" forState:UIControlStateNormal];
    } else {
        self.startButton.enabled = YES;
        self.startButton.backgroundColor = UIColor.sil_regularBlueColor;
        
        self.stopButton.enabled = NO;
        self.stopButton.backgroundColor = UIColor.sil_silverChaliceColor;
        
        self.pauseResumeButton.enabled = NO;
        self.pauseResumeButton.backgroundColor = UIColor.sil_silverChaliceColor;
    }
}

- (void) startButtonTappedFunction {
    if (!self.isRunning) {
        self.isRunning = YES;
        self.isPaused = NO;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
        [self updateUI];
    }
}

- (void) pauseResumeButtonTappedFunction {
    
    if (self.isRunning) {
        if (self.isPaused) {
            self.isPaused = NO;
            [self.pauseResumeButton setTitle:@"PAUSE" forState:UIControlStateNormal];
            [self.timer setFireDate:[NSDate date]]; // Resume timer
            if (self.timer == nil) {
                [self readDishwaserEM];
                [self startGettingDishwasherEMData];
                self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
            }
        } else {
            self.isPaused = YES;
            [self.pauseResumeButton setTitle:@"RESUME" forState:UIControlStateNormal];
            [self.timer setFireDate:[NSDate distantFuture]]; // Pause timer
        }
    } else {
        self.isRunning = YES;
    }
    [self updateUI];
}

- (void) stopButtonTappedFunction {
    self.isRunning = NO;
    self.isPaused = NO;
    self.timeLeft = 600; // Reset to 10 minutes
    [self.timer invalidate];
    self.timer = nil;
    self.timerLabel.text = [self formatTime:self.timeLeft];
    self.progressBar.progress = 0; // Reset progress bar
    [self updateUI];
    isFirstCycle = true;
    initialTotalEnergyValue = 0.0;
}

- (void)updateTimer {
    if (self.timeLeft > 0) {
        self.timeLeft--;
        self.timerLabel.text = [self formatTime:self.timeLeft];
        self.progressBar.progress = (600 - self.timeLeft) / 600.0;
    } else {
        [self stopDishwasher];
        [self stopButtonTappedFunction];
    }
}

- (NSString *)formatTime:(NSInteger)seconds {
    NSInteger minutes = seconds / 60;
    NSInteger remainingSeconds = seconds % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)remainingSeconds];
}

- (void) startGettingDishwasherEMData {
    if (self.dishwasherTimer == nil) {
        self.dishwasherTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(readDishwaserEM) userInfo:nil repeats:YES];
    }
}

- (void) stopGettingDishwasherEMData {
    if (self.dishwasherTimer != nil && [self.dishwasherTimer isValid]) {
        [self.dishwasherTimer invalidate];
        self.dishwasherTimer = nil;
    }
}

@end
